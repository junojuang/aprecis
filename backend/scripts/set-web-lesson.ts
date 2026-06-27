/**
 * Publish a web-lesson bundle and wire it to a paper, with no app update.
 *
 * Does four things, all idempotent:
 *   1. Ensures the public `web-lessons` Storage bucket exists.
 *   2. Uploads the bundle to `web-lessons/<slug>/index.html`.
 *   3. Sets `paper_catalog.web_lesson_url` for the paper (creates the curated
 *      catalog row if it does not exist yet).
 *   4. For arXiv-backed lessons, seeds the canonical graph row so the app can
 *      show Builds on / Led to / Adjacent without a binary update.
 *
 * The iOS app reads the URL via GET /serve-cards/web-lessons and renders the
 * bundle in WebLessonView instead of a native reader.
 *
 * Run (after `npx supabase db push` so the column exists):
 *   cd backend && deno run --allow-net --allow-env --allow-read \
 *     scripts/set-web-lesson.ts \
 *     --loop grokking \
 *     --file ../prototypes/web-lesson/grokking-premium.html \
 *     --slug grokking \
 *     --title "Grokking: Generalization Beyond Overfitting on Small Algorithmic Datasets" \
 *     --canonical-key arxiv:2201.02177 \
 *     --topic Foundations --year 2022 --url https://arxiv.org/abs/2201.02177 \
 *     --arxiv-id 2201.02177
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { parseArgs } from "https://deno.land/std@0.224.0/cli/parse_args.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { runGraphStage } from "../src/graph.ts";

const BUCKET = "web-lessons";

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const OPENAI_KEY = env.OPENAI_API_KEY ?? Deno.env.get("OPENAI_API_KEY");
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

const args = parseArgs(Deno.args, {
  string: ["loop", "file", "slug", "title", "canonical-key", "topic", "url", "arxiv-id", "year"],
});
const loopId = args.loop;
const file = args.file;
const slug = args.slug ?? (loopId ? loopId.split(":").pop() : undefined);
if (!loopId || !file || !slug) {
  console.error("Required: --loop <paper_id> --file <path> [--slug <storage-folder>]");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

// 1. Ensure the public bucket exists.
const { data: buckets } = await supabase.storage.listBuckets();
if (!buckets?.some((b) => b.name === BUCKET)) {
  const { error } = await supabase.storage.createBucket(BUCKET, {
    public: true,
    fileSizeLimit: "10MB",
  });
  if (error) { console.error("createBucket failed:", error.message); Deno.exit(1); }
  console.log(`✓ created public bucket "${BUCKET}"`);
} else {
  console.log(`• bucket "${BUCKET}" exists`);
}

// 2. Upload the bundle (overwrites any prior version).
const bytes = await Deno.readFile(file);
const objectPath = `${slug}/index.html`;
const { error: upErr } = await supabase.storage
  .from(BUCKET)
  .upload(objectPath, bytes, { contentType: "text/html; charset=utf-8", upsert: true });
if (upErr) { console.error("upload failed:", upErr.message); Deno.exit(1); }
const publicUrl =
  `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${objectPath}?v=${Date.now()}`;
console.log(`✓ uploaded ${file} → ${publicUrl}`);

// 3. Link it in the catalog. Update first; if the curated row is missing, insert it.
const { data: updated, error: updErr } = await supabase
  .from("paper_catalog")
  .update({
    title: args.title ?? slug,
    canonical_key: args["canonical-key"] ?? loopId,
    topic: args.topic ?? null,
    url: args.url ?? null,
    arxiv_id: args["arxiv-id"] ?? null,
    year: args.year ? Number(args.year) : null,
    published_at: args.year ? `${args.year}-01-01T00:00:00Z` : null,
    web_lesson_url: publicUrl,
    updated_at: new Date().toISOString(),
  })
  .eq("paper_id", loopId)
  .select("paper_id");
if (updErr) {
  console.error("catalog update failed:", updErr.message);
  console.error("Did you run `npx supabase db push` to apply migration 020?");
  Deno.exit(1);
}

if (!updated || updated.length === 0) {
  const { error: insErr } = await supabase.from("paper_catalog").insert({
    paper_id: loopId,
    canonical_key: args["canonical-key"] ?? loopId,
    title: args.title ?? slug,
    source: "curated",
    origin: "curated",
    topic: args.topic ?? null,
    url: args.url ?? null,
    arxiv_id: args["arxiv-id"] ?? null,
    year: args.year ? Number(args.year) : null,
    published_at: args.year ? `${args.year}-01-01T00:00:00Z` : null,
    web_lesson_url: publicUrl,
    updated_at: new Date().toISOString(),
  });
  if (insErr) { console.error("catalog insert failed:", insErr.message); Deno.exit(1); }
  console.log(`✓ created catalog row for ${loopId} with web lesson`);
} else {
  console.log(`✓ set web_lesson_url on ${loopId}`);
}

// 4. Make the lesson connectable. The App Store app asks for related papers
// using the app-facing `loop:` id, while the graph corpus is keyed by canonical
// paper ids such as `arxiv:2205.14135`. `serve-cards/related` resolves that
// alias, so publishing should ensure the canonical graph row exists.
if (args["arxiv-id"]) {
  if (!OPENAI_KEY) {
    console.warn("! OPENAI_API_KEY missing; skipped graph embedding for related rails");
  } else {
    const arxivId = String(args["arxiv-id"]).replace(/^arxiv:/, "");
    const graphPaperId = `arxiv:${arxivId}`;
    try {
      const meta = await fetchArxivMeta(arxivId);
      const { error: graphUpsertErr } = await supabase.from("papers").upsert({
        paper_id: graphPaperId,
        title: meta.title,
        authors: [],
        abstract: meta.abstract,
        source: "arxiv",
        url: meta.url,
        arxiv_category: meta.arxiv_category ?? null,
        published_at: meta.published_at,
        score: 0.9,
        score_breakdown: {},
        status: "processed",
      }, { onConflict: "paper_id" });
      if (graphUpsertErr) throw graphUpsertErr;

      const graph = await runGraphStage(supabase, OPENAI_KEY, {
        paper_id: graphPaperId,
        title: meta.title,
        abstract: meta.abstract,
        source: "arxiv",
        arxiv_category: meta.arxiv_category,
      });
      const tag = graph.errors.length ? `; warnings: ${graph.errors.join("; ")}` : "";
      console.log(`✓ graph ready for ${graphPaperId} (embed=${graph.embedded}, edges=${graph.edges}${tag})`);
    } catch (err) {
      console.warn(`! graph setup skipped for ${graphPaperId}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
}

console.log("\nDone. Redeploy if needed: npx supabase functions deploy serve-cards");

async function fetchArxivMeta(arxivId: string) {
  const res = await fetch(`https://export.arxiv.org/api/query?id_list=${arxivId}&max_results=1`);
  if (!res.ok) throw new Error(`arXiv ${res.status} for ${arxivId}`);
  const xml = await res.text();
  const entry = xml.match(/<entry>([\s\S]*?)<\/entry>/)?.[1];
  if (!entry) throw new Error(`arXiv entry missing for ${arxivId}`);
  const tag = (t: string) =>
    entry.match(new RegExp(`<${t}[^>]*>([\\s\\S]*?)</${t}>`))?.[1]?.replace(/\s+/g, " ").trim();
  const title = tag("title");
  const abstract = tag("summary");
  const published = entry.match(/<published>([\s\S]*?)<\/published>/)?.[1]?.trim();
  const category =
    entry.match(/<arxiv:primary_category[^>]*\bterm="([^"]+)"/)?.[1] ??
    entry.match(/<category[^>]*\bterm="([^"]+)"/)?.[1];
  if (!title || !abstract) throw new Error(`arXiv metadata incomplete for ${arxivId}`);
  return {
    title,
    abstract,
    arxiv_category: category,
    published_at: published ?? new Date().toISOString(),
    url: `https://arxiv.org/abs/${arxivId}`,
  };
}
