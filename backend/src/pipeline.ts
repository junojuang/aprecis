/**
 * Multi-stage LLM pipeline: paper text → structured insight → cards
 * Target: <10s per paper, minimal tokens
 */

import type { ProcessedInsight, CardDeck, Card, VisualSchema } from "./types.ts";

interface OpenAIClient {
  chat: (messages: ChatMessage[], opts?: ChatOptions) => Promise<string>;
}

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface ChatOptions {
  model?: string;
  max_tokens?: number;
  temperature?: number;
  response_format?: { type: "json_object" };
}

// ─── OpenAI Client ────────────────────────────────────────────────────────────

export function createOpenAIClient(apiKey: string): OpenAIClient {
  return {
    async chat(messages, opts = {}) {
      const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: opts.model ?? "gpt-4o-mini",
          messages,
          max_tokens: opts.max_tokens ?? 800,
          temperature: opts.temperature ?? 0.4,
          response_format: opts.response_format,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error?.message ?? "OpenAI error");
      return data.choices[0].message.content;
    },
  };
}

// ─── Stage 1: Headline Understanding ─────────────────────────────────────────

async function stageHeadline(
  ai: OpenAIClient,
  title: string,
  abstract: string
): Promise<Pick<ProcessedInsight, "headline" | "why_it_matters" | "core_ideas">> {
  const prompt = `You are extracting key ideas from an AI research paper for a general tech-savvy audience.

Title: ${title}
Abstract: ${abstract}

Return JSON with exactly:
{
  "headline": "<one sentence: what this paper does>",
  "why_it_matters": "<one sentence: why this matters>",
  "core_ideas": ["<bullet 1>", "<bullet 2>", "<bullet 3>"]
}

Rules: be specific, avoid jargon, max 15 words per bullet.`;

  const raw = await ai.chat(
    [{ role: "user", content: prompt }],
    { max_tokens: 300, response_format: { type: "json_object" } }
  );
  return JSON.parse(raw);
}

// ─── Stage 2: Simplification ──────────────────────────────────────────────────

async function stageSimplify(
  ai: OpenAIClient,
  headline: string,
  coreIdeas: string[]
): Promise<Pick<ProcessedInsight, "eli5" | "analogy">> {
  const prompt = `Transform this AI research insight into accessible content.

What it does: ${headline}
Core ideas: ${coreIdeas.join("; ")}

Return JSON with exactly:
{
  "eli5": "<explain like I'm 5, max 40 words, use everyday language>",
  "analogy": "<a vivid real-world analogy that captures the core mechanism, max 40 words>"
}`;

  const raw = await ai.chat(
    [{ role: "user", content: prompt }],
    { max_tokens: 250, response_format: { type: "json_object" } }
  );
  return JSON.parse(raw);
}

// ─── Stage 3: Visual Generation ───────────────────────────────────────────────

async function stageVisual(
  ai: OpenAIClient,
  headline: string,
  coreIdeas: string[]
): Promise<VisualSchema> {
  const prompt = `Generate a simple diagram schema for this AI concept.

Concept: ${headline}
Ideas: ${coreIdeas.join("; ")}

Return JSON in this EXACT format (choose type: "flow", "diagram", or "comparison"):
{
  "type": "flow",
  "description": "<one sentence describing the visual>",
  "nodes": [
    {"id": "a", "label": "<short label, max 4 words>"},
    {"id": "b", "label": "<short label>"},
    {"id": "c", "label": "<short label>"}
  ],
  "edges": [
    {"from": "a", "to": "b"},
    {"from": "b", "to": "c"}
  ]
}

Rules: max 5 nodes, max 6 edges, keep labels short.`;

  const raw = await ai.chat(
    [{ role: "user", content: prompt }],
    { max_tokens: 300, response_format: { type: "json_object" } }
  );
  return JSON.parse(raw);
}

// ─── Stage 4: Card Packaging ──────────────────────────────────────────────────

function packageCards(insight: ProcessedInsight): Card[] {
  return [
    {
      type: "hook",
      text: insight.headline,
    },
    {
      type: "core_idea",
      text: insight.core_ideas.map((idea, i) => `${i + 1}. ${idea}`).join("\n"),
    },
    {
      type: "eli5",
      text: insight.eli5,
    },
    {
      type: "analogy",
      text: insight.analogy,
    },
    {
      type: "visual",
      description: insight.visual.description,
      visual: insight.visual,
    },
    {
      type: "takeaway",
      text: insight.why_it_matters,
    },
  ];
}

// ─── Orchestrator ─────────────────────────────────────────────────────────────

export interface PaperInput {
  paper_id: string;
  title: string;
  abstract: string;
  source: string;
  url: string;
}

export async function processPaper(
  ai: OpenAIClient,
  paper: PaperInput
): Promise<{ insight: ProcessedInsight; deck: CardDeck }> {
  // Run stages 1 and (2+3) with stage 1 result feeding into stages 2 & 3
  const stage1 = await stageHeadline(ai, paper.title, paper.abstract);

  // Stages 2 and 3 run in parallel — both only need stage 1 output
  const [stage2, stage3] = await Promise.all([
    stageSimplify(ai, stage1.headline, stage1.core_ideas),
    stageVisual(ai, stage1.headline, stage1.core_ideas),
  ]);

  const insight: ProcessedInsight = {
    paper_id: paper.paper_id,
    ...stage1,
    ...stage2,
    visual: stage3,
  };

  const deck: CardDeck = {
    paper_id: paper.paper_id,
    title: paper.title,
    source: paper.source,
    url: paper.url,
    cards: packageCards(insight),
    created_at: new Date().toISOString(),
  };

  return { insight, deck };
}
