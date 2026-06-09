import { useMemo, useState } from 'react'
import type { DiagramSpec } from '../../../lib/types'

/**
 * Stack of sine waves at doubling frequencies, with a frequency dial that
 * scales the base period in real time. Drag the dial right to compress
 * every wave; drag left and the lowest-frequency wave widens out into a
 * single hump. Matches the positional-encoding intuition the LLM picks
 * this diagram for.
 */
export default function SineWavesSpec({ spec }: { spec: DiagramSpec }) {
  const width = 340
  const height = 160
  const waves = 4
  const samples = 120
  const [k, setK] = useState(1)

  const paths = useMemo(() => {
    const out: string[] = []
    for (let w = 0; w < waves; w++) {
      const freq = Math.pow(2, w) * 1.1 * k
      const amp = height / (waves * 2.4)
      const yMid = ((w + 0.5) / waves) * height
      let d = ''
      for (let i = 0; i <= samples; i++) {
        const x = (i / samples) * width
        const y = yMid + Math.sin((i / samples) * Math.PI * 2 * freq) * amp
        d += i === 0 ? `M${x.toFixed(2)} ${y.toFixed(2)}` : ` L${x.toFixed(2)} ${y.toFixed(2)}`
      }
      out.push(d)
    }
    return out
  }, [k])

  return (
    <div className="ds_sine">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="ds_sine_svg"
        role="img"
        aria-label="Stack of sine waves at doubling frequencies"
      >
        {paths.map((d, i) => (
          <path
            key={i}
            d={d}
            fill="none"
            stroke="var(--teal)"
            strokeWidth="1.6"
            opacity={0.3 + (i / waves) * 0.6}
          />
        ))}
      </svg>
      <div className="ds_sine_dial">
        <span>slow</span>
        <input
          type="range"
          min={20}
          max={260}
          value={Math.round(k * 100)}
          onChange={(e) => setK(parseInt(e.currentTarget.value, 10) / 100)}
          aria-label="Scale the base frequency"
        />
        <span>fast</span>
      </div>
      <div className="ds_sine_legend">
        freq ×{(1 * k).toFixed(1)} · ×{(2 * k).toFixed(1)} · ×{(4 * k).toFixed(1)} · ×{(8 * k).toFixed(1)}
      </div>
    </div>
  )
}
