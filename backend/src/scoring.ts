import type { RawPaper, ScoredPaper } from "./types.ts";

// ─── Keyword Lists ────────────────────────────────────────────────────────────

const HIGH_VALUE_KEYWORDS = [
  "large language model", "llm", "transformer", "agent", "reasoning",
  "multimodal", "chain-of-thought", "rag", "retrieval", "fine-tuning",
  "rlhf", "alignment", "diffusion", "vision language", "tool use",
  "benchmark", "emergent", "in-context learning", "prompt", "gpt",
  "claude", "gemini", "mistral", "llama", "foundation model",
];

const KNOWN_AUTHORS = new Set([
  "Ilya Sutskever", "Andrej Karpathy", "Yann LeCun", "Geoffrey Hinton",
  "Yoshua Bengio", "Demis Hassabis", "Sam Altman", "Dario Amodei",
  "Noam Shazeer", "Jakob Uszkoreit", "Ashish Vaswani",
]);

// ─── Individual Score Components ──────────────────────────────────────────────

/**
 * Exponential decay: score=1.0 at publish time, ~0.37 at 48h, ~0.14 at 96h
 */
function recencyScore(publishedAt: string): number {
  const hoursAgo = (Date.now() - new Date(publishedAt).getTime()) / 3_600_000;
  return Math.exp(-hoursAgo / 48);
}

/**
 * Log-normalized social signals (mentions + stars), capped at 1.0
 */
function socialScore(signals?: { mentions?: number; stars?: number; forks?: number }): number {
  if (!signals) return 0;
  const raw = (signals.mentions ?? 0) + (signals.stars ?? 0) + (signals.forks ?? 0) * 0.5;
  return Math.min(Math.log10(1 + raw) / 3, 1.0); // 1000 interactions → 1.0
}

/**
 * Keyword match ratio: 5+ matches → 1.0
 */
function keywordScore(text: string): number {
  const lower = text.toLowerCase();
  const hits = HIGH_VALUE_KEYWORDS.filter((kw) => lower.includes(kw)).length;
  return Math.min(hits / 5, 1.0);
}

/**
 * Known author heuristic
 */
function authorScore(authors: string[]): number {
  return authors.some((a) => KNOWN_AUTHORS.has(a)) ? 1.0 : 0.4;
}

// ─── Composite Scorer ─────────────────────────────────────────────────────────

const WEIGHTS = { recency: 0.4, social: 0.3, keyword: 0.2, author: 0.1 };
const MIN_SCORE = 0.25; // below this → filtered out

export function scorePaper(paper: RawPaper): ScoredPaper {
  const breakdown = {
    recency: recencyScore(paper.published_at),
    social: socialScore(paper.social_signals),
    keyword: keywordScore(`${paper.title} ${paper.abstract}`),
    author: authorScore(paper.authors),
  };

  const score =
    WEIGHTS.recency * breakdown.recency +
    WEIGHTS.social * breakdown.social +
    WEIGHTS.keyword * breakdown.keyword +
    WEIGHTS.author * breakdown.author;

  return { ...paper, score: Math.round(score * 1000) / 1000, score_breakdown: breakdown };
}

export function filterPapers(papers: RawPaper[]): ScoredPaper[] {
  return papers
    .map(scorePaper)
    .filter((p) => p.score >= MIN_SCORE)
    .sort((a, b) => b.score - a.score);
}
