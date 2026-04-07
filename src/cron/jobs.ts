import cron from 'node-cron'
import { ingestArxiv } from '../ingestion/arxiv'
import { ingestXPosts } from '../ingestion/xPosts'
import { ingestNews } from '../ingestion/news'
import { processEmbeddings } from '../processing/embed'
import { runSignalEngine } from '../jobs/signals'

export function startCronJobs() {
  // Ingest from all sources every 6 hours
  cron.schedule('0 */6 * * *', async () => {
    console.log('[CRON] Ingestion starting...')
    try {
      await ingestArxiv()
      await ingestXPosts()
      await ingestNews()
    } catch (err) {
      console.error('[CRON] Ingestion error:', err)
    }
  })

  // Embed any new items every 2 hours
  cron.schedule('0 */2 * * *', async () => {
    console.log('[CRON] Embedding starting...')
    try {
      await processEmbeddings()
    } catch (err) {
      console.error('[CRON] Embedding error:', err)
    }
  })

  // Recompute signals every 4 hours (offset by 30 min to run after embedding)
  cron.schedule('30 */4 * * *', async () => {
    console.log('[CRON] Signal engine starting...')
    try {
      await runSignalEngine()
    } catch (err) {
      console.error('[CRON] Signal engine error:', err)
    }
  })

  console.log('Cron jobs scheduled.')
}
