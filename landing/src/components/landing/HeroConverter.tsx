import { useEffect, useRef, useState } from 'react'
import { convertPaper } from '../../lib/api'
import { SAMPLE_DECKS } from '../../lib/sampleDecks'
import type { AprecisDeck } from '../../lib/types'
import DeckRenderer from '../converter/DeckRenderer'

type Status = 'idle' | 'loading' | 'done' | 'error'

const STEPS = [
  'Fetching the paper from arXiv',
  'Reading the abstract',
  'Distilling the core ideas',
  'Choosing the right diagram per idea',
  "Mapping the paper's arc",
  'Assembling the Aprecis deck',
]

// Curated sample papers — clicking these renders a hand-authored deck
// instantly. They show the premium-diagram UX without waiting on the live
// pipeline (or being served a stale cached row that predates per-concept
// diagrams). For any paper outside this list, paste an arXiv URL into the
// input above to hit the live `add-paper` edge function.
const EXAMPLES: { label: string; id: string }[] = [
  { label: 'Attention Is All You Need', id: '1706.03762' },
  { label: 'GPT-3', id: '2005.14165' },
  { label: 'Diffusion (DDPM)', id: '2006.11239' },
]

/**
 * The landing-page front door. A paste-arxiv input lives inside the hero so
 * a first-time visitor can convert a paper without leaving the homepage.
 * On submit we swap the hero contents for a progress indicator, then for the
 * rendered deck (which lifts to the top of the page).
 */
export default function HeroConverter({
  onStatusChange,
}: {
  onStatusChange?: (s: Status) => void
}) {
  const [input, setInput] = useState('')
  const [status, setStatus] = useState<Status>('idle')
  const [step, setStep] = useState(0)
  const [error, setError] = useState('')
  const [deck, setDeck] = useState<AprecisDeck | null>(null)
  const deckRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    onStatusChange?.(status)
  }, [status, onStatusChange])

  async function run(value: string, opts?: { sample?: AprecisDeck }) {
    const v = value.trim()
    if (!v || status === 'loading') return

    // Sample-deck path: instant render, no network, no cache. Used by the
    // example chips so the premium-diagram UX is reachable from a cold open.
    if (opts?.sample) {
      setDeck(opts.sample)
      setStatus('done')
      window.requestAnimationFrame(() => {
        deckRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
      })
      return
    }

    setStatus('loading')
    setStep(0)
    setError('')
    setDeck(null)
    try {
      const result = await convertPaper(v)
      setDeck(result)
      setStatus('done')
      window.requestAnimationFrame(() => {
        deckRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
      })
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Something went wrong.')
      setStatus('error')
    }
  }

  useEffect(() => {
    if (status !== 'loading') return
    const t = window.setInterval(() => {
      setStep((s) => Math.min(s + 1, STEPS.length - 2))
    }, 8000)
    return () => clearInterval(t)
  }, [status])

  function reset() {
    setStatus('idle')
    setDeck(null)
    setInput('')
    setError('')
  }

  if (status === 'done' && deck) {
    return (
      <section className="hero" ref={deckRef}>
        <div className="wrap">
          <div className="hero_head">
            <div className="eyebrow">Your Aprecis deck</div>
            <h1 className="headline" style={{ marginBottom: 14 }}>
              <span className="hl_line">
                <span className="hl_inner">
                  The abstract, <span className="hl">re-read</span>.
                </span>
              </span>
            </h1>
          </div>
          <DeckRenderer data={deck} onReset={reset} />
        </div>
      </section>
    )
  }

  return (
    <section className="hero">
      <div className="wrap">
        <div className="hero_head">
          <div className="eyebrow">Paste an arXiv link · get a deck</div>
          <h1 className="headline">
            <span className="hl_line">
              <span className="hl_inner">Read the research,</span>
            </span>
            <span className="hl_line">
              <span className="hl_inner">
                the <span className="hl">AI-native</span> way.
              </span>
            </span>
          </h1>
          <p className="lede">
            Aprecis turns every fresh AI paper into <em>interactive diagrams</em>.
            Drop an arXiv link, watch the deck assemble.
          </p>

          {status === 'loading' ? (
            <div className="conv_loading" style={{ margin: '8px auto 0' }}>
              <div className="conv_spin" />
              <p
                style={{
                  fontFamily: "'EB Garamond', serif",
                  fontSize: 18,
                  color: 'var(--ink_soft)',
                }}
              >
                Reading the paper. A first conversion takes about a minute.
              </p>
              <div className="conv_steps">
                {STEPS.map((s, i) => (
                  <div
                    key={i}
                    className={
                      'conv_step ' +
                      (i < step ? 'done' : i === step ? 'active' : '')
                    }
                  >
                    <span className="cs_dot" />
                    {s}
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <>
              <form
                className="conv_form hero_conv_form"
                onSubmit={(e) => {
                  e.preventDefault()
                  run(input)
                }}
              >
                <input
                  className="conv_input"
                  type="text"
                  placeholder="arxiv.org/abs/2501.12948"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  autoFocus
                  spellCheck={false}
                  autoComplete="off"
                />
                <button
                  className="conv_submit"
                  type="submit"
                  disabled={!input.trim()}
                >
                  Convert <span aria-hidden="true">→</span>
                </button>
              </form>

              <div className="conv_examples">
                <span style={{ marginRight: 6 }}>Or open a curated sample:</span>
                {EXAMPLES.map((ex) => {
                  const sample = SAMPLE_DECKS[ex.id]
                  return (
                    <button
                      key={ex.id}
                      onClick={() => {
                        setInput(`https://arxiv.org/abs/${ex.id}`)
                        run(ex.id, sample ? { sample } : undefined)
                      }}
                    >
                      {ex.label}
                    </button>
                  )
                })}
              </div>

              {status === 'error' && <p className="conv_error">{error}</p>}
            </>
          )}
        </div>
      </div>
    </section>
  )
}
