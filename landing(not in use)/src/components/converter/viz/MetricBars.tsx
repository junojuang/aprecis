import { useEffect, useState } from 'react'
import type { BarSpec } from '../../../lib/types'

/**
 * Interactive grouped bar chart. Bars grow on mount; tapping a column dims the
 * rest, lifts the pair, and reveals that point's narrative annotation.
 */
export default function MetricBars({
  spec,
  takeaway,
}: {
  spec: BarSpec
  takeaway?: string
}) {
  const points = spec.points ?? []
  const cliff =
    typeof spec.cliffIndex === 'number' &&
    spec.cliffIndex >= 0 &&
    spec.cliffIndex < points.length
      ? spec.cliffIndex
      : -1

  const [active, setActive] = useState(cliff >= 0 ? cliff : 0)
  const [grown, setGrown] = useState(false)

  useEffect(() => {
    const id = requestAnimationFrame(() => setGrown(true))
    return () => cancelAnimationFrame(id)
  }, [])

  if (points.length === 0) return null
  const ticks = spec.yTickLabels ?? ['', '', '']
  const note = points[active]

  return (
    <div className="mb">
      <div className="mb_plot">
        <div className="mb_yaxis">
          <span>{ticks[2]}</span>
          <span>{ticks[1]}</span>
          <span>{ticks[0]}</span>
        </div>

        <div className="mb_grid">
          <div className="mb_gridline" style={{ top: '0%' }} />
          <div className="mb_gridline" style={{ top: '50%' }} />
          <div className="mb_gridline" style={{ bottom: '26px' }} />

          <div className="mb_bars">
            {points.map((p, i) => (
              <div
                key={i}
                className={
                  'mb_col' +
                  (i === active ? ' active' : active >= 0 ? ' dim' : '')
                }
                onClick={() => setActive(i)}
                role="button"
                tabIndex={0}
                aria-pressed={i === active}
                onKeyDown={(e) =>
                  (e.key === 'Enter' || e.key === ' ') && setActive(i)
                }
              >
                <div className="mb_pair">
                  <div
                    className="mb_bar secondary"
                    style={{
                      height: grown ? `${Math.max(2, p.secondary * 100)}%` : 0,
                      transitionDelay: `${i * 0.06}s`,
                    }}
                  />
                  <div
                    className="mb_bar primary"
                    style={{
                      height: grown ? `${Math.max(2, p.primary * 100)}%` : 0,
                      transitionDelay: `${i * 0.06 + 0.05}s`,
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          <div className="mb_xlabels">
            {points.map((p, i) => (
              <div
                key={i}
                className={'mb_xl' + (i === active ? ' active' : '')}
                onClick={() => setActive(i)}
              >
                <div className="mb_xl_label">{p.label}</div>
                {p.sublabel && <div className="mb_xl_sub">{p.sublabel}</div>}
                {i === cliff && spec.cliffLabel && (
                  <div className="mb_cliff">▲ {spec.cliffLabel}</div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="mb_legend">
        <span className="lg">
          <span className="sw" style={{ background: 'var(--teal)' }} />
          {spec.primaryLabel}
        </span>
        <span className="lg">
          <span className="sw" style={{ background: 'var(--paper_3)' }} />
          {spec.secondaryLabel}
        </span>
      </div>

      <div className="mb_note" key={active}>
        <span className="mb_note_x">{note.label}</span>
        {note.annotation}
      </div>

      {takeaway && <div className="dcard_takeaway">{takeaway}</div>}
    </div>
  )
}
