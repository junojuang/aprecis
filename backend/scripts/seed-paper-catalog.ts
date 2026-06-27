/**
 * Seed the `paper_catalog` table with the hand-curated canon.
 *
 * The catalog is the single queryable index of EVERY paper in the app. Ingested
 * papers flow in automatically (trigger on `papers` → see migration 016). The
 * hand-curated `loop:` papers, however, are authored in Swift (FoundationalLoops,
 * DailyLoopContent, …) and never touch the ingestion pipeline — so they must be
 * recorded here.
 *
 * This script is the ONE place to update when you add a new curated paper in
 * Swift: add its id to data/curated-paper-catalog.json, then add a row to the
 * CURATED map below and re-run. Idempotent: upserts on `paper_id`.
 *
 * `canonicalKey` must match BraceIdentity (ios/.../Models/Models.swift) so a
 * curated row dedupes against any ingested row for the same work:
 *   • arXiv works → "arxiv:<id>"
 *   • perceptron  → "doi:10.1037/h0042519"
 *   • backprop    → "article:nature:323533a0"
 *   • lenet/alexnet (no arXiv/DOI alias) → "id:<servedPaperId>"
 *
 * `publishedAt` is the publication date (Jan 1 of year where only the year is
 * known); curated works are old, so they never pollute the "Latest" list.
 *
 * Run: cd backend && deno run --allow-net --allow-env --allow-read scripts/seed-paper-catalog.ts
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
// Keyed by the iOS loop id. Mirror of the Swift sources (FoundationalLoops
// `paperTitle` / `paperURL`, RelatedPapers.curatedLoopToBackend). Keep in sync.

interface CatalogEntry {
  title: string;
  canonicalKey: string;
  year: number;
  publishedAt: string; // ISO date
  topic: string;       // SimilarityGraph cluster label
  url: string;
  arxivId: string | null;
}

const CURATED: Record<string, CatalogEntry> = {
  "perceptron": {
    title: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
    canonicalKey: "doi:10.1037/h0042519",
    year: 1958,
    publishedAt: "1958-01-01",
    topic: "Foundations",
    url: "https://psycnet.apa.org/doi/10.1037/h0042519",
    arxivId: null,
  },
  "backprop": {
    title: "Learning Representations by Back Propagating Errors",
    canonicalKey: "article:nature:323533a0",
    year: 1986,
    publishedAt: "1986-01-01",
    topic: "Foundations",
    url: "https://www.nature.com/articles/323533a0",
    arxivId: null,
  },
  "lenet": {
    title: "Gradient Based Learning Applied to Document Recognition (LeNet-5)",
    canonicalKey: "id:lenet",
    year: 1998,
    publishedAt: "1998-01-01",
    topic: "Vision",
    url: "https://yann.lecun.com/exdb/publis/pdf/lecun-98.pdf",
    arxivId: null,
  },
  "alexnet": {
    title: "ImageNet Classification with Deep Convolutional Neural Networks",
    canonicalKey: "id:alexnet",
    year: 2012,
    publishedAt: "2012-01-01",
    topic: "Vision",
    url: "https://papers.nips.cc/paper_files/paper/2012/hash/c399862d3b9d6b76c8436e924a68c45b-Abstract.html",
    arxivId: null,
  },
  "word2vec": {
    title: "Efficient Estimation of Word Representations in Vector Space",
    canonicalKey: "arxiv:1301.3781",
    year: 2013,
    publishedAt: "2013-01-16",
    topic: "Language",
    url: "https://arxiv.org/abs/1301.3781",
    arxivId: "1301.3781",
  },
  "seq2seq": {
    title: "Sequence to Sequence Learning with Neural Networks",
    canonicalKey: "arxiv:1409.3215",
    year: 2014,
    publishedAt: "2014-09-10",
    topic: "Language",
    url: "https://arxiv.org/abs/1409.3215",
    arxivId: "1409.3215",
  },
  "gans": {
    title: "Generative Adversarial Nets",
    canonicalKey: "arxiv:1406.2661",
    year: 2014,
    publishedAt: "2014-06-10",
    topic: "Generative",
    url: "https://arxiv.org/abs/1406.2661",
    arxivId: "1406.2661",
  },
  "resnet": {
    title: "Deep Residual Learning for Image Recognition",
    canonicalKey: "arxiv:1512.03385",
    year: 2015,
    publishedAt: "2015-12-10",
    topic: "Vision",
    url: "https://arxiv.org/abs/1512.03385",
    arxivId: "1512.03385",
  },
  "attention": {
    title: "Attention Is All You Need",
    canonicalKey: "arxiv:1706.03762",
    year: 2017,
    publishedAt: "2017-06-12",
    topic: "Language",
    url: "https://arxiv.org/abs/1706.03762",
    arxivId: "1706.03762",
  },
  "gpt3": {
    title: "Language Models are Few Shot Learners (GPT-3)",
    canonicalKey: "arxiv:2005.14165",
    year: 2020,
    publishedAt: "2020-05-28",
    topic: "Language",
    url: "https://arxiv.org/abs/2005.14165",
    arxivId: "2005.14165",
  },
  "bert": {
    title: "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
    canonicalKey: "arxiv:1810.04805",
    year: 2018,
    publishedAt: "2018-10-11",
    topic: "Language",
    url: "https://arxiv.org/abs/1810.04805",
    arxivId: "1810.04805",
  },
};

// ─── Load the shipped catalog for the id list ────────────────────────────────

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

const rows = cat.interactiveLoopPaperIds
  .filter((id) => CURATED[id])
  .map((id) => {
    const meta = CURATED[id];
    return {
      paper_id: id,
      canonical_key: meta.canonicalKey,
      title: meta.title,
      published_at: new Date(meta.publishedAt).toISOString(),
      year: meta.year,
      source: "curated",
      origin: "curated",
      topic: meta.topic,
      url: meta.url,
      arxiv_id: meta.arxivId,
      updated_at: now,
    };
  });

const { error } = await supabase
  .from("paper_catalog")
  .upsert(rows, { onConflict: "paper_id" });

if (error) {
  console.error("Upsert failed:", error.message);
  Deno.exit(1);
}

console.log(`✓ Recorded ${rows.length} curated papers in paper_catalog`);
for (const r of rows) {
  console.log(`  ${r.paper_id.padEnd(32)} ${String(r.year)}  ${r.title.slice(0, 44)}`);
}
