/**
 * Local test: run the full pipeline on one paper and print output.
 * Usage: deno run --allow-net --allow-env scripts/test-pipeline.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
await load({ envPath: ".env.local", export: true, allowEmptyValues: true });

import { createOpenAIClient, processPaper } from "../src/pipeline.ts";

const SAMPLE_PAPER = {
  paper_id: "arxiv:2401.12345",
  title: "Chain-of-Thought Agents with Tool Use for Complex Reasoning",
  abstract:
    "We present a novel framework where language model agents iteratively decompose complex reasoning tasks using chain-of-thought prompting combined with external tool calls. Our approach achieves state-of-the-art performance on mathematical reasoning benchmarks while reducing token usage by 40% compared to baseline ReAct agents. The key insight is a dynamic planning step that routes subtasks to specialized tools based on complexity classification.",
  source: "arxiv",
  url: "https://arxiv.org/abs/2401.12345",
};

const apiKey = Deno.env.get("OPENAI_API_KEY");
if (!apiKey) {
  console.error("Set OPENAI_API_KEY env var");
  Deno.exit(1);
}

const ai = createOpenAIClient(apiKey);

console.log("🚀 Running pipeline on sample paper...\n");
const start = Date.now();

const { insight, deck } = await processPaper(ai, SAMPLE_PAPER);

const elapsed = ((Date.now() - start) / 1000).toFixed(1);
console.log(`✅ Pipeline completed in ${elapsed}s\n`);

console.log("─── INSIGHT ───────────────────────────────");
console.log(JSON.stringify(insight, null, 2));

console.log("\n─── CARDS ─────────────────────────────────");
for (const card of deck.cards) {
  console.log(`\n[${card.type.toUpperCase()}]`);
  if (card.text) console.log(card.text);
  if (card.description) console.log(`Visual: ${card.description}`);
  if (card.visual) console.log(JSON.stringify(card.visual, null, 2));
}
