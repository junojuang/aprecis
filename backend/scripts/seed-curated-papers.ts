/**
 * Seed all curated papers into the backend graph corpus.
 *
 * The curated canon (perceptron … gpt3) used to get its Explore rails from
 * hand-written maps on the iOS client. This script puts every curated paper
 * into `papers` so the rails come from the SAME scoring system as every other
 * paper: embeddings (Adjacent) + Semantic Scholar citations (Builds on / Led to).
 *
 * It seeds lightweight `papers` rows only — no `cards`, no LLM pipeline. The
 * curated hub CONTENT still ships client-side; these rows exist purely to drive
 * the graph. The 6 arXiv-era papers use real arXiv ids so citation lookup
 * works and they cite each other; the 5 pre-arXiv papers get a stable id and
 * an embedding-only presence (no citation edges).
 *
 * Also fills `curated_papers.served_paper_id` so the audit registry maps each
 * loop id to its backend id.
 *
 * Idempotent. Run after migrations 008-011.
 *   cd backend && deno run --allow-net --allow-env --allow-read scripts/seed-curated-papers.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { runGraphStage } from "../src/graph.ts";

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const OPENAI_KEY = env.OPENAI_API_KEY ?? Deno.env.get("OPENAI_API_KEY");

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}
if (!OPENAI_KEY) {
  console.error("Missing OPENAI_API_KEY (needed for embeddings)");
  Deno.exit(1);
}

// ─── Curated paper manifest ──────────────────────────────────────────────────
// loopId      — the iOS client id
// backendId   — the `papers.paper_id` (arxiv:<id> for arXiv-era papers)
// arxivId     — set when the paper is on arXiv; drives metadata fetch + citations
// Pre-arXiv papers carry an inline title/abstract instead.

interface CuratedSeed {
  loopId: string;
  backendId: string;
  arxivId?: string;
  title?: string;        // used only for pre-arXiv papers
  abstract?: string;     // used only for pre-arXiv papers
  url?: string;
  publishedAt?: string;
}

const CURATED: CuratedSeed[] = [
  {
    loopId: "loop:foundational:perceptron",
    backendId: "rosenblatt:1958",
    title: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
    abstract:
      "We propose a hypothetical nervous system, called the perceptron, designed to illustrate fundamental properties of intelligent systems. The perceptron consists of input retina cells, association units that pool weighted signals through an adjustable threshold, and a response unit. A reinforcement rule updates the association weights from labelled examples. Under broad conditions the perceptron is shown capable of learning to classify stimuli into categories.",
    url: "https://psycnet.apa.org/doiLanding?doi=10.1037/h0042519",
    publishedAt: "1958-11-01T00:00:00Z",
  },
  {
    loopId: "loop:foundational:backprop",
    backendId: "rumelhart:1986",
    title: "Learning Representations by Back-Propagating Errors",
    abstract:
      "We describe a new learning procedure, back-propagation, for networks of neurone-like units. The procedure repeatedly adjusts the weights of the connections in the network to minimize the difference between the actual output vector and the desired output vector. Internal hidden units come to represent important features of the task domain, and regularities are captured by the interactions of these units.",
    url: "https://www.nature.com/articles/323533a0",
    publishedAt: "1986-10-09T00:00:00Z",
  },
  {
    loopId: "loop:foundational:lenet",
    backendId: "lecun:1998",
    title: "Gradient-Based Learning Applied to Document Recognition",
    abstract:
      "Multilayer neural networks trained with the back-propagation algorithm constitute the best example of a successful gradient-based learning technique. Given an appropriate network architecture, gradient-based learning algorithms can synthesize a complex decision surface that classifies high-dimensional patterns such as handwritten characters with minimal preprocessing. This paper reviews various methods applied to handwritten character recognition and compares them on a standard handwritten digit recognition task. Convolutional neural networks, specifically designed to deal with the variability of 2D shapes, are shown to outperform all other techniques.",
    url: "https://ieeexplore.ieee.org/document/726791",
    publishedAt: "1998-11-01T00:00:00Z",
  },
  {
    loopId: "loop:foundational:alexnet",
    backendId: "krizhevsky:2012",
    title: "ImageNet Classification with Deep Convolutional Neural Networks",
    abstract:
      "We trained a large, deep convolutional neural network to classify the 1.2 million high-resolution images in the ImageNet LSVRC-2010 contest into 1000 classes. The neural network has 60 million parameters and 650,000 neurons. To make training faster we used non-saturating neurons and an efficient GPU implementation of the convolution operation. To reduce overfitting we employed a regularization method called dropout. We also entered a variant in the ILSVRC-2012 competition and achieved a winning top-5 test error rate of 15.3%.",
    url: "https://papers.nips.cc/paper/2012/hash/c399862d3b9d6b76c8436e924a68c45b-Abstract.html",
    publishedAt: "2012-12-03T00:00:00Z",
  },
  { loopId: "loop:foundational:word2vec", backendId: "arxiv:1301.3781", arxivId: "1301.3781" },
  { loopId: "loop:foundational:seq2seq",  backendId: "arxiv:1409.3215", arxivId: "1409.3215" },
  { loopId: "loop:foundational:gans",     backendId: "arxiv:1406.2661", arxivId: "1406.2661" },
  { loopId: "loop:foundational:resnet",   backendId: "arxiv:1512.03385", arxivId: "1512.03385" },
  { loopId: "loop:foundational:attention", backendId: "arxiv:1706.03762", arxivId: "1706.03762" },
  { loopId: "loop:foundational:gpt3",     backendId: "arxiv:2005.14165", arxivId: "2005.14165" },
  { loopId: "loop:foundational:bert",     backendId: "arxiv:1810.04805", arxivId: "1810.04805" },
];

// ─── Fetch arXiv metadata (no LLM) ───────────────────────────────────────────

async function fetchArxivMeta(arxivId: string) {
  const res = await fetch(`https://export.arxiv.org/api/query?id_list=${arxivId}&max_results=1`);
  if (!res.ok) throw new Error(`arXiv ${res.status} for ${arxivId}`);
  const xml = await res.text();
  const tag = (t: string) =>
    xml.match(new RegExp(`<${t}[^>]*>([\\s\\S]*?)</${t}>`))?.[1]?.replace(/\s+/g, " ").trim();
  const title = tag("title");
  const abstract = tag("summary");
  const published = xml.match(/<published>([\s\S]*?)<\/published>/)?.[1]?.trim();
  const category =
    xml.match(/<arxiv:primary_category[^>]*\bterm="([^"]+)"/)?.[1] ??
    xml.match(/<category[^>]*\bterm="([^"]+)"/)?.[1];
  if (!title || !abstract) throw new Error(`arXiv metadata incomplete for ${arxivId}`);
  return {
    title,
    abstract,
    arxiv_category: category,
    published_at: published ?? new Date().toISOString(),
    url: `https://arxiv.org/abs/${arxivId}`,
  };
}

// ─── Seed ────────────────────────────────────────────────────────────────────

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

interface ResolvedPaper {
  loopId: string;
  paper_id: string;
  title: string;
  abstract: string;
  source: string;
  url: string;
  arxiv_category?: string;
  published_at: string;
}

// 1. Resolve metadata for all 11 (fetch arXiv ones, pace for rate limits).
const resolved: ResolvedPaper[] = [];
for (const c of CURATED) {
  if (c.arxivId) {
    const meta = await fetchArxivMeta(c.arxivId);
    resolved.push({
      loopId: c.loopId,
      paper_id: c.backendId,
      title: meta.title,
      abstract: meta.abstract,
      source: "arxiv",
      url: meta.url,
      arxiv_category: meta.arxiv_category,
      published_at: meta.published_at,
    });
    await new Promise((r) => setTimeout(r, 400));
  } else {
    resolved.push({
      loopId: c.loopId,
      paper_id: c.backendId,
      title: c.title!,
      abstract: c.abstract!,
      source: "rss", // pre-arXiv; "rss" is an accepted source value
      url: c.url ?? "",
      published_at: c.publishedAt ?? new Date().toISOString(),
    });
  }
  console.log(`  resolved ${resolved[resolved.length - 1].paper_id}`);
}

// 2. Upsert all `papers` rows first, so citation edges between curated papers
//    resolve against a complete corpus when the graph stage runs.
const { error: upsertErr } = await supabase.from("papers").upsert(
  resolved.map((p) => ({
    paper_id: p.paper_id,
    title: p.title,
    authors: [],
    abstract: p.abstract,
    source: p.source,
    url: p.url,
    arxiv_category: p.arxiv_category ?? null,
    published_at: p.published_at,
    score: 0.9,
    score_breakdown: {},
    status: "processed",
  })),
  { onConflict: "paper_id" },
);
if (upsertErr) {
  console.error("papers upsert failed:", upsertErr.message);
  Deno.exit(1);
}
console.log(`Upserted ${resolved.length} papers rows.`);

// 3. Graph stage per paper — embedding + citation edges + category.
let embedded = 0;
let edges = 0;
for (const p of resolved) {
  const result = await runGraphStage(supabase, OPENAI_KEY, {
    paper_id: p.paper_id,
    title: p.title,
    abstract: p.abstract,
    source: p.source,
    arxiv_category: p.arxiv_category,
  });
  if (result.embedded) embedded++;
  edges += result.edges;
  const tag = result.errors.length ? `errors: ${result.errors.join("; ")}` : "ok";
  console.log(`  graph ${p.paper_id.padEnd(22)} embed=${result.embedded} edges=${result.edges} ${tag}`);
  await new Promise((r) => setTimeout(r, 3500)); // Semantic Scholar pacing (free tier 429s easily)
}

// 4. Link the audit registry: curated_papers.served_paper_id → backend id.
for (const p of resolved) {
  await supabase
    .from("curated_papers")
    .update({ served_paper_id: p.paper_id, updated_at: new Date().toISOString() })
    .eq("paper_id", p.loopId);
}

console.log(`\nDone: ${resolved.length} curated papers seeded, ${embedded} embedded, ${edges} citation edges.`);
