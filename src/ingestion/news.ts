import { prisma } from '../db/client'
import articles from '../seed/news.json'

export async function ingestNews() {
  let inserted = 0

  for (const article of articles) {
    const content = `${article.title} ${article.description}`

    await prisma.item.upsert({
      where: { externalId: article.id },
      update: {},
      create: {
        externalId: article.id,
        title: article.title,
        content,
        author: article.source ?? null,
        source: 'news',
        publishedAt: new Date(article.published_at),
      },
    })
    inserted++
  }

  console.log(`News: upserted ${inserted} items`)
}
