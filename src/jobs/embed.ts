import 'dotenv/config'
import { prisma } from '../db/client'
import { processEmbeddings } from '../processing/embed'

async function main() {
  console.log('--- Embedding ---')
  await processEmbeddings()
  console.log('Embedding complete.')
}

main()
  .then(() => prisma.$disconnect())
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
