import { useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Scrubbable before/after table. A slider at the top morphs every row
 * between its `before` and `after` value: each cell crossfades and the
 * "old" value strikes through as the new one rises into view. At 0% only
 * the left column is real, at 100% only the right.
 */
export default function ComparisonSpec({ spec }: { spec: DiagramSpec }) {
  const items = spec.items ?? []
  const left = spec.leftLabel ?? 'Before'
  const right = spec.rightLabel ?? 'After'
  const [t, setT] = useState(1) // 0..1, default fully "after"

  return (
    <div className="ds_cmp">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}
      <p className="ds_cmp_hint">Drag the dial to scrub from {left.toLowerCase()} to {right.toLowerCase()}.</p>

      <div className="ds_cmp_scrub">
        <span className="ds_cmp_endcap left">{left}</span>
        <input
          className="ds_cmp_slider"
          type="range"
          min={0}
          max={100}
          value={Math.round(t * 100)}
          onChange={(e) => setT(parseInt(e.currentTarget.value, 10) / 100)}
          aria-label={`Scrub between ${left} and ${right}`}
        />
        <span className="ds_cmp_endcap right">{right}</span>
      </div>

      <div className="ds_cmp_rows">
        {items.map((it, i) => (
          <div
            className="ds_cmp_row"
            key={i}
            style={{ animationDelay: `${0.05 + i * 0.05}s` }}
          >
            <div className="ds_cmp_aspect">{it.aspect}</div>
            <div className="ds_cmp_cell">
              <span
                className="ds_cmp_before"
                style={{ opacity: 1 - t, transform: `translateY(${t * -6}px)` }}
              >
                {it.before}
              </span>
              <span
                className="ds_cmp_after"
                style={{ opacity: t, transform: `translateY(${(1 - t) * 6}px)` }}
              >
                {it.after}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
