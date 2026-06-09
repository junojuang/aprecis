// ─── Ingestion Schemas ────────────────────────────────────────────────────────

export interface RawPaper {
  paper_id: string;
  title: string;
  authors: string[];
  abstract: string;
  source: "arxiv" | "twitter" | "github" | "rss" | "hackernews";
  url: string;
  published_at: string; // ISO 8601
  pdf_url?: string;
  arxiv_category?: string; // primary arXiv category, e.g. "cs.CL" (arxiv source only)
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

// ─── Diagram DSL ──────────────────────────────────────────────────────────────

export type DiagramType =
  | "flow"              // sequential pipeline steps
  | "bar_chart"         // comparative metrics
  | "comparison"        // before/after or A-vs-B table
  | "attention_heatmap" // token × token attention weights
  | "multi_head"        // parallel attention heads
  | "sine_waves"        // positional encoding (no data needed)
  | "cycle"             // iterative loop with 3 to 6 numbered steps
  | "number_box"        // one headline statistic
  | "equation"          // formula with labelled terms
  | "custom";           // escape hatch, uses vizHtml

export interface HeadSpec {
  name: string;          // e.g. "Syntax"
  color: string;         // hex, e.g. "#1a8a8a"
  weights: number[];     // per-token attention weights, len = tokens.length
  desc: string;          // one line: what this head learns
}

export interface DiagramNode {
  id: string;
  label: string;
  sublabel?: string;
  color?: string;        // hex
}

export interface DiagramEdge {
  from: string;
  to: string;
  label?: string;
}

export interface BarSpec {
  label: string;
  value: number;         // 0 to 100 (percent) or normalised absolute
  color?: string;        // hex; defaults to teal
  note?: string;         // e.g. "state of the art ★"
}

export interface ComparisonItem {
  aspect: string;        // what is being compared, e.g. "Training time"
  before: string;        // old-approach value, e.g. "3 days"
  after: string;         // new-approach value, e.g. "3.5 hours"
}

export interface StepSpec {
  label: string;         // short step name, e.g. "Sample noise"
  sublabel?: string;     // optional detail, e.g. "Gaussian ε ~ N(0,1)"
}

export interface EquationTerm {
  symbol: string;        // e.g. "Q"
  meaning: string;       // e.g. "query matrix"
}

export interface DiagramSpec {
  type: DiagramType;
  caption?: string;      // label shown above the diagram

  // flow
  nodes?: DiagramNode[];
  edges?: DiagramEdge[];

  // bar_chart
  bars?: BarSpec[];
  yLabel?: string;

  // comparison
  leftLabel?: string;
  rightLabel?: string;
  items?: ComparisonItem[];

  // attention_heatmap & multi_head
  tokens?: string[];
  weights?: number[][];  // attention_heatmap only
  heads?: HeadSpec[];    // multi_head only

  // cycle
  steps?: StepSpec[];

  // number_box
  value?: string;        // e.g. "1000×", "97%", "3.2B"
  valueLabel?: string;   // headline label e.g. "fewer params"
  valueSublabel?: string; // optional context, e.g. "vs full fine-tune"

  // equation
  formula?: string;      // e.g. "Attention(Q,K,V) = softmax(QK^T/√d)V"
  terms?: EquationTerm[];

