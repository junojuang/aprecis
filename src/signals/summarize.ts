import OpenAI from 'openai'
import { Item } from '@prisma/client'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

export interface Summary {
  topic: string
  hook: string
  coreIdea: string
  eli5: string
  whyItMatters: string
}

/**
 * Uses GPT-4o-mini to generate a structured summary for a signal cluster.
 */
export async function summarizeSignal(items: Item[]): Promise<Summary> {
  const clusterText = items
    .slice(0, 12) // cap at 12 items to stay within token budget
    .map((item) => {
      const src = `[${item.source.toUpperCase()}]`
      const text = item.title
        ? `${item.title} — ${item.content.slice(0, 250)}`
        : item.content.slice(0, 300)
      return `${src} ${text}`
    })
    .join('\n\n')

  const prompt = `You are an expert analyst detecting early emerging signals in research, social media, and news.

The following items all appeared within a short time window and are semantically related — they form a cluster that may represent an emerging idea or trend.

CLUSTER ITEMS:
${clusterText}

Analyze this cluster and respond with ONLY a valid JSON object in this exact format:
{
  "topic": "3-6 word signal label",
  "hook": "One punchy sentence (max 120 chars) that captures why this is interesting right now",
  "coreIdea": "2-3 sentences explaining the core emerging concept",
  "eli5": "1-2 sentences explaining this to a 10-year-old",
  "whyItMatters": "2-3 sentences on implications and why this signal matters"
}`

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{ role: 'user', content: prompt }],
    response_format: { type: 'json_object' },
    temperature: 0.6,
    max_tokens: 600,
  })

  const raw = response.choices[0].message.content ?? '{}'
  const parsed = JSON.parse(raw)

  return {
    topic: parsed.topic ?? 'Unnamed Signal',
    hook: parsed.hook ?? '',
    coreIdea: parsed.coreIdea ?? '',
    eli5: parsed.eli5 ?? '',
    whyItMatters: parsed.whyItMatters ?? '',
  }
}
