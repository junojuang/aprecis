// ─── Diagram DSL (mirrors backend/src/types.ts) ─────────────────────────────

export type DiagramType =
  | 'flow'
  | 'bar_chart'
  | 'comparison'
  | 'attention_heatmap'
  | 'multi_head'
  | 'sine_waves'
  | 'cycle'
  | 'number_box'
  | 'equation'
  | 'custom'

export interface DiagramNode {
  id: string
  label: string
  sublabel?: string
  color?: string
}

export interface DiagramEdge {
  from: string
  to: string
  label?: string
}

export interface BarDatum {
  label: string
  value: number
  color?: string
  note?: string
}

export interface ComparisonItem {
  aspect: string
  before: string
  after: string
}

export interface HeadSpec {
  name: string
  color: string
  weights: number[]
  desc: string
}

export interface StepSpec {
  label: string
  sublabel?: string
}

export interface EquationTerm {
  symbol: string
  meaning: string
}

export interface DiagramSpec {
  type: DiagramType
  caption?: string

  // flow
  nodes?: DiagramNode[]
  edges?: DiagramEdge[]

  // bar_chart
  bars?: BarDatum[]
  yLabel?: string

  // comparison
  leftLabel?: string
  rightLabel?: string
  items?: ComparisonItem[]

  // attention_heatmap & multi_head
  tokens?: string[]
  weights?: number[][]
  heads?: HeadSpec[]

  // cycle
  steps?: StepSpec[]

  // number_box
  value?: string
  valueLabel?: string
  valueSublabel?: string

  // equation
  formula?: string
  terms?: EquationTerm[]
}

export interface Concept {
  title: string
  body: string
  diagramSpec?: DiagramSpec
}

export interface DeckResponse {
  paper_id: string
  title: string
  source: string
  url: string
  hook: string
  summary: string
  concepts: Concept[]
  published_at?: string | null
  score?: number
}

export interface TimelineNode {
  label: string
  sublabel?: string
  panelTitle: string
  panelBody: string
}

export interface BarPoint {
  label: string
  sublabel?: string
  primary: number
  secondary: number
  annotation: string
}

export interface BarSpec {
  kind: 'bar'
  yAxisLabel: string
  primaryLabel: string
  secondaryLabel: string
  defaultInsight: string
  yTickLabels?: [string, string, string]
  cliffIndex?: number
  cliffLabel?: string
  points: BarPoint[]
}

export interface VizCard {
  kicker: string
  title: { text: string }
  spec: { kind: string } & Partial<BarSpec>
  caption: string
  takeaway: string
}

export interface Blueprint {
  sourceLine?: string
  diagramTitle?: { text: string }
  diagramCollapseText?: string
  diagramDefaultPanelBody?: string
  timelineNodes?: TimelineNode[]
  vizCards?: VizCard[]
}

export interface AprecisDeck {
  deck: DeckResponse
  blueprint: Blueprint | null
}
