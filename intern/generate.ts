// Uses OpenAI to generate structured Instagram post ideas from arXiv papers

import OpenAI from 'openai';
import type { Paper } from './arxiv';
import { ACCOUNTS } from './accounts';

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export interface PostIdea {
  title: string;
  hook: string;
  format: string;
  slides: string[];
  caption: string;
  hashtags: string[];
  sourcePaper: string;
}

export async function generatePostIdeas(papers: Paper[]): Promise<PostIdea[]> {
  if (papers.length === 0) {
    console.warn('No papers to generate ideas from.');
    return [];
  }

  const papersText = papers
    .map((p, i) => `[${i + 1}] ${p.title}\nPublished: ${p.published}\n${p.summary}`)
    .join('\n\n---\n\n');

  const accountList = ACCOUNTS.map(a => `@${a}`).join(', ');

  const prompt = `
You are the content strategist for Aprecis — an AI microlearning Instagram account that turns bleeding-edge AI research into swipeable, ELI5-style carousel posts.

Style reference: study how accounts like ${accountList} present AI content — clean, visual, scroll-stopping, educational but not dry. Think: "a smart friend who makes AI feel exciting and approachable."

Here are the latest AI papers from arXiv this week:

${papersText}

Pick the 5 most Instagram-worthy papers (prioritise ones with surprising findings, practical impact, or concepts that can be explained with a great analogy) and generate one carousel post idea per paper.

Each post should:
- Teach one concept in 6 slides: hook → what it is → ELI5 → real-world analogy → key insight → takeaway + CTA
- Have a hook that stops the scroll (max 10 words, no emojis in hook)
- Feel like content from those reference accounts — punchy, visual, confident

Return a JSON object with key "ideas" containing an array of 5 objects, each with:
{
  "title": "internal name for this post",
  "hook": "first slide text — scroll-stopping, max 10 words",
  "format": "carousel",
  "slides": ["slide 1", "slide 2", "slide 3", "slide 4", "slide 5", "slide 6"],
  "caption": "Instagram caption, 2-3 punchy sentences + CTA to aprecis.app",
  "hashtags": ["ai", "machinelearning", ...up to 10 relevant tags],
  "sourcePaper": "paper title this is based on"
}
`;

  const res = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{ role: 'user', content: prompt }],
    response_format: { type: 'json_object' },
    temperature: 0.85,
  });

  const raw = res.choices[0].message.content ?? '{"ideas":[]}';
  const parsed = JSON.parse(raw);
  return parsed.ideas ?? [];
}
