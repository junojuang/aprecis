/**
 * One-off destructive seed: wipes all paper rows from Supabase and inserts a
 * single curated demo paper ("Chain-of-Thought Prompting", Wei et al. 2022)
 * with hand-crafted hook, summary, and 4 concepts featuring native DiagramSpec
 * visualizations matching the editorial quality of the iOS daily loop content.
 *
 * Run: deno run --allow-net --allow-env --allow-read backend/scripts/seed-demo-paper.ts
 *
 * Reads SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY from backend/.env.local.
 *
 * Daily learning paper ("Attention Head Collapse") is hardcoded in iOS at
 * Models/DailyLoopContent.swift and is unaffected by this script.
 */

import "https://deno.land/std@0.224.0/dotenv/load.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

// ─── Curated demo paper ───────────────────────────────────────────────────────

const PAPER_ID = "arxiv:2201.11903";
const TITLE    = "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models";
const AUTHORS  = ["Jason Wei", "Xuezhi Wang", "Dale Schuurmans", "Maarten Bosma", "Brian Ichter", "Fei Xia", "Ed H. Chi", "Quoc V. Le", "Denny Zhou"];
const ABSTRACT = "We explore how generating a chain of thought, a series of intermediate reasoning steps, significantly improves the ability of large language models to perform complex reasoning. We show that on three large language models, chain-of-thought prompting improves performance on a range of arithmetic, commonsense, and symbolic reasoning tasks. The empirical gains can be striking. For instance, prompting a 540B-parameter language model with just eight chain-of-thought exemplars achieves state-of-the-art accuracy on the GSM8K benchmark of math word problems, surpassing even fine-tuned GPT-3 with a verifier.";
const URL      = "https://arxiv.org/abs/2201.11903";
const PUBLISHED_AT = "2022-01-28T00:00:00Z";

const HOOK    = "Adding 'let's think step by step' unlocks reasoning that scale alone cannot.";
const SUMMARY = "Large language models stumble on multi-step reasoning when asked for direct answers. Wei et al. show that prompting them with worked examples that include intermediate steps unlocks dramatic gains on math, commonsense, and symbolic tasks. The effect emerges only above ~62B parameters and requires no finetuning, just a different prompt.";

const CONCEPTS = [
  {
    title: "Reasoning Gap",
    body: "Standard few-shot prompting plateaus on multi-step problems even at hundreds of billions of parameters. The model has the latent capability but is forced to commit to an answer in a single forward pass. Without room to write intermediate work, multi-step arithmetic and symbolic chains collapse into confident wrong guesses.",
    diagramSpec: {
      type: "comparison",
      caption: "Direct answer vs. step-by-step on GSM8K math word problems (PaLM 540B).",
      leftLabel: "Direct answer",
      rightLabel: "Chain-of-thought",
      items: [
        { aspect: "GSM8K accuracy", before: "17.9%", after: "56.9%" },
        { aspect: "MultiArith accuracy", before: "44.0%", after: "94.7%" },
        { aspect: "Tokens of context used", before: "answer only", after: "intermediate steps" },
        { aspect: "Finetuning needed", before: "no", after: "no" },
      ],
    },
  },
  {
    title: "Chain-of-Thought Prompting",
    body: "The fix is a prompt-format change: each few-shot example shows not just the question and answer but the worked reasoning between them. At inference, the model imitates the format and writes its own intermediate steps before committing to a final answer. No weights change; only the demonstration shape does.",
    diagramSpec: {
      type: "flow",
      caption: "Standard prompt vs. chain-of-thought prompt for one few-shot example.",
      nodes: [
        { id: "q",   label: "Question",        sublabel: "Roger has 5 balls...",         color: "#1a8a8a" },
        { id: "cot", label: "Reasoning chain", sublabel: "Roger started with 5...",      color: "#e8a020" },
        { id: "a",   label: "Final answer",    sublabel: "11 tennis balls",              color: "#1a8a8a" },
      ],
      edges: [
        { from: "q",   to: "cot", label: "intermediate steps" },
        { from: "cot", to: "a",   label: "commit answer" },
      ],
    },
  },
  {
    title: "Emergent at Scale",
    body: "Chain-of-thought is not free. On smaller models it actively hurts, since the model lacks the capacity to follow its own reasoning faithfully. The benefit appears as a sharp emergence around 62B parameters and grows with scale. This makes CoT a property of the model size, not just the prompt.",
    diagramSpec: {
      type: "bar_chart",
      caption: "GSM8K accuracy across model sizes. CoT trails standard prompting until a sharp emergence above 62B parameters.",
      yLabel: "Accuracy (%)",
      bars: [
        { label: "8B",   value: 6.5,  color: "#888888", note: "below threshold" },
        { label: "62B",  value: 29.0, color: "#2db8b8" },
        { label: "175B", value: 46.9, color: "#1a8a8a" },
        { label: "540B", value: 56.9, color: "#e8a020", note: "★ SOTA" },
      ],
    },
  },
  {
    title: "Prompted, Not Trained",
    body: "No gradient updates, no specialised dataset, no verifier model. Eight worked exemplars in the prompt are enough to lift a 540B PaLM past a finetuned GPT-3 with a learned verifier on GSM8K. The result reframes capability as something already present in the weights and waiting on the right interface.",
    diagramSpec: {
      type: "number_box",
      caption: "Eight worked exemplars in a prompt match a finetuned and verified model.",
      value: "8",
      valueLabel: "few-shot exemplars",
      valueSublabel: "no finetuning, no verifier",
    },
  },
];

