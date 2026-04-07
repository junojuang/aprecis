import 'dotenv/config'
import { prisma } from '../db/client'
import { ingestXPosts } from '../ingestion/xPosts'
import { ingestNews } from '../ingestion/news'

async function main() {
  console.log('Seeding mock data (X posts + news)...')
  await ingestXPosts()
  await ingestNews()
  console.log('Seed complete. Run `npm run ingest` to also fetch live arXiv data.')
}

main()
  .then(() => prisma.$disconnect())
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
