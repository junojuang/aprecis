import 'dotenv/config'
import { prisma } from '../db/client'
import { clusterItems } from '../signals/cluster'
import { scoreCluster } from '../signals/score'
import { summarizeSignal } from '../signals/summarize'

export async function runSignalEngine() {
  console.log('--- Signal Engine ---')

  // Wipe previous signals to recompute from scratch
  await prisma.signalItem.deleteMany()
  await prisma.signal.deleteMany()

  const clusters = await clusterItems(0.78)
  console.log(`Found ${clusters.length} candidate clusters`)

  let detected = 0

  for (const cluster of clusters) {
    const scored = await scoreCluster(cluster)
    if (!scored) continue

    const items = await prisma.item.findMany({
      where: { id: { in: cluster.itemIds } },
    })

    // Summarize with LLM; fall back to heuristic label on failure
    let summaryData = {
      topic: scored.topic,
      hook: null as string | null,
      coreIdea: null as string | null,
      eli5: null as string | null,
      whyItMatters: null as string | null,
    }

    try {
      const summary = await summarizeSignal(items)
      summaryData = {
        topic: summary.topic,
        hook: summary.hook,
        coreIdea: summary.coreIdea,
        eli5: summary.eli5,
        whyItMatters: summary.whyItMatters,
      }
    } catch (err) {
      console.warn(`  Summarization failed for cluster, using fallback label`)
    }

    const signal = await prisma.signal.create({
      data: {
        id: scored.id,
        topic: summaryData.topic,
        sourceCount: scored.sourceCount,
        totalMentions: scored.totalMentions,
        timeSpanHours: scored.timeSpanHours,
        score: scored.score,
        strength: scored.strength,
        hook: summaryData.hook,
        coreIdea: summaryData.coreIdea,
        eli5: summaryData.eli5,
        whyItMatters: summaryData.whyItMatters,
      },
    })

    // Link items to this signal
    await prisma.signalItem.createMany({
      data: scored.itemIds.map((itemId) => ({ signalId: signal.id, itemId })),
      skipDuplicates: true,
    })

    detected++
    console.log(
      `  [${scored.strength.toUpperCase()}] "${signal.topic}" — ` +
        `sources: ${scored.sourceCount}, mentions: ${scored.totalMentions}, ` +
        `score: ${scored.score.toFixed(2)}`,
    )
  }

  console.log(`\nDone. ${detected} signals detected.`)
}

if (require.main === module) {
  runSignalEngine()
    .then(() => prisma.$disconnect())
    .catch((err) => {
      console.error(err)
      process.exit(1)
    })
}
