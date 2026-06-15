import type { AprecisDeck, BarSpec, VizCard } from '../../lib/types'
import FlowDiagram from './viz/FlowDiagram'
import MetricBars from './viz/MetricBars'
import DiagramSpecView from './viz/DiagramSpecView'

/** A bar viz card is real only if the pipeline filled it; otherwise it is the
 *  deterministic fallback (generic A/B/C/D bars) and we skip it. */
function isRealBar(card: VizCard): boolean {
  if (card.spec.kind !== 'bar') return false
  const s = card.spec as BarSpec
  if (s.primaryLabel === 'New' && s.secondaryLabel === 'Baseline') return false
  const pts = s.points ?? []
  if (pts.length === 0) return false
  if (pts.every((p) => p.label.length <= 2)) return false
  return true
}

export default function DeckRenderer({
  data,
  onReset,
}: {
  data: AprecisDeck
  onReset: () => void
}) {
  const { deck, blueprint } = data

  const timeline = blueprint?.timelineNodes ?? []
  const barCard = (blueprint?.vizCards ?? []).find(isRealBar)
  let cardNo = 0
  const card = () => String(++cardNo).padStart(2, '0')

  return (
    <div className="deck">
      <div className="deck_meta">
        <span className="src">
          {deck.source === 'arxiv' ? 'arXiv' : deck.source}
          {' · '}
          <a href={deck.url} target="_blank" rel="noopener noreferrer">
            open the paper →
          </a>
        </span>
        <p className="deck_paper_title">{deck.title}</p>
      </div>

      {/* HOOK */}
      <div className="dcard teal">
        <div className="dcard_kicker">Card {card()} · The hook</div>
        <p className="dcard_hook">{deck.hook}</p>
      </div>

      {/* PRÉCIS */}
      <div className="dcard">
        <div className="dcard_kicker">Card {card()} · The précis</div>
        <p className="dcard_body">{deck.summary}</p>
      </div>

      {/* CONCEPTS — one card per concept, each with its own interactive diagram.
          Layout mirrors the iOS lesson cadence: kicker → italic title → prose →
          interactive. The role label ("Mechanism", "Result", etc.) makes the
          four-card progression read as a path, not a list. */}
      {deck.concepts.map((c, i) => {
        const role =
          ['Problem', 'Mechanism', 'Training', 'Result'][i] ?? 'Idea'
        return (
          <div className="dcard dcard_concept" key={i}>
            <div className="dcard_kicker">
              Card {card()} · Idea {String(i + 1).padStart(2, '0')} · {role}
            </div>
            <h4 className="concept_h">{c.title}</h4>
            <p className="concept_lead">{c.body}</p>
            {c.diagramSpec && (
              <div className="concept_diagram">
                <div className="concept_diagram_rule" aria-hidden="true">
                  <span>Interactive</span>
                </div>
                <DiagramSpecView spec={c.diagramSpec} />
              </div>
            )}
          </div>
        )
      })}

      {/* FLOW DIAGRAM — the paper's arc, interactive */}
      {timeline.length >= 3 && (
        <div className="dcard">
          <div className="dcard_kicker">
            Card {card()} · {blueprint?.diagramTitle?.text ?? "The paper's arc"}
          </div>
          <FlowDiagram
            nodes={timeline}
            hint={
              blueprint?.diagramDefaultPanelBody ?? 'Tap a step to follow the arc.'
            }
          />
        </div>
      )}

      {/* METRIC BARS — comparative results, interactive */}
      {barCard && (
        <div className="dcard">
          <div className="dcard_kicker">{barCard.kicker}</div>
          <p className="dcard_hook" style={{ fontSize: 25, marginBottom: 4 }}>
            {barCard.title.text}
          </p>
          <p className="dcard_caption" style={{ marginBottom: 4 }}>
            {(barCard.spec as BarSpec).yAxisLabel}
          </p>
          <MetricBars spec={barCard.spec as BarSpec} takeaway={barCard.takeaway} />
        </div>
      )}

      <div className="deck_actions">
        <button className="btn btn_primary" onClick={onReset}>
          Convert another <span className="arrow">→</span>
        </button>
        <a
          href={deck.url}
          target="_blank"
          rel="noopener noreferrer"
          className="btn btn_ghost"
        >
          Read the original
        </a>
      </div>
    </div>
  )
}
