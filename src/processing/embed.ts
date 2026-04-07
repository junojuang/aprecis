import OpenAI from 'openai'
import { v4 as uuidv4 } from 'uuid'
import { prisma } from '../db/client'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

// Max characters to send — well within token limits for text-embedding-3-small
const MAX_CHARS = 8000

export async function embedContent(content: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: content.slice(0, MAX_CHARS),
  })
  return response.data[0].embedding
}

export async function processEmbeddings() {
  const items = await prisma.item.findMany({
    where: { embedded: false },
  })

  if (items.length === 0) {
    console.log('No unembedded items found.')
    return
  }

  console.log(`Embedding ${items.length} items...`)

  for (const item of items) {
    try {
      const vector = await embedContent(item.content)
      // pgvector expects the string format [0.1,0.2,...,0.n]
      const vectorStr = `[${vector.join(',')}]`
      const embeddingId = uuidv4()

      await prisma.$executeRaw`
        INSERT INTO "Embedding" (id, "itemId", vector, "createdAt")
        VALUES (
          ${embeddingId}::uuid,
          ${item.id}::uuid,
          ${vectorStr}::vector,
          NOW()
        )
        ON CONFLICT ("itemId")
        DO UPDATE SET vector = ${vectorStr}::vector
      `

      await prisma.item.update({
        where: { id: item.id },
        data: { embedded: true },
      })

      const label = item.title ?? item.content.slice(0, 60)
      console.log(`  Embedded [${item.source}]: ${label}`)
    } catch (err) {
      console.error(`  Failed to embed item ${item.id}:`, err)
    }
  }

  console.log('Embedding pass complete.')
}
