import type { DiagramSpec } from '../../../lib/types'
import FlowSpec from './FlowSpec'
import BarChartSpec from './BarChartSpec'
import ComparisonSpec from './ComparisonSpec'
import CycleSpec from './CycleSpec'
import NumberBoxSpec from './NumberBoxSpec'
import EquationSpec from './EquationSpec'
import AttentionHeatmapSpec from './AttentionHeatmapSpec'
import MultiHeadSpec from './MultiHeadSpec'
import SineWavesSpec from './SineWavesSpec'

/**
 * Dispatcher that turns a backend DiagramSpec into the matching React
 * renderer. Anything we can't render (custom, malformed, or empty) falls
 * through silently — the concept then renders as prose only.
 */
export default function DiagramSpecView({ spec }: { spec: DiagramSpec }) {
  switch (spec.type) {
    case 'flow':
      if (!spec.nodes || spec.nodes.length < 2) return null
      return <FlowSpec spec={spec} />
    case 'bar_chart':
      if (!spec.bars || spec.bars.length === 0) return null
      return <BarChartSpec spec={spec} />
    case 'comparison':
      if (!spec.items || spec.items.length === 0) return null
      return <ComparisonSpec spec={spec} />
    case 'cycle':
      if (!spec.steps || spec.steps.length < 2) return null
      return <CycleSpec spec={spec} />
    case 'number_box':
      if (!spec.value) return null
      return <NumberBoxSpec spec={spec} />
    case 'equation':
      if (!spec.formula) return null
      return <EquationSpec spec={spec} />
    case 'attention_heatmap':
      if (!spec.tokens || !spec.weights || spec.tokens.length === 0) return null
      return <AttentionHeatmapSpec spec={spec} />
    case 'multi_head':
      if (!spec.heads || !spec.tokens) return null
      return <MultiHeadSpec spec={spec} />
    case 'sine_waves':
      return <SineWavesSpec spec={spec} />
    default:
      return null
  }
}
