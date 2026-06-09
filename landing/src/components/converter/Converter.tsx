import { useEffect, useState } from 'react'
import { convertPaper } from '../../lib/api'
import type { AprecisDeck } from '../../lib/types'
import DeckRenderer from './DeckRenderer'

type Status = 'idle' | 'loading' | 'done' | 'error'

const STEPS = [
  'Fetching the paper from arXiv',
  'Reading the abstract',
  'Distilling the core ideas',
  'Writing the plain-English explainers',
  "Mapping the paper's arc",
  'Assembling the Aprecis deck',
]

const EXAMPLES = [
  { label: 'Attention Is All You Need', id: '1706.03762' },
  { label: 'GPT-3', id: '2005.14165' },
  { label: 'DeepSeek-R1', id: '2501.12948' },
]

export default function Converter() {
  const [input, setInput] = useState('')
  const [status, setStatus] = useState<Status>('idle')
  const [step, setStep] = useState(0)
  const [error, setError] = useState('')
  const [deck, setDeck] = useState<AprecisDeck | null>(null)

  async function run(value: string) {
    const v = value.trim()
    if (!v || status === 'loading') return
    setStatus('loading')
    setStep(0)
    setError('')
    setDeck(null)
    try {
      const result = await convertPaper(v)
      setDeck(result)
      setStatus('done')
      window.scrollTo({ top: 0, behavior: 'smooth' })
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Something went wrong.')
      setStatus('error')
    }
  }

  // Cold pipeline runs take ~60s. Advance the step indicator so the wait
  // reads as progress; it caps one short of the end until the deck arrives.
  useEffect(() => {
    if (status !== 'loading') return
    const t = window.setInterval(() => {
      setStep((s) => Math.min(s + 1, STEPS.length - 2))
    }, 9000)
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
      <section className="conv">
        <div className="wrap">
          <div className="conv_head">
            <div className="eyebrow">Your Aprecis deck</div>
            <h1 className="conv_title">
              The abstract, <em>re-read</em>.
            </h1>
          </div>
          <DeckRenderer data={deck} onReset={reset} />
        </div>
      </section>
    )
  }

  return (
    <section className="conv">
      <div className="wrap">
        <div className="conv_head">
          <div className="eyebrow">The converter</div>
          <h1 className="conv_title">
            Paste a paper. <br />
            Get an <em>Aprecis</em>.
          </h1>
          <p className="conv_lede">
            Drop any arXiv link. Aprecis reads it and rebuilds it as a swipeable
            deck: a hook, a plain-English précis, the core ideas, the paper&apos;s
            arc.
          </p>
        </div>

        {status === 'loading' ? (
          <div className="conv_loading">
            <div className="conv_spin" />
            <p style={{ fontFamily: "'EB Garamond', serif", fontSize: 19, color: 'var(--ink_soft)' }}>
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
              className="conv_form"
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
              />
              <button className="conv_submit" type="submit" disabled={!input.trim()}>
                Convert →
              </button>
            </form>

            <div className="conv_examples">
              <span style={{ marginRight: 6 }}>Or try one:</span>
              {EXAMPLES.map((ex) => (
                <button
                  key={ex.id}
                  onClick={() => {
                    setInput(`https://arxiv.org/abs/${ex.id}`)
                    run(ex.id)
                  }}
                >
                  {ex.label}
                </button>
              ))}
            </div>

            {status === 'error' && <p className="conv_error">{error}</p>}
          </>
        )}
      </div>
    </section>
  )
}
