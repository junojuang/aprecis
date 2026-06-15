import { useMemo, useState } from 'react'
import type { DiagramSpec, EquationTerm } from '../../../lib/types'

/**
 * Tap-a-term equation card. We tokenise the formula and wrap every defined
 * term in a chip; tapping a chip slides its definition into the panel below.
 * Mirrors the iOS EquationRichVizSpec where each glyph is its own pressable
 * target — the formula becomes a small interactive instead of inert prose.
 */

interface Token {
  text: string
  termIdx: number // -1 = plain text
}

function tokenise(formula: string, terms: EquationTerm[]): Token[] {
  if (terms.length === 0) return [{ text: formula, termIdx: -1 }]
  // Build a regex matching any defined symbol, longest first so multi-char
  // symbols (e.g. "QK^T") beat single-char prefixes.
  const symbols = [...terms]
    .map((t, i) => ({ sym: t.symbol, i }))
    .sort((a, b) => b.sym.length - a.sym.length)
  const out: Token[] = []
  let cursor = 0
  while (cursor < formula.length) {
    let hit: { sym: string; i: number } | null = null
    for (const s of symbols) {
      if (!s.sym) continue
      if (formula.startsWith(s.sym, cursor)) {
        hit = s
        break
      }
    }
    if (hit) {
      out.push({ text: hit.sym, termIdx: hit.i })
      cursor += hit.sym.length
    } else {
      // Accumulate one char of plain text; we will merge later.
      out.push({ text: formula[cursor], termIdx: -1 })
      cursor++
    }
  }
  // Merge runs of plain-text tokens for readability.
  const merged: Token[] = []
  for (const t of out) {
    const last = merged[merged.length - 1]
    if (last && last.termIdx === -1 && t.termIdx === -1) last.text += t.text
    else merged.push({ ...t })
  }
  return merged
}

export default function EquationSpec({ spec }: { spec: DiagramSpec }) {
  const terms = spec.terms ?? []
  const tokens = useMemo(() => tokenise(spec.formula ?? '', terms), [spec.formula, terms])
  const [active, setActive] = useState<number>(-1)

  // First termed token, so the panel has something useful at rest.
  const initialIdx = useMemo(
    () => tokens.findIndex((t) => t.termIdx !== -1 && terms[t.termIdx]?.meaning),
    [tokens, terms],
  )
  const shownIdx = active === -1 ? initialIdx : active
  const shownTerm = shownIdx === -1 ? null : terms[tokens[shownIdx]?.termIdx]

  return (
    <div className="ds_eq">
      {spec.caption && <p className="ds_caption">{spec.caption}</p>}
      <div className="ds_eq_card">
        <div className="ds_eq_hint">Tap any symbol to see what it means</div>

        <div className="ds_eq_formula">
          {tokens.map((t, i) => {
            if (t.termIdx === -1) {
              return (
                <span className="ds_eq_glue" key={i}>
                  {t.text}
                </span>
              )
            }
            const isActive = i === shownIdx
            return (
              <button
                type="button"
                key={i}
                className={'ds_eq_chip' + (isActive ? ' active' : '')}
                onClick={() => setActive(isActive ? -1 : i)}
                aria-pressed={isActive}
              >
                {t.text}
              </button>
            )
          })}
        </div>

        <div className="ds_eq_panel" key={shownIdx}>
          {shownTerm ? (
            <>
              <div className="ds_eq_panel_sym">{shownTerm.symbol}</div>
              <div className="ds_eq_panel_body">{shownTerm.meaning}</div>
            </>
          ) : (
            <div className="ds_eq_panel_idle">
              The formula condenses the paper's idea. Tap a symbol to unfold it.
            </div>
          )}
        </div>

        {terms.length > 0 && (
          <div className="ds_eq_terms" aria-hidden="true">
            {terms.map((t, i) => {
              const tokenIdx = tokens.findIndex((tt) => tt.termIdx === i)
              const isActive = tokenIdx === shownIdx
              return (
                <button
                  type="button"
                  key={i}
                  className={'ds_eq_term' + (isActive ? ' active' : '')}
                  onClick={() => tokenIdx >= 0 && setActive(tokenIdx)}
                >
                  <span className="ds_eq_sym">{t.symbol}</span>
                  <span className="ds_eq_meaning">{t.meaning}</span>
                </button>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
