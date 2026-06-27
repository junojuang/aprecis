/**
 * Backfill graph data for the hand-authored branch roadmap papers only.
 *
 * These decks are served to the current App Store binary as `loop:*` cards,
 * while related-paper lookups should resolve through their canonical
 * `arxiv:*` rows. This script embeds those canonical rows and inserts any
 * citation edges Semantic Scholar can resolve against the local corpus.
 *
 * Run from `backend/`:
 *   deno run --allow-net --allow-env --allow-read scripts/backfill-branch-graph.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
await load({ envPath: ".env.local", export: true, allowEmptyValues: true });

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { runGraphStage } from "../src/graph.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY");

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}
if (!OPENAI_KEY) {
  console.error("Missing OPENAI_API_KEY");
  Deno.exit(1);
}

const branchTargets = [
  { loopId: "vit", arxivId: "arxiv:2010.11929" },
  { loopId: "ddpm", arxivId: "arxiv:2006.11239" },
  { loopId: "clip", arxivId: "arxiv:2103.00020" },
  { loopId: "stable-diffusion", arxivId: "arxiv:2112.10752" },
  { loopId: "controlnet", arxivId: "arxiv:2302.05543" },
  { loopId: "sam", arxivId: "arxiv:2304.02643" },
  { loopId: "t5", arxivId: "arxiv:1910.10683" },
  { loopId: "chinchilla", arxivId: "arxiv:2203.15556" },
  { loopId: "palm", arxivId: "arxiv:2204.02311" },
  { loopId: "llama", arxivId: "arxiv:2302.13971" },
  { loopId: "mixtral", arxivId: "arxiv:2401.04088" },
  { loopId: "reflexion", arxivId: "arxiv:2303.11366" },
];

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
const canonicalIds = branchTargets.map((target) => target.arxivId);

const { data: papers, error: papersError } = await supabase
  .from("papers")
  .select("paper_id, title, abstract, source, arxiv_category")
  .in("paper_id", canonicalIds);

if (papersError) {
  console.error("Paper query failed:", papersError.message);
  Deno.exit(1);
}

const paperById = new Map((papers ?? []).map((paper: any) => [paper.paper_id, paper]));
const coreIdeas = new Map<string, string[]>();

const { data: loopCards, error: cardsError } = await supabase
  .from("cards")
  .select("paper_id, cards")
  .in("paper_id", branchTargets.map((target) => target.loopId));

if (cardsError) {
  console.error("Cards query failed:", cardsError.message);
  Deno.exit(1);
}

for (const row of loopCards ?? []) {
  const concepts = (row as any).cards?.concepts;
  if (Array.isArray(concepts)) {
    coreIdeas.set(
      (row as any).paper_id,
      concepts.map((concept: any) => concept?.title).filter(Boolean),
    );
  }
}

let embedded = 0;
let edges = 0;
let withErrors = 0;

for (const target of branchTargets) {
  const paper = paperById.get(target.arxivId);
  if (!paper) {
    withErrors++;
    console.error(`Missing canonical paper row: ${target.arxivId}`);
    continue;
  }

  const result = await runGraphStage(supabase, OPENAI_KEY, {
    paper_id: paper.paper_id,
    title: paper.title,
    abstract: paper.abstract ?? "",
    source: paper.source,
    arxiv_category: paper.arxiv_category ?? undefined,
    coreIdeas: coreIdeas.get(target.loopId),
  });

  if (result.embedded) embedded++;
  edges += result.edges;

  if (result.errors.length) {
    withErrors++;
    console.error(`x ${target.arxivId}: ${result.errors.join("; ")}`);
  } else {
    console.log(`ok ${target.arxivId.padEnd(18)} embed=${result.embedded} edges=${result.edges}`);
  }

  await new Promise((resolve) => setTimeout(resolve, 1100));
}

console.log(`Done: ${embedded} embedded, ${edges} edges inserted, ${withErrors} targets with errors`);
