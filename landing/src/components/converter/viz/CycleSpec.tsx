import { useEffect, useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Auto-orbiting cycle. The active dot pulses, every 2.6s the loop advances,
 * and a teal arc traces from the previous step to the next so the eye
 * follows the iteration. Tap any dot to pause and pin it.
 */
export default function CycleSpec({ spec }: { spec: DiagramSpec }) {
  const steps = spec.steps ?? []
  const [active, setActive] = useState(0)
  const [playing, setPlaying] = useState(true)
  const n = steps.length
  const radius = 100

  useEffect(() => {
    if (!playing || n < 2) return
    const id = window.setInterval(() => setActive((i) => (i + 1) % n), 2600)
    return () => clearInterval(id)
  }, [playing, n])

  function angle(i: number) {
    return (i / n) * Math.PI * 2 - Math.PI / 2
  }

  // SVG arc from previous → active dot, on the orbit circle.
  const prev = (active + n - 1) % n
  const a0 = angle(prev)
  const a1 = angle(active)
  const arcStart = { x: Math.cos(a0) * radius, y: Math.sin(a0) * radius }
  const arcEnd = { x: Math.cos(a1) * radius, y: Math.sin(a1) * radius }

  return (
    <div className="ds_cycle">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}

      <div className="ds_cycle_controls">
        <button
          type="button"
          className={'ds_play sm' + (playing ? ' playing' : '')}
          onClick={() => setPlaying((p) => !p)}
        >
          {playing ? '❚❚' : '▶'}
          <span>{playing ? 'Pause the loop' : 'Resume'}</span>
        </button>
      </div>

      <div className="ds_cycle_stage">
        <svg
          className="ds_cycle_svg"
          viewBox="-130 -130 260 260"
          aria-hidden="true"
        >
          <circle
            cx="0"
            cy="0"
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth="1.4"
            strokeDasharray="3 5"
            className="ds_cycle_ring"
          />
          <path
            key={active}
            d={`M ${arcStart.x.toFixed(2)} ${arcStart.y.toFixed(2)} A ${radius} ${radius} 0 0 1 ${arcEnd.x.toFixed(2)} ${arcEnd.y.toFixed(2)}`}
            fill="none"
            stroke="var(--teal)"
            strokeWidth="2.4"
            strokeLinecap="round"
            className="ds_cycle_trace"
          />
        </svg>

        <div className="ds_cycle_centre" key={active}>
          <div className="ds_cycle_step_kicker">
            STEP {active + 1} / {n}
          </div>
          <div className="ds_cycle_step_label">{steps[active]?.label}</div>
          {steps[active]?.sublabel && (
            <div className="ds_cycle_step_sub">{steps[active]?.sublabel}</div>
          )}
        </div>

        {steps.map((s, i) => {
          const theta = angle(i)
          const x = Math.cos(theta) * radius
          const y = Math.sin(theta) * radius
          return (
            <button
              key={i}
              type="button"
              className={'ds_cycle_dot' + (i === active ? ' active' : '')}
              style={{
                left: `calc(50% + ${x}px)`,
                top: `calc(50% + ${y}px)`,
              }}
              onClick={() => {
                setPlaying(false)
                setActive(i)
              }}
              aria-label={`Step ${i + 1}: ${s.label}`}
              aria-pressed={i === active}
            >
              {i + 1}
            </button>
          )
        })}
      </div>
    </div>
  )
}
