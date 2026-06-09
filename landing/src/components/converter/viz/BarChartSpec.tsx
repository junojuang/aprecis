import { useEffect, useRef, useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Premium narrative bar chart. Click a bar to dim the rest, lift the active
 * one, and pin its note into the panel below. Hit "Play the story" to walk
 * the bars left to right with a pause on each. Animated grow-in on mount.
 */
export default function BarChartSpec({ spec }: { spec: DiagramSpec }) {
  const bars = spec.bars ?? []
  const max = Math.max(1, ...bars.map((b) => b.value))
  const [active, setActive] = useState(-1)
  const [grown, setGrown] = useState(false)
  const [playing, setPlaying] = useState(false)
  const timer = useRef<number | null>(null)

  useEffect(() => {
    const id = requestAnimationFrame(() => setGrown(true))
    return () => cancelAnimationFrame(id)
  }, [])

  useEffect(() => {
    if (!playing) return
    if (active < 0) setActive(0)
    timer.current = window.setInterval(() => {
      setActive((i) => {
        if (i >= bars.length - 1) {
          setPlaying(false)
          return i
        }
        return i + 1
      })
    }, 1700)
    return () => {
      if (timer.current) clearInterval(timer.current)
    }
  }, [playing, bars.length, active])

  const hasNotes = bars.some((b) => b.note)
  const noteBar = active >= 0 ? bars[active] : null

  return (
    <div className="ds_bar">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}
      <div className="ds_bar_head">
        {spec.yLabel && <div className="ds_bar_ylabel">{spec.yLabel}</div>}
        {hasNotes && (
          <button
            type="button"
            className={'ds_play sm' + (playing ? ' playing' : '')}
            onClick={() => {
              if (active >= bars.length - 1) setActive(-1)
              setPlaying((p) => !p)
            }}
          >
            {playing ? '❚❚' : '▶'}
            <span>{playing ? 'Pause' : 'Play the story'}</span>
          </button>
        )}
      </div>

      <div className="ds_bar_track">
        {bars.map((b, i) => {
          const pct = (b.value / max) * 100
          return (
            <button
              key={i}
              type="button"
              className={
                'ds_bar_col' +
                (i === active ? ' active' : active >= 0 ? ' dim' : '')
              }
              onClick={() => {
                setPlaying(false)
                setActive(active === i ? -1 : i)
              }}
              aria-pressed={i === active}
            >
              <div className="ds_bar_value">
                {Number.isInteger(b.value) ? b.value : Math.round(b.value * 10) / 10}
              </div>
              <div
                className="ds_bar_fill"
                style={{
                  height: grown ? `${Math.max(4, pct)}%` : 0,
                  background: b.color
                    ? `linear-gradient(180deg, ${b.color}, ${b.color}cc)`
                    : undefined,
                  transitionDelay: `${i * 0.06}s`,
                }}
              />
              <div className="ds_bar_label">{b.label}</div>
              {b.note && (
                <div className="ds_bar_note_dot" aria-hidden="true" />
              )}
            </button>
          )
        })}
      </div>

      {noteBar?.note && (
        <div className="ds_bar_note" key={active}>
          <span className="ds_bar_note_kicker">{noteBar.label}</span>
          {noteBar.note}
        </div>
      )}
    </div>
  )
}
