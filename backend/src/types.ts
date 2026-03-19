// ─── Ingestion Schemas ────────────────────────────────────────────────────────

export interface RawPaper {
  paper_id: string;
  title: string;
  authors: string[];
  abstract: string;
  source: "arxiv" | "twitter" | "github" | "rss";
  url: string;
  published_at: string; // ISO 8601
  pdf_url?: string;
  social_signals?: SocialSignals;
}

export interface SocialSignals {
  mentions?: number;
  stars?: number;
  forks?: number;
}

export interface ScoredPaper extends RawPaper {
  score: number;
  score_breakdown: {
    recency: number;
    social: number;
    keyword: number;
    author: number;
  };
}

// ─── Processing Schemas ───────────────────────────────────────────────────────

export interface ProcessedInsight {
  paper_id: string;
  headline: string;
  why_it_matters: string;
  core_ideas: string[];
  eli5: string;
  analogy: string;
  visual: VisualSchema;
}

export type VisualType = "flow" | "diagram" | "comparison";

export interface VisualSchema {
  type: VisualType;
  nodes: VisualNode[];
  edges: VisualEdge[];
  description: string;
}

export interface VisualNode {
  id: string;
  label: string;
}

export interface VisualEdge {
  from: string;
  to: string;
  label?: string;
}

// ─── Card Schemas ─────────────────────────────────────────────────────────────

export type CardType = "hook" | "core_idea" | "eli5" | "analogy" | "visual" | "takeaway";

export interface Card {
  type: CardType;
  text?: string;
  description?: string; // for visual cards
  visual?: VisualSchema; // for visual cards
}

export interface CardDeck {
  paper_id: string;
  title: string;
  source: string;
  url: string;
  cards: Card[];
  created_at: string;
}

// ─── Queue Schemas ────────────────────────────────────────────────────────────

export interface QueueMessage {
  paper_id: string;
  pdf_url?: string;
  abstract: string;
  title: string;
  enqueued_at: string;
}

// ─── API Response Schemas ─────────────────────────────────────────────────────

export interface FeedResponse {
  decks: CardDeck[];
  page: number;
  has_more: boolean;
}

export interface InteractionPayload {
  paper_id: string;
  action: "swiped_left" | "swiped_right" | "saved" | "shared";
  timestamp: string;
}
