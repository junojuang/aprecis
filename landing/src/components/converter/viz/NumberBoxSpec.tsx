import { useEffect, useRef, useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Headline-statistic card with a count-up animation. We try to parse a
 * leading number from the value string (handles "97%", "1000×", "3.2B",
 * "57 → 17", "$540M"); if there's nothing numeric we fall back to a
 * letter-stagger reveal. The IntersectionObserver fires the animation
 * exactly once when the card is visible.
 */

interface Parsed {
  prefix: string
  num: number
  decimals: number
  suffix: string
}

function parseValue(raw: string): Parsed | null {
  const m = raw.match(/^([^\d.\-]*)(-?[\d,]+(?:\.\d+)?)(.*)$/)
  if (!m) return null
  const numStr = m[2].replace(/,/g, '')
  const num = parseFloat(numStr)
  if (Number.isNaN(num)) return null
  const decimals = (numStr.split('.')[1] ?? '').length
  return { prefix: m[1], num, decimals, suffix: m[3] }
}

function format(parsed: Parsed, t: number): string {
  const v = parsed.num * t
  const body = parsed.decimals
    ? v.toFixed(parsed.decimals)
    : Math.round(v).toLocaleString('en-US')
  return `${parsed.prefix}${body}${parsed.suffix}`
}

export default function NumberBoxSpec({ spec }: { spec: DiagramSpec }) {
  const ref = useRef<HTMLDivElement>(null)
  const [t, setT] = useState(0)
  const parsed = spec.value ? parseValue(spec.value) : null

  useEffect(() => {
    if (!parsed) {
      setT(1)
      return
    }
    if (!ref.current) return
    let raf = 0
    let started = false
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting || started) continue
          started = true
          const start = performance.now()
          const dur = 1300
          const easeOut = (x: number) => 1 - Math.pow(1 - x, 3)
          const tick = (now: number) => {
            const k = Math.min(1, (now - start) / dur)
            setT(easeOut(k))
            if (k < 1) raf = requestAnimationFrame(tick)
          }
          raf = requestAnimationFrame(tick)
        }
      },
      { threshold: 0.3 },
    )
    io.observe(ref.current)
    return () => {
      io.disconnect()
      cancelAnimationFrame(raf)
    }
  }, [parsed])

  const display = parsed ? format(parsed, t) : (spec.value ?? '')

  return (
    <div className="ds_numbox" ref={ref}>
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}
      <div className="ds_numbox_card">
        <div className="ds_numbox_value">
          {parsed ? (
            display
          ) : (
            (spec.value ?? '').split('').map((ch, i) => (
              <span
                key={i}
                className="ds_numbox_glyph"
                style={{ animationDelay: `${i * 60}ms` }}
              >
                {ch}
              </span>
            ))
          )}
        </div>
        {spec.valueLabel && (
          <div className="ds_numbox_label">{spec.valueLabel}</div>
        )}
        {spec.valueSublabel && (
          <div className="ds_numbox_sub">{spec.valueSublabel}</div>
        )}
      </div>
    </div>
  )
}
