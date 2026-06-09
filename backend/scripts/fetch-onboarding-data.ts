/**
 * Fetches real arXiv papers across all onboarding categories, runs the LLM
 * pipeline on the top paper per category, and prints JSON.
 *
 * Uses existing ingestion / scoring / pipeline modules.
 * Extends fetchArxiv to also cover cs.CV and cs.RO for vision + robotics.
 *
 * Usage:
 *   cd backend
 *   deno run --allow-net --allow-env --allow-read scripts/fetch-onboarding-data.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
await load({ envPath: ".env.local", export: true, allowEmptyValues: true });

import { fetchArxiv } from "../src/ingestion.ts";
import { scorePaper } from "../src/scoring.ts";
import { createOpenAIClient, processPaper } from "../src/pipeline.ts";
import type { RawPaper } from "../src/types.ts";

const apiKey = Deno.env.get("OPENAI_API_KEY");
if (!apiKey) { console.error("Set OPENAI_API_KEY in .env.local"); Deno.exit(1); }
const ai = createOpenAIClient(apiKey);

// ─── Category definitions (mirrors OnboardingView.swift) ─────────────────────

const CATEGORIES = [
  {
    preferenceKey: "pref_llm",
    keywords: ["language model", "llm", "gpt", "transformer", "chain-of-thought", "in-context", "fine-tun", "rlhf", "reasoning", "token", "prompt", "pretraining", "claude", "gemini", "mistral", "llama"],
  },
  {
    preferenceKey: "pref_vision",
    keywords: ["image", "vision", "visual", "object detection", "segmentation", "depth estimation", "3d", "scene", "recognition", "pixel", "vit", "stable diffusion", "image generation", "video generation"],
  },
  {
    preferenceKey: "pref_safety",
    keywords: ["safety", "alignment", "constitutional", "harmless", "jailbreak", "red team", "bias", "fairness", "robustness", "adversarial", "interpretability", "explainab", "trust", "reward hacking"],
  },
  {
    preferenceKey: "pref_robotics",
    keywords: ["robot", "embodied", "manipulation", "locomotion", "grasping", "sim-to-real", "physical", "motor", "navigation", "drone", "humanoid"],
  },
  {
    preferenceKey: "pref_multimodal",
    keywords: ["multimodal", "audio", "speech", "video understanding", "vision-language", "vlm", "image-text", "cross-modal", "captioning", "visual question", "vqa", "clip"],
  },
  {
    preferenceKey: "pref_systems",
    keywords: ["training efficiency", "inference", "quantization", "pruning", "distillation", "gpu", "kernel", "throughput", "latency", "distributed training", "parallelism", "hardware", "accelerat"],
  },
  {
    preferenceKey: "pref_rl",
    keywords: ["reinforcement learning", " rl ", "reward", "policy gradient", "q-learning", "actor-critic", "exploration", "mdp", "ppo", "dqn", "grpo", "game playing"],
  },
] as const;

// ─── Fetch from arXiv (existing fn covers cs.AI/cs.LG/cs.CL; add cs.CV/cs.RO) ─

async function fetchExtraCategories(): Promise<RawPaper[]> {
  const cats = ["cs.CV", "cs.RO"];
  const search = cats.map((c) => `cat:${c}`).join("+OR+");
  const url = `https://export.arxiv.org/api/query?search_query=${search}&sortBy=submittedDate&sortOrder=descending&max_results=60`;
  const res = await fetch(url);
  const xml = await res.text();

  const papers: RawPaper[] = [];
  const entries = xml.match(/<entry>([\s\S]*?)<\/entry>/g) ?? [];
  for (const entry of entries) {
    const id = entry.match(/<id>([\s\S]*?)<\/id>/)?.[1]?.split("/abs/")[1]?.trim() ?? "";
    const title = entry.match(/<title>([\s\S]*?)<\/title>/)?.[1]?.replace(/\s+/g, " ").trim() ?? "";
    const abstract = entry.match(/<summary>([\s\S]*?)<\/summary>/)?.[1]?.replace(/\s+/g, " ").trim() ?? "";
    const published = entry.match(/<published>([\s\S]*?)<\/published>/)?.[1] ?? new Date().toISOString();
    const authors = [...entry.matchAll(/<name>(.*?)<\/name>/g)].map((m) => m[1]);
    if (!id || !title) continue;
    papers.push({ paper_id: `arxiv:${id}`, title, abstract, source: "arxiv", url: `https://arxiv.org/abs/${id}`, authors, published_at: published });
  }
  return papers;
}

console.error("Fetching arXiv papers…");
const [main, extra] = await Promise.all([fetchArxiv(100), fetchExtraCategories()]);
const rawPapers = [...main, ...extra];
console.error(`Fetched ${rawPapers.length} papers total`);

// ─── Score + categorise ───────────────────────────────────────────────────────

function classify(paper: RawPaper): string | null {
  const text = `${paper.title} ${paper.abstract}`.toLowerCase();
  let bestKey: string | null = null;
  let bestHits = 0;
  for (const cat of CATEGORIES) {
    const hits = cat.keywords.filter((kw) => text.includes(kw)).length;
    if (hits > bestHits) { bestHits = hits; bestKey = cat.preferenceKey; }
  }
  return bestHits >= 1 ? bestKey : null;
}
teh t
const scored = rawPapers.map(scorePaper).sort((a, b) => b.score - a.score);

const topPerCategory: Record<string, typeof scored[0]> = {};
for (const paper of scored) {
  const key = classify(paper);
  if (key && !topPerCategory[key]) topPerCategory[key] = paper;
}

console.error(`Matched categories: ${Object.keys(topPerCategory).join(", ")}`);

// ─── Run LLM pipeline on each top paper ──────────────────────────────────────

const results: Record<string, { title: string; hook: string; url: string }> = {};

for (const [prefKey, paper] of Object.entries(topPerCategory)) {
  console.error(`  [${prefKey}] ${paper.title.slice(0, 70)}…`);
  try {
    const { deck } = await processPaper(ai, paper);
    const hookCard = deck.cards.find((c) => c.type === "hook");
    results[prefKey] = { title: paper.title, hook: hookCard?.text ?? paper.title, url: paper.url };
  } catch (err) {
    console.error(`  ⚠ Pipeline error: ${err}`);
    results[prefKey] = { title: paper.title, hook: paper.abstract.slice(0, 140), url: paper.url };
  }
}

console.log(JSON.stringify(results, null, 2));
