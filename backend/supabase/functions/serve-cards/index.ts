/**
 * Supabase Edge Function: serve-cards
 * Public API consumed by the iOS app.
 *
 * GET /serve-cards?page=0&limit=20        → paginated feed (includes score + published_at from papers)
 * POST /serve-cards/interaction           → log swipe/save/share
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const url = new URL(req.url);
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });

  try {
    // POST /serve-cards/interaction
    if (req.method === "POST" && url.pathname.endsWith("/interaction")) {
      const body = await req.json();
      const { action, timestamp } = body;
      const paper_id = preferredPaperId(body.paper_id);

      if (!paper_id || !action) {
        return json({ error: "Missing paper_id or action" }, 400);
      }

      const { error } = await supabase.from("user_interactions").insert({
        paper_id,
        action,
        interacted_at: timestamp ?? new Date().toISOString(),
      });

      if (error) throw error;
      return json({ ok: true });
    }

    // GET /serve-cards/related?paperId=<id>
    // Returns the Explore rails for one paper: citation lineage (buildsOn /
    // ledTo) plus embedding nearest-neighbors (adjacent) and one cross-category
    // surprise pick. Every value is a paper_id present in the corpus.
    if (req.method === "GET" && url.pathname.endsWith("/related")) {
      const paperId = preferredPaperId(url.searchParams.get("paperId") ?? url.searchParams.get("paper_id"));
      if (!paperId) return json({ error: "Missing paperId" }, 400);
      const graphPaperId = await resolveGraphPaperId(supabase, paperId);

      // Citation edges. buildsOn = outgoing cites; ledTo = incoming cites.
      const [outgoing, incoming] = await Promise.all([
        supabase.from("paper_edges").select("to_id").eq("from_id", graphPaperId).eq("kind", "cites"),
        supabase.from("paper_edges").select("from_id").eq("to_id", graphPaperId).eq("kind", "cites"),
      ]);
      if (outgoing.error) throw outgoing.error;
      if (incoming.error) throw incoming.error;

      const buildsOn = (outgoing.data ?? []).map((r: any) => r.to_id);
      const ledTo = (incoming.data ?? []).map((r: any) => r.from_id);

      // Adjacent: pgvector kNN, excluding self + the citation lineage so each
      // rail surfaces distinct papers.
      const lineage = Array.from(new Set([graphPaperId, ...buildsOn, ...ledTo]));
      const { data: matches, error: matchErr } = await supabase.rpc("match_papers", {
        query_id: graphPaperId,
        exclude_ids: lineage,
        match_count: 14,
      });
      if (matchErr) throw matchErr;

      const ranked = (matches ?? []) as Array<{ paper_id: string; arxiv_category: string | null }>;
      const adjacent = ranked.slice(0, 14).map((m) => m.paper_id);

      // Focal paper's category, to find a high-similarity but cross-category
      // "surprise" pick from the same kNN result set.
      const { data: focal } = await supabase
        .from("papers")
        .select("arxiv_category")
        .eq("paper_id", graphPaperId)
        .maybeSingle();
      const focalCategory = (focal as any)?.arxiv_category ?? null;
      const adjacentSet = new Set(adjacent);
      const surprise =
        ranked.find(
          (m) =>
            m.arxiv_category != null &&
            m.arxiv_category !== focalCategory &&
            !adjacentSet.has(m.paper_id),
        )?.paper_id ?? null;

      const openable = await openableRelatedIds(supabase, [
        ...buildsOn,
        ...ledTo,
        ...adjacent,
        ...(surprise ? [surprise] : []),
      ]);
      const resolveOpenable = (id: string) => openable.get(id) ?? null;
      const unique = (ids: string[], limit: number) => {
        const out: string[] = [];
        const seen = new Set<string>();
        for (const id of ids) {
          const openableId = resolveOpenable(id);
          if (!openableId || seen.has(openableId) || openableId === paperId) continue;
          seen.add(openableId);
          out.push(openableId);
          if (out.length >= limit) break;
        }
        return out;
      };

      return json({
        paperId,
        graphPaperId,
        buildsOn: unique(buildsOn, 12),
        ledTo: unique(ledTo, 12),
        adjacent: unique(adjacent, 8),
        surprise: surprise ? resolveOpenable(surprise) : null,
      });
    }

    // GET /serve-cards/web-lessons
    // Returns { paper_id: web_lesson_url } for every catalog paper that has a
    // server-driven web bundle. The iOS app loads this once and renders those
    // papers from the bundle instead of a native reader, no app update needed.
    if (req.method === "GET" && url.pathname.endsWith("/web-lessons")) {
      const { data, error } = await supabase
        .from("paper_catalog")
        .select("paper_id, web_lesson_url")
        .not("web_lesson_url", "is", null);
      if (error) throw error;
      const map: Record<string, string> = {};
      for (const r of (data ?? []) as Array<{ paper_id: string; web_lesson_url: string }>) {
        map[r.paper_id] = r.web_lesson_url;
        for (const alias of aliasesFor(r.paper_id)) {
          map[alias] = r.web_lesson_url;
        }
      }
      return json(map);
    }

    // GET /serve-cards
    if (req.method === "GET") {
      // Single-deck lookup: GET /serve-cards?paper_id=<id>
      const paperIdParam = preferredPaperId(url.searchParams.get("paper_id"));
      if (paperIdParam) {
        const { data, error } = await supabase
          .from("cards")
          .select(`
            paper_id,
            title,
            source,
            url,
            cards,
            blueprint,
            web_lesson_url,
            created_at,
            papers!inner (
              score,
              published_at,
              arxiv_category
            )
          `)
          .eq("paper_id", paperIdParam)
          .maybeSingle();

        if (error) throw error;
        if (!data) {
          const catalogDeck = await webCatalogDeck(supabase, paperIdParam);
          if (catalogDeck) return json(catalogDeck);
          return json({ error: "Not found" }, 404);
        }

        const { papers, cards, blueprint, ...rest } = data as any;
        return json({
          ...rest,
          score:         papers?.score          ?? null,
          published_at:  papers?.published_at   ?? null,
          arxiv_category: papers?.arxiv_category ?? null,
          hook:         cards?.hook          ?? null,
          summary:      cards?.summary       ?? null,
          concepts:     cards?.concepts      ?? [],
          blueprint:    blueprint            ?? null,
        });
      }

      const page  = parseInt(url.searchParams.get("page")  ?? "0");
      const limit = Math.min(parseInt(url.searchParams.get("limit") ?? "20"), 50);
      const offset = page * limit;

      // Join cards → papers to pull score + published_at up to the top level.
      // Order by the paper's real publish date (freshest research first);
      // created_at would surface whichever card our pipeline processed most
      // recently, not what was actually published recently.
      const { data: rawDecks, error, count } = await supabase
        .from("cards")
        .select(
          `
          paper_id,
          title,
          source,
          url,
          cards,
          blueprint,
          web_lesson_url,
          created_at,
          papers!inner (
            score,
            published_at,
            arxiv_category
          )
        `,
          { count: "exact" }
        )
        .order("published_at", { foreignTable: "papers", ascending: false, nullsFirst: false })
        .order("created_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) throw error;

      // Flatten score, published_at, summary and concepts to the top level
      let decks = (rawDecks ?? []).map((deck: any) => {
        const { papers, cards, blueprint, ...rest } = deck;
        return {
          ...rest,
          score:         papers?.score          ?? null,
          published_at:  papers?.published_at   ?? null,
          arxiv_category: papers?.arxiv_category ?? null,
          hook:         cards?.hook          ?? null,
          summary:      cards?.summary       ?? null,
          concepts:     cards?.concepts      ?? [],
          blueprint:    blueprint            ?? null,
        };
      });

      // Web-bundle-only papers may live in `paper_catalog` before they have a
      // full LLM-generated `cards` row. Surface them as lightweight decks on
      // the first page so existing app binaries can discover them in Search,
      // then render via `web_lesson_url` with no App Store update.
      if (page === 0) {
        const existingIds = new Set(decks.map((deck: any) => deck.paper_id));
        const { data: webRows, error: webErr } = await supabase
          .from("paper_catalog")
          .select("paper_id, title, source, topic, url, arxiv_id, published_at, year, web_lesson_url")
          .not("web_lesson_url", "is", null)
          .order("published_at", { ascending: false, nullsFirst: false })
          .order("year", { ascending: false, nullsFirst: false });
        if (webErr) throw webErr;

        const webDecks = (webRows ?? [])
          .filter((row: any) => !existingIds.has(row.paper_id))
          .map(catalogRowToDeck);
        decks = [...webDecks, ...decks];
      }

      return json({
        decks,
        page,
        has_more: (count ?? 0) > offset + limit,
      });
    }

    return json({ error: "Not found" }, 404);
  } catch (err: any) {
    const msg = err?.message ?? err?.error_description ?? String(err);
    const code = err?.code ?? err?.status ?? undefined;
    console.error("[serve-cards] Error:", msg, code);
    return json({ error: msg, code }, 500);
  }
});

async function webCatalogDeck(supabase: any, paperId: string) {
  const { data, error } = await supabase
    .from("paper_catalog")
    .select("paper_id, title, source, topic, url, arxiv_id, published_at, year, web_lesson_url")
    .eq("paper_id", paperId)
    .not("web_lesson_url", "is", null)
    .maybeSingle();
  if (error) throw error;
  return data ? catalogRowToDeck(data) : null;
}

function preferredPaperId(id: string | null | undefined): string {
  if (!id) return "";
  return PAPER_ID_ALIASES[id] ?? id;
}

function aliasesFor(id: string): string[] {
  return PAPER_ID_REVERSE_ALIASES[id] ?? [];
}

async function resolveGraphPaperId(supabase: any, paperId: string): Promise<string> {
  // App-facing curated ids (`loop:...`) can have lightweight `papers` rows so
  // search can return them as blueprint decks. For graph rails, prefer their
  // canonical arXiv row when the catalog knows one.
  if (paperId.startsWith("loop:")) {
    const aliased = await resolveCatalogGraphAlias(supabase, paperId);
    if (aliased) return aliased;
  }

  const { data: direct, error: directErr } = await supabase
    .from("papers")
    .select("paper_id")
    .eq("paper_id", paperId)
    .maybeSingle();
  if (directErr) throw directErr;
  if (direct?.paper_id) return direct.paper_id;

  const aliased = await resolveCatalogGraphAlias(supabase, paperId);
  if (aliased) return aliased;

  return paperId;
}

async function resolveCatalogGraphAlias(supabase: any, paperId: string): Promise<string | null> {
  const { data: catalog, error: catalogErr } = await supabase
    .from("paper_catalog")
    .select("canonical_key, arxiv_id")
    .eq("paper_id", paperId)
    .maybeSingle();
  if (catalogErr) throw catalogErr;

  const candidates = [
    catalog?.arxiv_id ? `arxiv:${String(catalog.arxiv_id).replace(/^arxiv:/, "")}` : null,
    typeof catalog?.canonical_key === "string" && catalog.canonical_key.startsWith("arxiv:")
      ? catalog.canonical_key
      : null,
  ].filter(Boolean) as string[];

  for (const candidate of candidates) {
    const { data, error } = await supabase
      .from("papers")
      .select("paper_id")
      .eq("paper_id", candidate)
      .maybeSingle();
    if (error) throw error;
    if (data?.paper_id) return data.paper_id;
  }

  return null;
}

async function openableRelatedIds(supabase: any, ids: string[]): Promise<Map<string, string>> {
  const uniqueIds = Array.from(new Set(ids.filter(Boolean)));
  const openable = new Map<string, string>();
  if (uniqueIds.length === 0) return openable;

  const { data: cardRows, error: cardErr } = await supabase
    .from("cards")
    .select("paper_id")
    .in("paper_id", uniqueIds);
  if (cardErr) throw cardErr;
  for (const row of (cardRows ?? []) as Array<{ paper_id: string }>) {
    openable.set(row.paper_id, row.paper_id);
  }

  const { data: directCatalogRows, error: directCatalogErr } = await supabase
    .from("paper_catalog")
    .select("paper_id, web_lesson_url")
    .in("paper_id", uniqueIds)
    .not("web_lesson_url", "is", null);
  if (directCatalogErr) throw directCatalogErr;
  for (const row of (directCatalogRows ?? []) as Array<{ paper_id: string; web_lesson_url: string | null }>) {
    if (row.web_lesson_url) openable.set(row.paper_id, row.paper_id);
  }

  const arxivIds = uniqueIds
    .filter((id) => id.startsWith("arxiv:"))
    .map((id) => id.replace(/^arxiv:/, ""));
  if (arxivIds.length === 0) return openable;

  const canonicalKeys = arxivIds.map((id) => `arxiv:${id}`);
  const { data: aliasRows, error: aliasErr } = await supabase
    .from("paper_catalog")
    .select("paper_id, canonical_key, arxiv_id, web_lesson_url")
    .or(`canonical_key.in.(${canonicalKeys.join(",")}),arxiv_id.in.(${arxivIds.join(",")})`);
  if (aliasErr) throw aliasErr;

  const aliasPaperIds = Array.from(new Set((aliasRows ?? []).map((row: any) => row.paper_id)));
  let aliasCards = new Set<string>();
  if (aliasPaperIds.length > 0) {
    const { data: aliasCardRows, error: aliasCardErr } = await supabase
      .from("cards")
      .select("paper_id")
      .in("paper_id", aliasPaperIds);
    if (aliasCardErr) throw aliasCardErr;
    aliasCards = new Set((aliasCardRows ?? []).map((row: any) => row.paper_id));
  }

  for (const row of (aliasRows ?? []) as Array<{
    paper_id: string;
    canonical_key: string | null;
    arxiv_id: string | null;
    web_lesson_url: string | null;
  }>) {
    if (!row.web_lesson_url && !aliasCards.has(row.paper_id)) continue;
    const graphIds = [
      row.arxiv_id ? `arxiv:${String(row.arxiv_id).replace(/^arxiv:/, "")}` : null,
      row.canonical_key?.startsWith("arxiv:") ? row.canonical_key : null,
    ].filter(Boolean) as string[];
    for (const graphId of graphIds) {
      if (uniqueIds.includes(graphId)) openable.set(graphId, row.paper_id);
    }
  }

  return openable;
}

function catalogRowToDeck(row: any) {
  const year = row.year ?? (row.published_at ? new Date(row.published_at).getUTCFullYear() : null);
  const topic = row.topic ? String(row.topic) : null;
  const editorial = WEB_LESSON_COPY[row.paper_id] ?? null;
  // Editorial title wins over the catalog row so a web lesson can carry the
  // full paper title without re-running the publish script / DB migration.
  const title = editorial?.title ?? row.title ?? row.paper_id;
  const hookParts = [
    year ? String(year) : null,
    topic ? `${topic} web lesson` : "Interactive web lesson",
  ].filter(Boolean);

  return {
    paper_id: row.paper_id,
    title,
    source: row.source ?? "web_lesson",
    url: row.url ?? (row.arxiv_id ? `https://arxiv.org/abs/${row.arxiv_id}` : null),
    cards: null,
    blueprint: null,
    web_lesson_url: row.web_lesson_url,
    created_at: null,
    score: null,
    published_at: row.published_at ?? (year ? `${year}-01-01T00:00:00Z` : null),
    arxiv_category: null,
    hook: editorial?.hook ?? (hookParts.length > 0 ? hookParts.join(". ") + "." : "Interactive web lesson."),
    summary: editorial?.summary ?? (topic
      ? `A bespoke interactive lesson about ${title}, served as a web bundle.`
      : `A bespoke interactive lesson about ${title}.`),
    concepts: [],
  };
}

const WEB_LESSON_COPY: Record<string, { title?: string; hook: string; summary: string }> = {
  "flashattention": {
    hook: "Same attention, fewer memory trips. The trick that made long context feel less ridiculous.",
    summary: "FlashAttention keeps small tiles in fast GPU memory and updates softmax online, so Transformers get the exact same answer while moving far fewer bytes.",
  },
  "grokking": {
    title: "Grokking: Generalization Beyond Overfitting on Small Algorithmic Datasets",
    hook: "It memorised the data, looked hopelessly overfit, then woke up and understood the rule.",
    summary: "On tiny algorithmic tasks like modular arithmetic, a network hits 100% training accuracy fast while validation sits at chance, looking textbook overfit. Keep training tens of thousands of steps past that and validation suddenly snaps to near perfect: the model switched from a memorised lookup table to the underlying rule. Weight decay, a gentle pressure toward simpler weights, is what drives this delayed leap from memorising to generalising.",
  },
  "loop:systems:flashattention": {
    hook: "Same attention, fewer memory trips. The trick that made long context feel less ridiculous.",
    summary: "FlashAttention keeps small tiles in fast GPU memory and updates softmax online, so Transformers get the exact same answer while moving far fewer bytes.",
  },
  "loop:foundational:grokking": {
    title: "Grokking: Generalization Beyond Overfitting on Small Algorithmic Datasets",
    hook: "It memorised the data, looked hopelessly overfit, then woke up and understood the rule.",
    summary: "On tiny algorithmic tasks like modular arithmetic, a network hits 100% training accuracy fast while validation sits at chance, looking textbook overfit. Keep training tens of thousands of steps past that and validation suddenly snaps to near perfect: the model switched from a memorised lookup table to the underlying rule. Weight decay, a gentle pressure toward simpler weights, is what drives this delayed leap from memorising to generalising.",
  },
};

const PAPER_ID_ALIASES: Record<string, string> = {
  "loop:foundational:perceptron": "perceptron",
  "rosenblatt:1958": "perceptron",
  "loop:foundational:backprop": "backprop",
  "rumelhart:1986": "backprop",
  "loop:foundational:lenet": "lenet",
  "lecun:1998": "lenet",
  "loop:foundational:alexnet": "alexnet",
  "krizhevsky:2012": "alexnet",
  "loop:foundational:word2vec": "word2vec",
  "arxiv:1301.3781": "word2vec",
  "loop:foundational:seq2seq": "seq2seq",
  "arxiv:1409.3215": "seq2seq",
  "loop:foundational:gans": "gans",
  "arxiv:1406.2661": "gans",
  "loop:foundational:resnet": "resnet",
  "arxiv:1512.03385": "resnet",
  "loop:foundational:attention": "attention",
  "arxiv:1706.03762": "attention",
  "loop:foundational:gpt3": "gpt3",
  "arxiv:2005.14165": "gpt3",
  "loop:foundational:bert": "bert",
  "arxiv:1810.04805": "bert",
  "loop:foundational:instructgpt": "instructgpt",
  "arxiv:2203.02155": "instructgpt",
  "loop:foundational:chain-of-thought": "chain-of-thought",
  "arxiv:2201.11903": "chain-of-thought",
  "loop:foundational:scratchpad": "scratchpad",
  "arxiv:2112.00114": "scratchpad",
  "loop:foundational:self-consistency": "self-consistency",
  "arxiv:2203.11171": "self-consistency",
  "loop:foundational:tot": "tree-of-thoughts",
  "arxiv:2305.10601": "tree-of-thoughts",
  "loop:foundational:least-to-most": "least-to-most",
  "arxiv:2205.10625": "least-to-most",
  "loop:foundational:react": "react",
  "arxiv:2210.03629": "react",
  "loop:foundational:toolformer": "toolformer",
  "arxiv:2302.04761": "toolformer",
  "loop:foundational:grokking": "grokking",
  "arxiv:2201.02177": "grokking",
  "loop:foundational:deepseek-r1": "deepseek-r1",
  "arxiv:2501.12948": "deepseek-r1",
  "loop:vision:vit": "vit",
  "arxiv:2010.11929": "vit",
  "loop:vision:ddpm": "ddpm",
  "arxiv:2006.11239": "ddpm",
  "loop:vision:clip": "clip",
  "arxiv:2103.00020": "clip",
  "loop:vision:sd": "stable-diffusion",
  "arxiv:2112.10752": "stable-diffusion",
  "loop:vision:controlnet": "controlnet",
  "arxiv:2302.05543": "controlnet",
  "loop:vision:sam": "sam",
  "arxiv:2304.02643": "sam",
  "loop:language:t5": "t5",
  "arxiv:1910.10683": "t5",
  "loop:language:chinchilla": "chinchilla",
  "arxiv:2203.15556": "chinchilla",
  "loop:language:palm": "palm",
  "arxiv:2204.02311": "palm",
  "loop:language:llama": "llama",
  "arxiv:2302.13971": "llama",
  "loop:language:mixtral": "mixtral",
  "arxiv:2401.04088": "mixtral",
  "loop:reasoning:reflexion": "reflexion",
  "arxiv:2303.11366": "reflexion",
  "loop:systems:flashattention": "flashattention",
  "arxiv:2205.14135": "flashattention",
  "domingos:2012": "useful-things-ml",
  "loop:domingos": "useful-things-ml",
  "arxiv:2401.06816": "creative-writing-homogenization",
};

const PAPER_ID_REVERSE_ALIASES: Record<string, string[]> = Object.entries(PAPER_ID_ALIASES)
  .reduce((acc, [alias, preferred]) => {
    acc[preferred] = [...(acc[preferred] ?? []), alias];
    return acc;
  }, {} as Record<string, string[]>);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
