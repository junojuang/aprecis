/**
 * Supabase Edge Function: process-queue
 * Triggered every 5 minutes via pg_cron (or via HTTP for manual run).
 * Dequeues papers and runs the full LLM pipeline.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { createAnthropicClient, processPaper } from "../../../src/pipeline.ts";
import { runGraphStage } from "../../../src/graph.ts";
import type { QueueMessage } from "../../../src/types.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY"); // embeddings; optional
const BATCH_SIZE = 5; // Papers processed per invocation

serve(async (_req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const ai = createAnthropicClient(ANTHROPIC_API_KEY);

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

        // Fetch full paper record for URL/source/category
        const { data: paperRecord } = await supabase
          .from("papers")
          .select("source, url, abstract, arxiv_category")
          .eq("paper_id", paper.paper_id)
          .single();

        const deck = await processPaper(ai, {
          paper_id: paper.paper_id,
          title: paper.title,
          abstract: paper.abstract,
          source: paperRecord?.source ?? "unknown",
          url: paperRecord?.url ?? "",
        });

        // 3. Store deck (new concept-based format)
        const { error: cardsError } = await supabase.from("cards").upsert({
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
        if (cardsError) throw new Error(`cards upsert: ${cardsError.message}`);

        // 4. Graph stage: embedding + citation edges + category.
        // Failure-isolated inside runGraphStage; logged but never throws,
        // so a paper still completes even if OpenAI or Semantic Scholar fail.
        if (OPENAI_API_KEY) {
          try {
            const graph = await runGraphStage(supabase, OPENAI_API_KEY, {
              paper_id: deck.paper_id,
              title: deck.title,
              abstract: paper.abstract ?? paperRecord?.abstract ?? "",
              source: paperRecord?.source ?? "unknown",
              arxiv_category: paperRecord?.arxiv_category ?? undefined,
              coreIdeas: deck.concepts.map((c) => c.title),
            });
            if (graph.errors.length) {
              console.warn(`[process-queue] graph ${paper.paper_id}:`, graph.errors);
            }
          } catch (graphErr) {
            console.warn(`[process-queue] graph stage threw for ${paper.paper_id}:`, graphErr);
          }
        }

        // 5. Update paper status
        const { error: statusError } = await supabase
          .from("papers")
          .update({ status: "processed" })
          .eq("paper_id", paper.paper_id);
        if (statusError) throw new Error(`status update: ${statusError.message}`);

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
      const reasons = failed.map((f: any) => f.reason?.message ?? String(f.reason));
      console.error("[process-queue] Failed papers:", reasons);
      return json({ processed: succeeded, failed: failed.length, errors: reasons });
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
