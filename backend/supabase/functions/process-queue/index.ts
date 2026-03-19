/**
 * Supabase Edge Function: process-queue
 * Triggered every 5 minutes via pg_cron (or via HTTP for manual run).
 * Dequeues papers and runs the full LLM pipeline.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { createOpenAIClient, processPaper } from "../../../src/pipeline.ts";
import type { QueueMessage } from "../../../src/types.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const BATCH_SIZE = 5; // Papers processed per invocation

serve(async (_req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const ai = createOpenAIClient(OPENAI_API_KEY);

  try {
    // 1. Dequeue batch from pgmq
    const { data: messages, error: dequeueError } = await supabase.rpc("pgmq_read", {
      queue_name: "paper_processing",
      vt: 120, // visibility timeout: 2 min
      qty: BATCH_SIZE,
    });

    if (dequeueError) throw dequeueError;
    if (!messages || messages.length === 0) {
      return json({ message: "Queue empty", processed: 0 });
    }

    console.log(`[process-queue] Processing ${messages.length} papers`);

    // 2. Process each paper (with per-paper error isolation)
    const results = await Promise.allSettled(
      messages.map(async (msg: { msg_id: string; message: QueueMessage }) => {
        const paper = msg.message;

        // Fetch full paper record for URL/source
        const { data: paperRecord } = await supabase
          .from("papers")
          .select("source, url")
          .eq("paper_id", paper.paper_id)
          .single();

        const { insight, deck } = await processPaper(ai, {
          paper_id: paper.paper_id,
          title: paper.title,
          abstract: paper.abstract,
          source: paperRecord?.source ?? "unknown",
          url: paperRecord?.url ?? "",
        });

        // 3. Store insight
        await supabase.from("processed_content").upsert({
          paper_id: insight.paper_id,
          headline: insight.headline,
          why_it_matters: insight.why_it_matters,
          core_ideas: insight.core_ideas,
          eli5: insight.eli5,
          analogy: insight.analogy,
          visual: insight.visual,
        }, { onConflict: "paper_id" });

        // 4. Store cards
        await supabase.from("cards").upsert({
          paper_id: deck.paper_id,
          title: deck.title,
          source: deck.source,
          url: deck.url,
          cards: deck.cards,
          created_at: deck.created_at,
        }, { onConflict: "paper_id" });

        // 5. Update paper status
        await supabase
          .from("papers")
          .update({ status: "processed" })
          .eq("paper_id", paper.paper_id);

        // 6. Acknowledge message from queue
        await supabase.rpc("pgmq_delete", {
          queue_name: "paper_processing",
          msg_id: msg.msg_id,
        });

        return paper.paper_id;
      })
    );

    const succeeded = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.filter((r) => r.status === "rejected");

    if (failed.length > 0) {
      console.error("[process-queue] Failed papers:", failed.map((f: any) => f.reason));
    }

    return json({ processed: succeeded, failed: failed.length });
  } catch (err) {
    console.error("[process-queue] Fatal error:", err);
    return json({ error: String(err) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
