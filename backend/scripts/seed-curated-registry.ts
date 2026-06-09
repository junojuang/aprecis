/**
 * Seed the `curated_papers` audit registry.
 *
 * Records every hand-curated paper shipped in the iOS app (the `loop:` canon)
 * as one row, for audit / tracking. This is NOT served to the app — the real
 * decks live in `papers` / `cards`.
 *
 * The id list + ordering is the same `data/curated-paper-catalog.json` the iOS
 * `CuratedPaperCatalog` loads, so this registry stays in lockstep with the
 * shipped catalog. Titles + canonical keys are kept here alongside it.
 *
 * Idempotent: upserts on `paper_id`; re-running refreshes title/order/updated_at.
 *
 * Run: cd backend && deno run --allow-net --allow-env --allow-read scripts/seed-curated-registry.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CURATED_CATALOG_JSON = new URL("../../data/curated-paper-catalog.json", import.meta.url);

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

// ─── Curated catalog metadata ────────────────────────────────────────────────
// Keyed by the iOS loop id. `canonicalKey` is BraceIdentity's canonical key:
// perceptron + backprop bridge to their DOI / Nature ids (so they merge with
// the seeded `papers` rows); the rest have no cross-id alias yet (null).
// `servedPaperId` is the backend paper_id when a full deck has been seeded.

interface CuratedEntry {
  title: string;
  canonicalKey: string | null;
  servedPaperId: string | null;
}

const CURATED: Record<string, CuratedEntry> = {
  "loop:foundational:perceptron": {
    title: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
    canonicalKey: "doi:10.1037/h0042519",
    servedPaperId: "rosenblatt:1958",
  },
  "loop:foundational:backprop": {
    title: "Learning Representations by Back-Propagating Errors",
    canonicalKey: "article:nature:323533a0",
    servedPaperId: "rumelhart:1986",
  },
  "loop:foundational:lenet": {
    title: "Gradient-Based Learning Applied to Document Recognition",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:alexnet": {
    title: "ImageNet Classification with Deep Convolutional Neural Networks",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:word2vec": {
    title: "Efficient Estimation of Word Representations in Vector Space",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:seq2seq": {
    title: "Sequence to Sequence Learning with Neural Networks",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:gans": {
    title: "Generative Adversarial Nets",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:resnet": {
    title: "Deep Residual Learning for Image Recognition",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:attention": {
    title: "Attention Is All You Need",
    canonicalKey: null,
    servedPaperId: null,
  },
  "loop:foundational:gpt3": {
    title: "Language Models are Few-Shot Learners",
    canonicalKey: null,
    servedPaperId: null,
  },
};

// ─── Load the shipped catalog for the id list + ordering ─────────────────────

interface CatalogFile {
  version: number;
  interactiveLoopPaperIds: string[];
}

const cat = JSON.parse(await Deno.readTextFile(CURATED_CATALOG_JSON)) as CatalogFile;
console.log(`Catalog v${cat.version}: ${cat.interactiveLoopPaperIds.length} curated paper ids`);

// Warn on drift between the shipped catalog and the metadata table above.
for (const id of cat.interactiveLoopPaperIds) {
  if (!CURATED[id]) console.warn(`  ⚠ catalog id has no metadata entry: ${id}`);
}
for (const id of Object.keys(CURATED)) {
  if (!cat.interactiveLoopPaperIds.includes(id)) {
    console.warn(`  ⚠ metadata id not in shipped catalog: ${id}`);
  }
}

// ─── Upsert rows ─────────────────────────────────────────────────────────────

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
const now = new Date().toISOString();

const rows = cat.interactiveLoopPaperIds.map((id, i) => {
  const meta = CURATED[id];
  return {
    paper_id: id,
    title: meta?.title ?? id,
    canonical_key: meta?.canonicalKey ?? null,
    served_paper_id: meta?.servedPaperId ?? null,
    catalog_order: i,
    updated_at: now,
  };
});

const { error } = await supabase
  .from("curated_papers")
  .upsert(rows, { onConflict: "paper_id" });

if (error) {
  console.error("Upsert failed:", error.message);
  Deno.exit(1);
}

console.log(`✓ Recorded ${rows.length} curated papers in curated_papers`);
for (const r of rows) {
  console.log(`  ${String(r.catalog_order).padStart(2)} ${r.paper_id.padEnd(32)} ${r.title.slice(0, 48)}`);
}
