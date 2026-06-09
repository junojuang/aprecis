/**
 * Supabase Edge Function: add-paper
 * POST { arxiv_id: "2301.07041" } , or,  { url: "https://arxiv.org/abs/2301.07041" }
 *
 * Fetches the paper from arXiv, runs the full LLM pipeline synchronously,
 * stores results in DB, and returns the CardDeck ready for the iOS app.
 *
 * If the paper was already processed, returns the cached deck immediately.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createAnthropicClient, processPaper } from "../../../src/pipeline.ts";
import { runGraphStage } from "../../../src/graph.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY"); // embeddings; optional

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  let body: { arxiv_id?: string; url?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  // ── 1. Parse arXiv ID ────────────────────────────────────────────────────────
  const rawId = body.arxiv_id ?? parseArxivId(body.url ?? "");
  if (!rawId) {
    return json({ error: "Provide arxiv_id or a valid arXiv URL" }, 400);
  }
  const arxivId = rawId.replace(/v\d+$/, "");
  const paperId = `arxiv:${arxivId}`;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  // ── 2. Return cached deck if already processed (new format) ──────────────────
  const { data: cached } = await supabase
    .from("cards")
    .select("paper_id, title, source, url, cards, papers!inner(published_at, score, authors, pdf_url)")
    .eq("paper_id", paperId)
    .single();

  if (cached && (cached.cards as any)?.concepts?.length > 0) {
    console.log(`[add-paper] Cache hit for ${paperId}`);
    const c = cached.cards as any;
    return json({
      paper_id: cached.paper_id,
      title: cached.title,
      source: cached.source,
      url: cached.url,
      hook: c.hook ?? null,
      summary: c.summary ?? null,
      concepts: c.concepts ?? [],
      published_at: (cached as any).papers?.published_at ?? null,
      score: (cached as any).papers?.score ?? 0.8,
      authors: (cached as any).papers?.authors ?? [],
      pdf_url: (cached as any).papers?.pdf_url ?? null,
    });
  }
  // Soft cache-miss: card row exists but predates per-concept diagrams.
  // The fresh-pipeline path below will overwrite with a richer payload.

  // ── 3. Fetch paper metadata from arXiv ───────────────────────────────────────
  const paper = await fetchArxivPaper(arxivId);
  if (!paper) {
    return json({ error: `Paper ${arxivId} not found on arXiv` }, 404);
  }

  console.log(`[add-paper] Processing: ${paper.title}`);

  // ── 4. Insert paper record ───────────────────────────────────────────────────
  await supabase.from("papers").upsert({
    paper_id: paper.paper_id,
    title: paper.title,
    abstract: paper.abstract,
    authors: paper.authors,
    source: "arxiv",
    url: paper.url,
    pdf_url: paper.pdf_url,
    arxiv_category: paper.arxiv_category ?? null,
    published_at: paper.published_at,
    score: 0.8,
    score_breakdown: {},
    status: "processing",
  }, { onConflict: "paper_id" });

  // ── 5. Run LLM pipeline ──────────────────────────────────────────────────────
  const ai = createAnthropicClient(ANTHROPIC_API_KEY);

  let deck;
  try {
    deck = await processPaper(ai, {
      paper_id: paper.paper_id,
      title: paper.title,
      abstract: paper.abstract,
      source: "arxiv",
      url: paper.url,
    });
  } catch (err: any) {
    await supabase.from("papers").update({ status: "failed" }).eq("paper_id", paperId);
    return json({ error: `Pipeline failed: ${err?.message ?? String(err)}` }, 500);
  }

  // ── 6. Persist results ───────────────────────────────────────────────────────
  const { error: cardsErr } = await supabase.from("cards").upsert({
    paper_id: deck.paper_id,
    title: deck.title,
    source: deck.source,
    url: deck.url,
    cards: {
      hook: deck.hook,
      summary: deck.summary,
      concepts: deck.concepts,
    },
    blueprint: deck.blueprint ?? null,
  }, { onConflict: "paper_id" });

  if (cardsErr) {
    return json({ error: `cards upsert: ${cardsErr.message}` }, 500);
  }

  // ── 7. Graph stage: embedding + citation edges + category ────────────────────
  // Same as the cron pipeline, so a hand-added paper gets Explore rails too.
  // Failure-isolated: never blocks returning the deck.
  if (OPENAI_API_KEY) {
    try {
      const graph = await runGraphStage(supabase, OPENAI_API_KEY, {
        paper_id: deck.paper_id,
        title: deck.title,
        abstract: paper.abstract,
        source: "arxiv",
        arxiv_category: paper.arxiv_category,
        coreIdeas: deck.concepts.map((c) => c.title),
      });
      if (graph.errors.length) console.warn(`[add-paper] graph ${paperId}:`, graph.errors);
    } catch (graphErr) {
      console.warn(`[add-paper] graph stage threw for ${paperId}:`, graphErr);
    }
  }

  await supabase.from("papers").update({ status: "processed" }).eq("paper_id", paperId);

  console.log(`[add-paper] Done: ${paperId}`);

  // ── 8. Return deck for immediate display ─────────────────────────────────────
  return json({
    paper_id: deck.paper_id,
    title: deck.title,
    source: deck.source,
    url: deck.url,
    hook: deck.hook,
    summary: deck.summary,
    concepts: deck.concepts,
    published_at: paper.published_at,
    score: 0.8,
    authors: paper.authors ?? [],
    pdf_url: paper.pdf_url ?? null,
  });
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function parseArxivId(input: string): string | null {
  if (!input) return null;
  const m = input.match(/(\d{4}\.\d{4,5}(?:v\d+)?)/);
  return m?.[1] ?? null;
}

async function fetchArxivPaper(arxivId: string) {
  const res = await fetch(
    `https://export.arxiv.org/api/query?id_list=${arxivId}&max_results=1`
  );
  if (!res.ok) return null;
  const xml = await res.text();

  if (xml.includes("<title>Error</title>")) return null;

  const title = extractXml(xml, "title", 1);
  const summary = extractXml(xml, "summary");
  const published = extractXml(xml, "published");
  if (!title || !summary) return null;

  const authorMatches = [...xml.matchAll(/<name>(.*?)<\/name>/g)].map(m => m[1]);
  const arxivCategory =
    xml.match(/<arxiv:primary_category[^>]*\bterm="([^"]+)"/)?.[1] ??
    xml.match(/<category[^>]*\bterm="([^"]+)"/)?.[1];

  return {
    paper_id: `arxiv:${arxivId}`,
    title: title.replace(/\s+/g, " ").trim(),
    abstract: summary.replace(/\s+/g, " ").trim(),
    authors: authorMatches.slice(0, 8),
    url: `https://arxiv.org/abs/${arxivId}`,
    pdf_url: `https://arxiv.org/pdf/${arxivId}`,
    arxiv_category: arxivCategory,
    published_at: published ?? new Date().toISOString(),
  };
}

function extractXml(xml: string, tag: string, index = 0): string | null {
  const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, "g");
  let match: RegExpExecArray | null;
  let i = 0;
  while ((match = re.exec(xml)) !== null) {
    if (i === index) return match[1];
    i++;
  }
  return null;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
