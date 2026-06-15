import { useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Parallel attention heads. Default is a tabbed single-head view where each
 * token gets a horizontal weight bar. Flick on Compare and a second head's
 * bars are overlaid in a contrasting colour above each row — you can see
 * how different heads disagree per token.
 */
export default function MultiHeadSpec({ spec }: { spec: DiagramSpec }) {
  const heads = spec.heads ?? []
  const tokens = spec.tokens ?? []
  const [active, setActive] = useState(0)
  const [compare, setCompare] = useState<number | null>(null)
  const [compareMode, setCompareMode] = useState(false)

  if (heads.length === 0 || tokens.length === 0) return null
  const head = heads[active]
  const compareHead = compareMode && compare !== null ? heads[compare] : null

  function toggleCompare() {
    if (compareMode) {
      setCompareMode(false)
      setCompare(null)
      return
    }
    if (heads.length < 2) return
    const next = (active + 1) % heads.length
    setCompare(next)
    setCompareMode(true)
  }

  return (
    <div className="ds_mh">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}

      <div className="ds_mh_head">
        <div className="ds_mh_tabs" role="tablist">
          {heads.map((h, i) => (
            <button
              type="button"
              key={i}
              role="tab"
              aria-selected={i === active}
              className={'ds_mh_tab' + (i === active ? ' active' : '')}
              onClick={() => setActive(i)}
              style={
                i === active
                  ? { background: h.color, borderColor: h.color, color: '#fff' }
                  : { borderColor: h.color, color: h.color }
              }
            >
              {h.name}
            </button>
          ))}
        </div>
        {heads.length > 1 && (
          <button
            type="button"
            className={'ds_mh_compare' + (compareMode ? ' active' : '')}
            onClick={toggleCompare}
          >
            {compareMode ? '× Stop comparing' : 'Compare another head'}
          </button>
        )}
      </div>

      <div className="ds_mh_panel">
        <div className="ds_mh_desc">
          <span style={{ color: head.color, fontWeight: 700 }}>{head.name}</span>
          {' · '}
          {head.desc}
          {compareHead && (
            <>
              {'  vs.  '}
              <span style={{ color: compareHead.color, fontWeight: 700 }}>
                {compareHead.name}
              </span>
              {' · '}
              {compareHead.desc}
            </>
          )}
        </div>

        <div className="ds_mh_bars">
          {tokens.map((t, j) => {
            const w = head.weights[j] ?? 0
            const pct = Math.max(2, Math.min(100, w * 100))
            const w2 = compareHead?.weights[j] ?? 0
            const pct2 = Math.max(2, Math.min(100, w2 * 100))
            return (
              <div className="ds_mh_row" key={j}>
                <div className="ds_mh_token">{t}</div>
                <div className="ds_mh_track">
                  <div
                    className="ds_mh_fill"
                    style={{
                      width: `${pct}%`,
                      background: head.color,
                      transitionDelay: `${j * 0.04}s`,
                    }}
                  />
                  {compareHead && (
                    <div
                      className="ds_mh_fill compare"
                      style={{
                        width: `${pct2}%`,
                        background: compareHead.color,
                        transitionDelay: `${j * 0.04 + 0.1}s`,
                      }}
                    />
                  )}
                </div>
                <div className="ds_mh_value">
                  {w.toFixed(2)}
                  {compareHead && (
                    <span style={{ color: compareHead.color, marginLeft: 6 }}>
                      {w2.toFixed(2)}
                    </span>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
