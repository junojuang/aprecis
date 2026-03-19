/**
 * Supabase Edge Function: cron-ingest
 * Triggered every 1–2 hours via pg_cron.
 * Fetches papers, scores them, deduplicates, and enqueues for processing.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Import from shared src — Supabase bundles these at deploy time
import { fetchArxiv, fetchGitHubTrending, fetchHackerNews, fetchRSSFeeds } from "../../../src/ingestion.ts";
import { filterPapers } from "../../../src/scoring.ts";
import type { ScoredPaper } from "../../../src/types.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GITHUB_TOKEN = Deno.env.get("GITHUB_TOKEN");

serve(async (req) => {
  // Allow cron trigger (GET) or manual trigger (POST)
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  try {
    console.log("[cron-ingest] Starting ingestion run");

    // 1. Fetch from all sources in parallel
    const [arxivPapers, githubPapers, rssPapers, hnPapers] = await Promise.allSettled([
      fetchArxiv(60),
      fetchGitHubTrending(GITHUB_TOKEN),
      fetchRSSFeeds(),
      fetchHackerNews(30),
    ]);

    const allPapers = [
      ...(arxivPapers.status === "fulfilled" ? arxivPapers.value : []),
      ...(githubPapers.status === "fulfilled" ? githubPapers.value : []),
      ...(rssPapers.status === "fulfilled" ? rssPapers.value : []),
      ...(hnPapers.status === "fulfilled" ? hnPapers.value : []),
    ];

    console.log(`[cron-ingest] Fetched ${allPapers.length} raw papers`);

    // 2. Score and filter
    const scored = filterPapers(allPapers);
    console.log(`[cron-ingest] ${scored.length} papers passed scoring`);

    if (scored.length === 0) {
      return json({ message: "No papers passed scoring", ingested: 0 });
    }

    // 3. Deduplicate against existing paper_ids
    const ids = scored.map((p) => p.paper_id);
    const { data: existing } = await supabase
      .from("papers")
      .select("paper_id")
      .in("paper_id", ids);

    const existingIds = new Set((existing ?? []).map((r: any) => r.paper_id));
    const newPapers = [
      ...new Map(
        scored.filter((p) => !existingIds.has(p.paper_id)).map((p) => [p.paper_id, p])
      ).values(),
    ];

    console.log(`[cron-ingest] ${newPapers.length} new papers to process`);

    if (newPapers.length === 0) {
      return json({ message: "All papers already ingested", ingested: 0 });
    }

    // 4. Upsert papers into DB
    const { error: insertError } = await supabase.from("papers").upsert(
      newPapers.map((p) => ({
        paper_id: p.paper_id,
        title: p.title,
        authors: p.authors,
        abstract: p.abstract,
        source: p.source,
        url: p.url,
        pdf_url: p.pdf_url,
        published_at: p.published_at,
        score: p.score,
        score_breakdown: p.score_breakdown,
        status: "queued",
      })),
      { onConflict: "paper_id" }
    );

    if (insertError) throw insertError;

    // 5. Enqueue for processing via pgmq
    const queueMessages = newPapers.map((p) => ({
      paper_id: p.paper_id,
      abstract: p.abstract,
      title: p.title,
      pdf_url: p.pdf_url,
      enqueued_at: new Date().toISOString(),
    }));

    const { error: queueError } = await supabase.rpc("pgmq_send_batch", {
      queue_name: "paper_processing",
      messages: queueMessages,
    });

    if (queueError) {
      console.warn("[cron-ingest] Queue error (non-fatal):", queueError.message);
    }

    return json({ message: "Ingestion complete", ingested: newPapers.length });
  } catch (err) {
    console.error("[cron-ingest] Error:", err);
    return json({ error: String(err) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
