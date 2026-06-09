import { Fragment, useState } from 'react'
import type { TimelineNode } from '../../../lib/types'

/**
 * Interactive flow diagram. Nodes lay out left-to-right, connected by arrows
 * that light up to the selected step. Tapping a node reveals its panel.
 */
export default function FlowDiagram({
  nodes,
  hint,
}: {
  nodes: TimelineNode[]
  hint?: string
}) {
  const [active, setActive] = useState(0)

  return (
    <div className="fd">
      {hint && <p className="fd_hint">{hint}</p>}

      <div className="fd_track">
        {nodes.map((n, i) => (
          <Fragment key={i}>
            <div
              className={'fd_node' + (i === active ? ' active' : '')}
              style={{ animationDelay: `${0.08 + i * 0.09}s` }}
              onClick={() => setActive(i)}
              role="button"
              tabIndex={0}
              aria-pressed={i === active}
              onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && setActive(i)}
            >
              <div className="fd_step">STEP {i + 1}</div>
              <div className="fd_label">{n.label}</div>
              {n.sublabel && <div className="fd_sub">{n.sublabel}</div>}
            </div>

            {i < nodes.length - 1 && (
              <div className={'fd_arrow' + (i < active ? ' lit' : '')}>
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path
                    d="M3 8h9M9 4l4 4-4 4"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </div>
            )}
          </Fragment>
        ))}
      </div>

      <div className="fd_panel" key={active}>
        <div className="fd_panel_kicker">{nodes[active].panelTitle}</div>
        <p className="fd_panel_body">{nodes[active].panelBody}</p>
      </div>
    </div>
  )
}
