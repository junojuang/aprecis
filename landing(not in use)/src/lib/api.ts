import type { AprecisDeck, Blueprint, DeckResponse } from './types'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string

/** Pull a bare arXiv id out of a URL or raw id string. */
export function parseArxivId(input: string): string | null {
  const m = input.match(/(\d{4}\.\d{4,5})(?:v\d+)?/)
  return m ? m[1] : null
}

/**
 * Convert a paper into an Aprecis deck.
 *  1. POST add-paper  → runs the LLM pipeline (cold runs take ~60s), returns
 *     hook + summary + concepts.
 *  2. GET cards row   → the editorial blueprint (timeline, viz) stored by the
 *     same pipeline. Best-effort: a missing blueprint never fails the convert.
 */
export async function convertPaper(input: string): Promise<AprecisDeck> {
  const arxivId = parseArxivId(input)
  if (!arxivId) {
    throw new Error('That does not look like an arXiv link. Try arxiv.org/abs/2501.12948')
  }

  const res = await fetch(`${SUPABASE_URL}/functions/v1/add-paper`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({ url: `https://arxiv.org/abs/${arxivId}` }),
  })

  const deck = (await res.json()) as DeckResponse & { error?: string }
  if (!res.ok || deck.error) {
    throw new Error(deck.error || `Conversion failed (HTTP ${res.status})`)
  }

  const blueprint = await fetchBlueprint(deck.paper_id)
  return { deck, blueprint }
}

async function fetchBlueprint(paperId: string): Promise<Blueprint | null> {
  try {
    const url = `${SUPABASE_URL}/rest/v1/cards?paper_id=eq.${encodeURIComponent(
      paperId,
    )}&select=blueprint`
    const res = await fetch(url, { headers: { apikey: SUPABASE_ANON_KEY } })
    if (!res.ok) return null
    const rows = (await res.json()) as { blueprint: Blueprint | null }[]
    return rows[0]?.blueprint ?? null
  } catch {
    return null
  }
}