const CARDS_BLOB = {
  hook: HOOK,
  summary: SUMMARY,
  concepts: CONCEPTS,
};

// ─── Run ──────────────────────────────────────────────────────────────────────

console.log(`Target: ${SUPABASE_URL}`);
console.log("Wiping cards, processed_content, user_interactions, papers...");

// Order matters because of FK cascades, but explicit is safer.
for (const table of ["user_interactions", "cards", "processed_content", "papers"]) {
  const { error } = await supabase.from(table).delete().not("paper_id", "is", null).gte("paper_id", "");
  if (error && !/no.*matches.*filter/i.test(error.message)) {
    // user_interactions has bigserial id, not paper_id filter, fall back to non-null id.
    if (table === "user_interactions") {
      const { error: e2 } = await supabase.from("user_interactions").delete().gt("id", 0);
      if (e2) {
        console.error(`Failed to wipe ${table}:`, e2.message);
        Deno.exit(1);
      }
    } else {
      console.error(`Failed to wipe ${table}:`, error.message);
      Deno.exit(1);
    }
  }
  console.log(`  cleared ${table}`);
}

console.log("Inserting curated demo paper...");

const { error: paperErr } = await supabase.from("papers").insert({
  paper_id:        PAPER_ID,
  title:           TITLE,
  authors:         AUTHORS,
  abstract:        ABSTRACT,
  source:          "arxiv",
  url:             URL,
  pdf_url:         "https://arxiv.org/pdf/2201.11903",
  published_at:    PUBLISHED_AT,
  score:           0.92,
  score_breakdown: { recency: 0.4, social: 0.95, keyword: 1.0, author: 0.9 },
  status:          "processed",
});
if (paperErr) { console.error("papers insert:", paperErr.message); Deno.exit(1); }

const { error: pcErr } = await supabase.from("processed_content").insert({
  paper_id:       PAPER_ID,
  headline:       HOOK,
  why_it_matters: SUMMARY,
  core_ideas:     CONCEPTS.map((c) => c.title),
  eli5:           "Asking a big model 'what's the answer' makes it guess. Asking it 'show your steps' makes it think. Same brain, more space to work.",
  analogy:        "It is like asking someone to do long division in their head versus on paper. The arithmetic does not change; the room to work does.",
  visual:         {},
});
if (pcErr) { console.error("processed_content insert:", pcErr.message); Deno.exit(1); }

const { error: cardsErr } = await supabase.from("cards").insert({
  paper_id: PAPER_ID,
  title:    TITLE,
  source:   "arxiv",
  url:      URL,
  cards:    CARDS_BLOB,
});
if (cardsErr) { console.error("cards insert:", cardsErr.message); Deno.exit(1); }

// Confirm
const { count: paperCount } = await supabase.from("papers").select("*", { count: "exact", head: true });
const { count: cardsCount } = await supabase.from("cards").select("*", { count: "exact", head: true });
console.log(`Done. papers=${paperCount}, cards=${cardsCount}`);
