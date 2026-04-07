import 'dotenv/config'
import { prisma } from '../db/client'
import { ingestArxiv } from '../ingestion/arxiv'
import { ingestXPosts } from '../ingestion/xPosts'
import { ingestNews } from '../ingestion/news'

async function main() {
  console.log('--- Ingestion ---')
  await ingestArxiv()
  await ingestXPosts()
  await ingestNews()
  console.log('Ingestion complete.')
}

main()
  .then(() => prisma.$disconnect())
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
