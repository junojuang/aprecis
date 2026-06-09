/**
 * Backfill the paper graph for the existing corpus: embeddings, citation
 * edges, and arXiv categories. Run once after migration 008.
 *
 * Idempotent: re-running re-embeds and re-upserts edges (duplicates ignored).
 * Pass --skip-embedded to only touch papers without an embedding yet.
 *
 * Semantic Scholar's free tier is ~1 req/sec unauthenticated, so this paces
 * itself with a delay between papers. A few hundred papers takes a few minutes.
 *
 * Usage:
 *   cd backend
 *   deno run --allow-net --allow-env --allow-read scripts/backfill-graph.ts
 *   deno run --allow-net --allow-env --allow-read scripts/backfill-graph.ts --skip-embedded
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
await load({ envPath: ".env.local", export: true, allowEmptyValues: true });

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { runGraphStage } from "../src/graph.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY");

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}
if (!OPENAI_KEY) {
  console.error("Missing OPENAI_API_KEY (needed for embeddings)");
  Deno.exit(1);
}

const skipEmbedded = Deno.args.includes("--skip-embedded");
const PACE_MS = 1100; // Semantic Scholar free tier ~1 req/sec

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// All papers, oldest first so citation edges resolve as the corpus fills in.
let query = supabase
  .from("papers")
  .select("paper_id, title, abstract, source, arxiv_category, embedding")
  .order("published_at", { ascending: true });
if (skipEmbedded) query = query.is("embedding", null);

const { data: papers, error } = await query;
if (error) {
  console.error("Query failed:", error.message);
  Deno.exit(1);
}
console.log(`Backfilling graph for ${papers?.length ?? 0} papers${skipEmbedded ? " (missing embeddings only)" : ""}`);

// Core ideas sharpen the embedding — pull concept titles from cards if present.
const ids = (papers ?? []).map((p: any) => p.paper_id);
const coreIdeas = new Map<string, string[]>();
for (let i = 0; i < ids.length; i += 200) {
  const { data: cards } = await supabase
    .from("cards")
    .select("paper_id, cards")
    .in("paper_id", ids.slice(i, i + 200));
  for (const c of cards ?? []) {
    const concepts = (c as any).cards?.concepts;
    if (Array.isArray(concepts)) {
      coreIdeas.set((c as any).paper_id, concepts.map((x: any) => x?.title).filter(Boolean));
    }
  }
}

let embedded = 0;
let edges = 0;
let withErrors = 0;

for (const p of papers ?? []) {
  const result = await runGraphStage(supabase, OPENAI_KEY, {
    paper_id: p.paper_id,
    title: p.title,
    abstract: p.abstract ?? "",
    source: p.source,
    arxiv_category: p.arxiv_category ?? undefined,
    coreIdeas: coreIdeas.get(p.paper_id),
  });

  if (result.embedded) embedded++;
  edges += result.edges;
  if (result.errors.length) {
    withErrors++;
    console.error(`✗ ${p.paper_id}: ${result.errors.join("; ")}`);
  } else {
    console.log(`✓ ${p.paper_id.slice(0, 44).padEnd(44)} embed=${result.embedded} edges=${result.edges}`);
  }

  await new Promise((r) => setTimeout(r, PACE_MS));
}

console.log(`\nDone: ${embedded} embedded, ${edges} edges inserted, ${withErrors} papers with errors`);
