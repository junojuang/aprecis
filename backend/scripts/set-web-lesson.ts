/**
 * Publish a web-lesson bundle and wire it to a paper, with no app update.
 *
 * Does three things, all idempotent:
 *   1. Ensures the public `web-lessons` Storage bucket exists.
 *   2. Uploads the bundle to `web-lessons/<slug>/index.html`.
 *   3. Sets `paper_catalog.web_lesson_url` for the paper (creates the curated
 *      catalog row if it does not exist yet).
 *
 * The iOS app reads the URL via GET /serve-cards/web-lessons and renders the
 * bundle in WebLessonView instead of a native reader.
 *
 * Run (after `npx supabase db push` so the column exists):
 *   cd backend && deno run --allow-net --allow-env --allow-read \
 *     scripts/set-web-lesson.ts \
 *     --loop loop:foundational:grokking \
 *     --file ../prototypes/web-lesson/grokking-premium.html \
 *     --slug grokking \
 *     --title "Grokking" --canonical-key arxiv:2201.02177 \
 *     --topic Foundations --year 2022 --url https://arxiv.org/abs/2201.02177 \
 *     --arxiv-id 2201.02177
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { parseArgs } from "https://deno.land/std@0.224.0/cli/parse_args.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BUCKET = "web-lessons";

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
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
  `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${objectPath}`;
console.log(`✓ uploaded ${file} → ${publicUrl}`);

// 3. Link it in the catalog. Update first; if the curated row is missing, insert it.
const { data: updated, error: updErr } = await supabase
  .from("paper_catalog")
  .update({ web_lesson_url: publicUrl, updated_at: new Date().toISOString() })
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

console.log("\nDone. Redeploy if needed: npx supabase functions deploy serve-cards");
