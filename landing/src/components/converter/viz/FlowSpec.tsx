import { Fragment, useEffect, useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Sequential pipeline diagram with playback. The reader can either click a
 * step to jump to it or hit play and watch the chain animate left to right
 * with a particle threading the arrows. Each step's sublabel and detail
 * lift into the panel below as the active index advances.
 */
export default function FlowSpec({ spec }: { spec: DiagramSpec }) {
  const nodes = spec.nodes ?? []
  const edges = spec.edges ?? []
  const [active, setActive] = useState(0)
  const [playing, setPlaying] = useState(false)

  useEffect(() => {
    if (!playing) return
    const id = window.setInterval(() => {
      setActive((i) => {
        const next = i + 1
        if (next >= nodes.length) {
          setPlaying(false)
          return i
        }
        return next
      })
    }, 1500)
    return () => clearInterval(id)
  }, [playing, nodes.length])

  function edgeLabel(fromIdx: number): string | undefined {
    const from = nodes[fromIdx]?.id
    const to = nodes[fromIdx + 1]?.id
    if (!from || !to) return undefined
    return edges.find((e) => e.from === from && e.to === to)?.label
  }

  const activeNode = nodes[active]

  return (
    <div className="ds_flow">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}

      <div className="ds_flow_controls">
        <button
          type="button"
          className={'ds_play' + (playing ? ' playing' : '')}
          onClick={() => {
            if (active >= nodes.length - 1) setActive(0)
            setPlaying((p) => !p)
          }}
          aria-label={playing ? 'Pause playback' : 'Play step-through'}
        >
          {playing ? '❚❚' : '▶'}
          <span>{playing ? 'Pause' : 'Play step-through'}</span>
        </button>
        <div className="ds_flow_progress" aria-hidden="true">
          {nodes.map((_, i) => (
            <span
              key={i}
              className={'ds_flow_pip' + (i <= active ? ' on' : '')}
              onClick={() => {
                setPlaying(false)
                setActive(i)
              }}
            />
          ))}
        </div>
        <span className="ds_flow_count">
          {active + 1} / {nodes.length}
        </span>
      </div>

      <div className="ds_flow_track">
        {nodes.map((n, i) => (
          <Fragment key={n.id ?? i}>
            <button
              type="button"
              className={'ds_flow_node' + (i === active ? ' active' : i < active ? ' done' : '')}
              style={{
                animationDelay: `${0.06 + i * 0.07}s`,
              }}
              onClick={() => {
                setPlaying(false)
                setActive(i)
              }}
              aria-pressed={i === active}
            >
              <div className="ds_flow_step">STEP {i + 1}</div>
              <div className="ds_flow_label">{n.label}</div>
              {n.sublabel && <div className="ds_flow_sub">{n.sublabel}</div>}
            </button>
            {i < nodes.length - 1 && (
              <div
                className={'ds_flow_arrow' + (i < active ? ' lit' : '')}
                aria-hidden="true"
              >
                <span className="ds_flow_arrow_line" />
                <span className={'ds_flow_arrow_particle' + (playing && i === active ? ' flying' : '')} />
                <svg
                  width="14"
                  height="14"
                  viewBox="0 0 14 14"
                  fill="none"
                  className="ds_flow_arrow_head"
                >
                  <path
                    d="M3 7h7M7 3l4 4-4 4"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
                {edgeLabel(i) && (
                  <span className="ds_flow_edge_label">{edgeLabel(i)}</span>
                )}
              </div>
            )}
          </Fragment>
        ))}
      </div>

      {activeNode && (
        <div className="ds_flow_panel" key={active}>
          <div className="ds_flow_panel_kicker">
            STEP {active + 1} · {activeNode.label}
          </div>
          {activeNode.sublabel ? (
            <p className="ds_flow_panel_body">{activeNode.sublabel}</p>
          ) : (
            <p className="ds_flow_panel_idle">
              The pipeline lands here next. Tap another step to skip ahead.
            </p>
          )}
        </div>
      )}
    </div>
  )
}
