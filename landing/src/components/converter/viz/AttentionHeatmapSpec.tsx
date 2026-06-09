import { useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Two-panel attention viz: the standard token×token heat-grid, plus a live
 * "ribbon" view above it that draws an arc from the selected source token
 * to every target token with stroke width proportional to the weight. The
 * arc panel reads like the iOS attention illustrations — a glance at one
 * row of the matrix gets you the whole attention pattern.
 */
export default function AttentionHeatmapSpec({ spec }: { spec: DiagramSpec }) {
  const tokens = spec.tokens ?? []
  const weights = spec.weights ?? []
  const [activeRow, setActiveRow] = useState(0)

  if (tokens.length === 0 || weights.length === 0) return null

  // Lay tokens out evenly across an SVG strip.
  const stripW = 360
  const stripH = 140
  const n = tokens.length
  const padX = 24
  function tokX(i: number) {
    if (n === 1) return stripW / 2
    return padX + ((stripW - padX * 2) * i) / (n - 1)
  }
  const sourceY = stripH - 10
  const targetY = 10

  const row = weights[activeRow] ?? []

  return (
    <div className="ds_ah">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}

      <div className="ds_ah_strip" aria-hidden="true">
        <svg viewBox={`0 0 ${stripW} ${stripH}`} className="ds_ah_strip_svg">
          {row.map((w, j) => {
            const x0 = tokX(activeRow)
            const x1 = tokX(j)
            const cy = stripH / 2
            const d = `M ${x0} ${sourceY} C ${x0} ${cy}, ${x1} ${cy}, ${x1} ${targetY}`
            const sw = Math.max(0.6, w * 5.2)
            const op = Math.max(0.08, Math.min(0.95, w))
            return (
              <path
                key={j}
                d={d}
                fill="none"
                stroke="var(--teal)"
                strokeWidth={sw}
                strokeOpacity={op}
                strokeLinecap="round"
                className="ds_ah_arc"
              />
            )
          })}
          {tokens.map((t, j) => (
            <g key={`top-${j}`}>
              <circle
                cx={tokX(j)}
                cy={targetY}
                r="3.2"
                fill="var(--teal)"
                opacity={Math.max(0.25, row[j] ?? 0)}
              />
              <text
                x={tokX(j)}
                y={targetY - 10}
                textAnchor="middle"
                className="ds_ah_strip_tok target"
              >
                {t}
              </text>
            </g>
          ))}
          {tokens.map((t, j) => (
            <g key={`bot-${j}`}>
              <circle
                cx={tokX(j)}
                cy={sourceY}
                r={j === activeRow ? 5 : 3.2}
                fill={j === activeRow ? 'var(--amber)' : 'var(--ink)'}
                opacity={j === activeRow ? 1 : 0.35}
              />
              <text
                x={tokX(j)}
                y={sourceY + 16}
                textAnchor="middle"
                className={'ds_ah_strip_tok source' + (j === activeRow ? ' active' : '')}
              >
                {t}
              </text>
            </g>
          ))}
        </svg>
        <div className="ds_ah_strip_caption">
          "<span className="ds_ah_strip_token">{tokens[activeRow]}</span>" attends to →
        </div>
      </div>

      <div className="ds_ah_grid" role="grid">
        <div className="ds_ah_row ds_ah_head" role="row">
          <div className="ds_ah_cnr" />
          {tokens.map((t, j) => (
            <div
              key={j}
              className={
                'ds_ah_col_label' +
                (j === activeRow ? ' active' : '')
              }
            >
              {t}
            </div>
          ))}
        </div>

        {weights.map((rw, i) => (
          <div
            key={i}
            className={'ds_ah_row' + (activeRow === i ? ' active' : '')}
            role="row"
            onMouseEnter={() => setActiveRow(i)}
            onFocus={() => setActiveRow(i)}
            onClick={() => setActiveRow(i)}
            tabIndex={0}
          >
            <div className="ds_ah_row_label">{tokens[i] ?? ''}</div>
            {rw.map((w, j) => {
              const op = Math.max(0.05, Math.min(1, w))
              return (
                <div
                  key={j}
                  className="ds_ah_cell"
                  style={{ background: `rgba(26, 138, 138, ${op})` }}
                  title={`${tokens[i]} → ${tokens[j]} = ${w.toFixed(2)}`}
                >
                  <span className="ds_ah_cell_v">{w.toFixed(2)}</span>
                </div>
              )
            })}
          </div>
        ))}
      </div>

      <div className="ds_ah_legend">
        <span>low</span>
        <span className="ds_ah_legend_bar" />
        <span>high</span>
      </div>
    </div>
  )
}
