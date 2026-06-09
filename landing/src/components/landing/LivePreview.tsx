import { useEffect, useState } from 'react'

type Shot = 'zero' | 'one' | 'few'

interface PromptLine {
  p: string
  v: string
  q: boolean
}
interface Scene {
  lines: PromptLine[]
  answer: string
  accuracy: number
  caption: string
  verdict: string
  ok: boolean
}

const SCENES: Record<Shot, Scene> = {
  zero: {
    lines: [{ p: 'cat →', v: '?', q: true }],
    answer: 'le chat',
    accuracy: 50,
    caption: 'Just the instruction. No demos.',
    verdict: "Half right. Got the language. Added an article it shouldn't have.",
    ok: false,
  },
  one: {
    lines: [
      { p: 'sea →', v: 'mer', q: false },
      { p: 'cat →', v: '?', q: true },
    ],
    answer: 'chat',
    accuracy: 62,
    caption: 'One worked demo before the test.',
    verdict: 'One demo locked the format. Single-word answer this time.',
    ok: true,
  },
  few: {
    lines: [
      { p: 'sea →', v: 'mer', q: false },
      { p: 'house →', v: 'maison', q: false },
      { p: 'song →', v: 'chanson', q: false },
      { p: 'cat →', v: '?', q: true },
    ],
    answer: 'chat',
    accuracy: 78,
    caption: 'A handful of demos. The pattern locks in.',
    verdict: 'Pattern locked. The model uses the demos like a tiny program.',
    ok: true,
  },
}

const SHOTS: { key: Shot; label: string }[] = [
  { key: 'zero', label: '0 shot' },
  { key: 'one', label: '1 shot' },
  { key: 'few', label: 'Few shot' },
]

export default function LivePreview() {
  const [shot, setShot] = useState<Shot>('zero')
  const [typed, setTyped] = useState('')
  const scene = SCENES[shot]

  useEffect(() => {
    setTyped('')
    const target = SCENES[shot].answer
    let i = 0
    let timer: number
    const tick = () => {
      i++
      setTyped(target.slice(0, i))
      if (i < target.length) timer = window.setTimeout(tick, 60)
    }
    const start = window.setTimeout(tick, 380)
    return () => {
      clearTimeout(start)
      clearTimeout(timer)
    }
  }, [shot])

  const typing = typed.length < scene.answer.length

  return (
    <section className="section gloss_demo" id="preview">
      <div className="wrap">
        <div className="gd_grid">
          <div className="gd_intro">
            <div className="section_label">In-context learning</div>
            <h2 className="section_title">
              Read a <em>real</em> card.
            </h2>
            <p className="section_sub">
              Toggle the prompt mode and watch the answer, accuracy, and verdict
              shift in real time.
            </p>
            <p className="gd_hint">
              Language Models are Few-Shot Learners · Brown et al., 2020
            </p>
          </div>

          <div className="gd_phone_col">
            <div className="gd_phone" aria-label="GPT-3 few-shot interactive prototype">
              <div className="gd_screen">
                <div className="gd_status" />
                <div className="gd_proto">
                  <div className="pt_eyebrow">CARD 04 · IN-CONTEXT LEARNING</div>
                  <h3 className="pt_title">
                    Same model. <em>Different prompts.</em>
                  </h3>
                  <p className="pt_sub">
                    GPT-3&apos;s weights never change here. Toggle the demos and
                    watch the answer get sharper.
                  </p>

                  <div className="pt_panel">
                    <div className="pt_panel_head">
                      <span className="pt_dot r" />
                      <span className="pt_dot y" />
                      <span className="pt_dot g" />
                      <span className="pt_panel_label">PROMPT</span>
                    </div>
                    <div className="pt_instr">Translate English to French.</div>
                    <div>
                      {scene.lines.map((ln, i) => (
                        <div
                          key={i}
                          className={'pt_line' + (ln.q ? ' is_query' : '')}
                        >
                          <span className="pt_prefix">{ln.p}</span>
                          <span className="pt_value">
                            {ln.q ? (
                              <>
                                {typed}
                                {typing && <span className="pt_caret" />}
                              </>
                            ) : (
                              ln.v
                            )}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="pt_seg" role="tablist">
                    {SHOTS.map((s) => (
                      <button
                        key={s.key}
                        type="button"
                        className={shot === s.key ? 'is_active' : ''}
                        onClick={() => setShot(s.key)}
                      >
                        {s.label}
                      </button>
                    ))}
                  </div>

                  <div className="pt_caption">{scene.caption}</div>

                  <div className="pt_acc_head">
                    <span className="pt_acc_label">ACCURACY</span>
                    <span className="pt_acc_value">{scene.accuracy}%</span>
                  </div>
                  <div className="pt_acc_track">
                    <div
                      className="pt_acc_fill"
                      style={{ width: `${scene.accuracy}%` }}
                    />
                  </div>

                  <p className={'pt_verdict ' + (scene.ok ? 'ok' : 'bad')}>
                    {scene.verdict}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
