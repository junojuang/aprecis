import { prisma } from '../db/client'
import posts from '../seed/xPosts.json'

export async function ingestXPosts() {
  let inserted = 0

  for (const post of posts) {
    await prisma.item.upsert({
      where: { externalId: post.id },
      update: {},
      create: {
        externalId: post.id,
        title: null,
        content: post.content,
        author: post.author,
        source: 'x',
        publishedAt: new Date(post.created_at),
      },
    })
    inserted++
  }

  console.log(`X posts: upserted ${inserted} items`)
}
