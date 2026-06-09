/**
 * Paper graph stage: embeddings + citation edges.
 *
 * Runs after the LLM pipeline. Three independent, failure-isolated steps:
 *   1. Embed   — OpenAI text-embedding-3-small → papers.embedding
 *   2. Citations — Semantic Scholar lookup → paper_edges rows
 *   3. Category — write papers.arxiv_category from the ingest payload
 *
 * Each step is wrapped so one external failure (OpenAI 500, Semantic Scholar
 * 429) never blocks the others or fails the paper. A paper with an embedding
 * but no citations still gets an Adjacent rail.
 *
 * Deno-compatible: no npm imports. The Supabase client is passed in by the
 * caller (edge function or backfill script) so this module stays runtime-free.
 */

// Minimal structural type for the bits of the supabase-js client we use.
// Avoids importing supabase-js here so the module loads in any Deno context.
export interface SupabaseLike {
  from: (table: string) => any;
}

export interface GraphStageInput {
  paper_id: string;
  title: string;
  abstract: string;
  source: string;
  arxiv_category?: string;
  coreIdeas?: string[]; // optional LLM-extracted ideas — sharpen the embedding
}

export interface GraphStageResult {
  embedded: boolean;
  edges: number;
  category: boolean;
  errors: string[];
}

const EMBEDDING_MODEL = "text-embedding-3-small";
const EMBEDDING_DIMS = 1536;

// ─── Embeddings ──────────────────────────────────────────────────────────────

/** Embed text with OpenAI. Returns a 1536-dim vector. */
export async function embedText(openaiKey: string, text: string): Promise<number[]> {
  const res = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${openaiKey}`,
    },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: text.slice(0, 8000), // ~8k chars is well under the token cap
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message ?? `OpenAI embeddings ${res.status}`);
  const vec = data.data?.[0]?.embedding;
  if (!Array.isArray(vec) || vec.length !== EMBEDDING_DIMS) {
    throw new Error(`Unexpected embedding shape: ${vec?.length}`);
  }
  return vec;
}

/** Build the embedding input string: title + abstract + core ideas. */
function embeddingInput(p: GraphStageInput): string {
  const parts = [p.title, p.abstract];
  if (p.coreIdeas && p.coreIdeas.length) parts.push(p.coreIdeas.join(". "));
  return parts.filter(Boolean).join("\n\n");
}

// ─── arXiv id helpers ────────────────────────────────────────────────────────

/**
 * Extract the bare arXiv id from one of our paper_ids.
 * `arxiv:2401.12345v2` → `2401.12345`. Returns null for non-arxiv papers.
 */
export function arxivIdFromPaperId(paperId: string): string | null {
  const m = paperId.match(/arxiv:(\d{4}\.\d{4,5})/i);
  return m ? m[1] : null;
}

/** Strip a trailing version suffix: `2401.12345v3` → `2401.12345`. */
function normalizeArxivId(id: string): string {
  return id.replace(/v\d+$/i, "").trim();
}

// ─── Semantic Scholar citations ──────────────────────────────────────────────

interface CitationResult {
  semanticScholarId: string | null;
  references: string[]; // normalized arXiv ids this paper cites
  citations: string[];  // normalized arXiv ids that cite this paper
}

/**
 * Look a paper up on Semantic Scholar by arXiv id and pull its reference +
 * citation arXiv ids. Free tier, ~1 req/sec unauthenticated.
 */
export async function fetchCitations(arxivId: string): Promise<CitationResult> {
  const fields = "externalIds,references.externalIds,citations.externalIds";
  const url =
    `https://api.semanticscholar.org/graph/v1/paper/arXiv:${arxivId}?fields=${fields}`;

  // Semantic Scholar's free tier 429s readily. Retry on 429 / 5xx with
  // exponential backoff, honoring Retry-After when the server sends it.
  let res: Response | undefined;
  for (let attempt = 0; attempt < 4; attempt++) {
    res = await fetch(url, { headers: { Accept: "application/json" } });
    if (res.ok) break;
    if (res.status !== 429 && res.status < 500) break; // non-retryable
    if (attempt === 3) break;
    const retryAfter = Number(res.headers.get("retry-after"));
    const waitMs = Number.isFinite(retryAfter) && retryAfter > 0
      ? retryAfter * 1000
      : 1500 * Math.pow(2, attempt); // 1.5s, 3s, 6s
    await new Promise((r) => setTimeout(r, waitMs));
  }
  if (!res || !res.ok) {
    throw new Error(`Semantic Scholar ${res?.status ?? "no response"} for arXiv:${arxivId}`);
  }
  const data = await res.json();

  const pullArxiv = (list: any[]): string[] =>
    (list ?? [])
      .map((x) => x?.externalIds?.ArXiv)
      .filter((id): id is string => typeof id === "string" && id.length > 0)
      .map(normalizeArxivId);

  return {
    semanticScholarId: data?.paperId ?? null,
    references: pullArxiv(data?.references),
    citations: pullArxiv(data?.citations),
  };
}

