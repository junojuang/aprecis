import axios from 'axios'
import { XMLParser } from 'fast-xml-parser'
import { prisma } from '../db/client'

const ARXIV_API = 'https://export.arxiv.org/api/query'
const parser = new XMLParser({ ignoreAttributes: false, isArray: (name) => name === 'entry' || name === 'author' })

interface ArxivAuthor {
  name: string
}

interface ArxivEntry {
  id: string
  title: string
  summary: string
  author: ArxivAuthor[]
  published: string
}

export async function ingestArxiv(query = 'large language models OR AI agents OR multimodal', maxResults = 75) {
  console.log(`Fetching arXiv: "${query}"...`)

  const url =
    `${ARXIV_API}?search_query=all:${encodeURIComponent(query)}` +
    `&sortBy=submittedDate&sortOrder=descending&max_results=${maxResults}`

  const response = await axios.get<string>(url, { timeout: 30_000 })
  const parsed = parser.parse(response.data)
  const entries: ArxivEntry[] = parsed?.feed?.entry ?? []

  if (entries.length === 0) {
    console.log('arXiv: no entries returned')
    return
  }

  let inserted = 0
  for (const entry of entries) {
    const authors = (entry.author ?? []).map((a) => a.name).join(', ')

    // arXiv ID looks like: http://arxiv.org/abs/2312.00001v1
    const externalId = entry.id.split('/abs/').pop()?.split('v')[0] ?? entry.id

    const title = entry.title?.trim().replace(/\n/g, ' ') ?? ''
    const abstract = entry.summary?.trim().replace(/\n/g, ' ') ?? ''
    const content = `${title} ${abstract}`

    await prisma.item.upsert({
      where: { externalId },
      update: {},
      create: {
        externalId,
        title,
        content,
        author: authors || 'Unknown',
        source: 'arxiv',
        publishedAt: new Date(entry.published),
      },
    })
    inserted++
  }

  console.log(`arXiv: upserted ${inserted} items`)
}
