/**
 * Diagnostic: run the full pipeline locally with the Anthropic client and
 * surface every chatJson / stage failure on stderr.
 * Usage: deno run --allow-net --allow-env --allow-read scripts/diag-blueprint.ts
 */
import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
await load({ envPath: ".env.local", export: true, allowEmptyValues: true });

import { createAnthropicClient, processPaper } from "../src/pipeline.ts";

const key = Deno.env.get("ANTHROPIC_API_KEY");
if (!key) { console.error("no ANTHROPIC_API_KEY"); Deno.exit(1); }

const ai = createAnthropicClient(key);
const start = Date.now();
const deck = await processPaper(ai, {
  paper_id: "arxiv:1706.03762",
  title: "Attention Is All You Need",
  abstract:
    "The dominant sequence transduction models are based on complex recurrent or convolutional neural networks. We propose the Transformer, based solely on attention mechanisms. Experiments on two machine translation tasks show these models to be superior in quality while being more parallelizable and requiring significantly less time to train.",
  source: "arxiv",
  url: "https://arxiv.org/abs/1706.03762",
});
console.log(`done in ${((Date.now() - start) / 1000).toFixed(1)}s`);
const bp = deck.blueprint!;
console.log("heroTitle:", JSON.stringify(bp.heroTitle));
console.log("eliHeadline:", JSON.stringify(bp.eliHeadline));
console.log("coreFindings[0].title:", bp.coreFindings[0]?.title);
console.log("vizCards[0].spec.points:", JSON.stringify(bp.vizCards[0]?.spec));