// ─── Corpus lookup ───────────────────────────────────────────────────────────

/**
 * Map normalized arXiv id → our paper_id, for every arxiv paper in the corpus.
 * One column-only scan; cheap up to tens of thousands of rows. If the corpus
 * grows large, swap for a per-candidate `.in()` lookup with a normalized
 * `arxiv_norm` column.
 */
async function corpusArxivIndex(
  supabase: SupabaseLike,
): Promise<Map<string, string>> {
  const index = new Map<string, string>();
  const { data, error } = await supabase
    .from("papers")
    .select("paper_id")
    .eq("source", "arxiv");
  if (error) throw new Error(`corpus index: ${error.message}`);
  for (const row of data ?? []) {
    const bare = arxivIdFromPaperId(row.paper_id);
    if (bare) index.set(bare, row.paper_id);
  }
  return index;
}

// ─── Orchestrator ────────────────────────────────────────────────────────────

/**
 * Run the full graph stage for one paper. Never throws — every failure is
 * caught and reported in `result.errors` so the caller can log without the
 * paper's pipeline run failing.
 */
export async function runGraphStage(
  supabase: SupabaseLike,
  openaiKey: string,
  paper: GraphStageInput,
): Promise<GraphStageResult> {
  const result: GraphStageResult = {
    embedded: false,
    edges: 0,
    category: false,
    errors: [],
  };

  // ── Step 1: embed ──────────────────────────────────────────────────────
  try {
    const vec = await embedText(openaiKey, embeddingInput(paper));
    const { error } = await supabase
      .from("papers")
      .update({ embedding: JSON.stringify(vec) })
      .eq("paper_id", paper.paper_id);
    if (error) throw new Error(error.message);
    result.embedded = true;
  } catch (err) {
    result.errors.push(`embed: ${err instanceof Error ? err.message : String(err)}`);
  }

  // ── Step 3: category (cheap, do early; independent of network) ─────────
  if (paper.arxiv_category) {
    try {
      const { error } = await supabase
        .from("papers")
        .update({ arxiv_category: paper.arxiv_category })
        .eq("paper_id", paper.paper_id);
      if (error) throw new Error(error.message);
      result.category = true;
    } catch (err) {
      result.errors.push(`category: ${err instanceof Error ? err.message : String(err)}`);
    }
  }

  // ── Step 2: citations ──────────────────────────────────────────────────
  const arxivId = arxivIdFromPaperId(paper.paper_id);
  if (arxivId) {
    try {
      const cites = await fetchCitations(arxivId);

      if (cites.semanticScholarId) {
        await supabase
          .from("papers")
          .update({ semantic_scholar_id: cites.semanticScholarId })
          .eq("paper_id", paper.paper_id);
      }

      const index = await corpusArxivIndex(supabase);
      const self = paper.paper_id;
      const rows: { from_id: string; to_id: string; kind: string }[] = [];

      // references: this paper cites them → edge self → ref
      for (const refArxiv of cites.references) {
        const refId = index.get(refArxiv);
        if (refId && refId !== self) {
          rows.push({ from_id: self, to_id: refId, kind: "cites" });
        }
      }
      // citations: they cite this paper → edge citer → self
      for (const citerArxiv of cites.citations) {
        const citerId = index.get(citerArxiv);
        if (citerId && citerId !== self) {
          rows.push({ from_id: citerId, to_id: self, kind: "cites" });
        }
      }

      if (rows.length) {
        // Dedup within the batch, then upsert (ignore existing edges).
        const seen = new Set<string>();
        const unique = rows.filter((r) => {
          const k = `${r.from_id}|${r.to_id}|${r.kind}`;
          if (seen.has(k)) return false;
          seen.add(k);
          return true;
        });
        const { error } = await supabase
          .from("paper_edges")
          .upsert(unique, { onConflict: "from_id,to_id,kind", ignoreDuplicates: true });
        if (error) throw new Error(error.message);
        result.edges = unique.length;
      }
    } catch (err) {
      result.errors.push(`citations: ${err instanceof Error ? err.message : String(err)}`);
    }
  }

  return result;
}