  // custom (escape hatch)
  vizHtml?: string;
}

// ─── Legacy Visual DSL (kept for backward compat with old cached papers) ──────

export type VisualType = "flow" | "diagram" | "comparison";
export interface VisualNode { id: string; label: string; }
export interface VisualEdge { from: string; to: string; label?: string; }
export interface VisualSchema { type: VisualType; nodes: VisualNode[]; edges: VisualEdge[]; }

// ─── Concept-Based Card Schema ────────────────────────────────────────────────

export interface Concept {
  title: string;
  body: string;
  diagramSpec?: DiagramSpec;  // structured native diagram (preferred)
  vizHtml?: string;           // custom HTML escape hatch or legacy
}

export interface CardDeck {
  paper_id: string;
  title: string;
  source: string;
  url: string;
  hook?: string;        // punchy 10-14 word hook headline
  summary: string;      // the Aprecis précis (ELI5, 40-60 words)
  concepts: Concept[];  // 4 explainer sections
  created_at: string;
  blueprint?: DailyLoopBlueprint;
}

// ─── Editorial Blueprint (drives DailyLoopView's 7-card flow) ────────────────
//
// All strings here are user-facing prose. Highlight phrases are matched against
// their parent string at render time; if not found, the phrase is appended as
// a non-highlight segment so render never breaks.

export interface HighlightedText {
  text: string;
  highlight?: string;   // verbatim substring of `text` to render in accent
  bold?: string;        // verbatim substring of `text` to render bold
}

export interface CoreFinding {
  title: string;        // 4-7 word verb-noun snap, e.g. "Boost is rented, not learned"
  detail: string;       // 35-55 words, no markdown
}

export interface TimelineNode {
  id?: string;          // stable identifier; auto-derived from index if absent
  label: string;        // short, e.g. "Day 1", "62B", "Step 2"
  sublabel?: string;    // qualifier, e.g. "baseline", "ChatGPT off"
  panelTitle: string;   // uppercased title for the explanation panel
  panelBody: string;    // 30-50 word panel description
}

export interface BarVizPoint {
  label: string;
  sublabel?: string;
  primary: number;      // 0..1, treatment / new method
  secondary: number;    // 0..1, control / old method
  annotation: string;   // narrative line shown when this bar is tapped
}

export interface BarVizSpec {
  kind: "bar";
  yAxisLabel: string;
  primaryLabel: string;
  secondaryLabel: string;
  yTickLabels: [string, string, string];  // exactly 3
  cliffIndex?: number;  // index of point where the narrative pivots
  cliffLabel?: string;
  defaultInsight: string;
  points: BarVizPoint[];   // 3-6 points
}

export interface ScatterVizSpec {
  kind: "scatter";
  beforeLabel: string;
  afterLabel: string;
  treatmentLabel: string;
  controlLabel: string;
  // Qualitative shape descriptors. iOS adapter materialises dot coordinates
  // deterministically (seeded RNG) from these so the LLM never has to hand-pick
  // numeric positions.
  treatmentBeforePattern: "spread" | "cluster_left" | "cluster_right";
  treatmentAfterPattern:  "spread" | "cluster_left" | "cluster_right" | "cluster_center";
  controlBeforePattern:   "spread" | "cluster_left" | "cluster_right";
  controlAfterPattern:    "spread" | "cluster_left" | "cluster_right";
  treatmentCount: number;  // typically 6-10
  controlCount: number;    // typically 4-8
  beforeCaption: string;
  afterCaption: string;
  xAxisLabel: string;
  yAxisLabel: string;
}

// ─── Training-curve viz ───────────────────────────────────────────────────────
//
// Premium hand-drawn line chart for "metric over time" stories, loss, accuracy,
// error rate, anything that climbs or falls across an axis of training progress.
// Multiple series share one set of axes; each series can mark its turning points
// as milestones, which become tap targets that reveal a narrative annotation.

export interface TrainingCurvePoint {
  x: number;             // domain value, raw (e.g. epoch number 1..10)
  y: number;             // 0..1 normalised against `yMax`
  milestone?: string;    // short label, rendered next to the dot ("peak", "off")
  annotation?: string;   // long-form panel body shown when this point is tapped
}

export interface TrainingCurveSeries {
  label: string;         // legend entry, e.g. "Linearly separable"
  color: "teal" | "amber" | "rose" | "ink";  // mapped to design tokens client-side
  points: TrainingCurvePoint[];   // 3-12 points; client splines between them
  dashed?: boolean;      // render as dashed stroke (e.g. control / counterfactual)
}

export interface TrainingCurveVizSpec {
  kind: "training_curve";
  xAxisLabel: string;    // e.g. "Epoch →"
  yAxisLabel: string;    // e.g. "Misclassifications"
  xTickLabels: string[]; // 3-6 tick labels evenly spaced along x
  yTickLabels: [string, string, string];  // exactly 3 (low, mid, high)
  series: TrainingCurveSeries[];          // 1-3 lines on shared axes
  defaultInsight: string;                  // shown before any milestone is tapped
}

// ─── Flow-rich viz ────────────────────────────────────────────────────────────
//
// Boxes-and-arrows diagram for "how data moves through this thing" stories
// forward passes, backward gradient flow, skip connections, encoder/decoder
// pipelines. Nodes lay out on a column/row grid so the client can render any
// architecture without hand-picked pixel coordinates. Edges optionally carry a
// kind (forward / backward / skip) which the client maps to distinct strokes.

export interface FlowRichNode {
  id: string;
  label: string;          // headline drawn inside the node ("Hidden", "Conv 3×3")
  sublabel?: string;      // small caption under label ("h = σ(W₁x)")
  role: "input" | "process" | "output" | "loss" | "skip";
  panelTitle: string;     // uppercased title shown when the node is tapped
  panelBody: string;      // long-form explanation
  column: number;         // grid column 0..n (left → right)
  row?: number;           // optional row, default 0 (used for skip branches)
}

export interface FlowRichEdge {
  from: string;           // node id
  to: string;             // node id
  label?: string;         // optional caption rendered along the arrow
  kind: "forward" | "backward" | "skip";
}

export interface FlowRichVizSpec {
  kind: "flow_rich";
  layout?: "horizontal" | "stacked";   // default "horizontal"
  nodes: FlowRichNode[];               // 3-6 nodes
  edges: FlowRichEdge[];               // 2-8 edges
  defaultInsight: string;              // shown before any node is tapped
}

// ─── Equation-rich viz ────────────────────────────────────────────────────────
//
// Hand-typeset equation where every meaningful term is tappable. Non-tappable
// terms (operators, fixed glyphs) carry no panel. Tap a term → its body and
// title swap into the panel below the equation.

export interface EquationRichTerm {
  id: string;
  display: string;        // glyph rendered inline ("w", "η", "∂L/∂w", "−", "·", "=")
  sup?: string;           // optional superscript ("new", "old", "T")
  sub?: string;           // optional subscript ("i", "1")
  color: "teal" | "amber" | "rose" | "ink" | "muted";  // muted = operators
  panelTitle?: string;    // omit on operators
  panelBody?: string;     // omit on operators
}

export interface EquationRichVizSpec {
  kind: "equation_rich";
  terms: EquationRichTerm[];
  defaultInsight: string;
  promptText?: string;    // override the small prompt above the equation
}

export type VizCardSpec = BarVizSpec | ScatterVizSpec | TrainingCurveVizSpec | FlowRichVizSpec | EquationRichVizSpec;

export interface VizCard {
  kicker: string;       // e.g. "CARD 05 · THE CLIFF"
  title: HighlightedText;
  spec: VizCardSpec;
  caption: string;
  takeaway: string;     // one declarative line
}

export interface DailyLoopBlueprint {
  heroEyebrow: string;          // e.g. "DAILY LOOP · NEW"
  heroTitle: HighlightedText;
  heroBody: string;
  sourceLine: string;

  hookTitle: HighlightedText;
  hookBody: string;

  coreIdeaTitle: HighlightedText;
  coreFindings: CoreFinding[];  // exactly 3

  eliAnalogyLabel: string;      // e.g. "ANALOGY · EXOSKELETON, NOT MUSCLE"
  eliHeadline: HighlightedText;
  eliBody: HighlightedText;     // bold spans permitted

  diagramTitle: HighlightedText;
  timelineNodes: TimelineNode[]; // 3-4 checkpoints
  diagramCollapseText: string;
  diagramDefaultPanelBody: string;

  vizCards: VizCard[];           // 1-2 cards

  completeQuote: string;
  completeTease: string;

  // ─── Curated extensions (optional; absent on LLM-only blueprints) ──────────
  paperTitle?: string;                              // full academic title shown under hero
  glossary?: Record<string, string>;                // term → 1 to 2 sentence definition
  eliArt?: "megaphone" | "scratchPaper";            // which illustration the analogy card draws
  diagramLayout?: "hub" | "flow";                   // hub = central node, flow = left-to-right chain
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
