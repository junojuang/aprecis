import { randomUUID } from 'crypto'
import { Item } from '@prisma/client'
import { prisma } from '../db/client'
import { Cluster } from './cluster'

export type SignalStrength = 'weak' | 'emerging' | 'strong'

export interface ScoredSignal {
  id: string
  topic: string
  itemIds: string[]
  sourceCount: number
  totalMentions: number
  timeSpanHours: number
  score: number
  strength: SignalStrength
}

function classifyStrength(
  sourceCount: number,
  totalMentions: number,
  timeSpanHours: number,
): SignalStrength {
  if (sourceCount >= 3 && totalMentions >= 7 && timeSpanHours <= 24) return 'strong'
  if (sourceCount >= 2 && totalMentions >= 4 && timeSpanHours <= 48) return 'emerging'
  return 'weak'
}

/**
 * Scores a cluster of items.
 * Returns null if the cluster doesn't meet the minimum signal threshold.
 */
export async function scoreCluster(cluster: Cluster): Promise<ScoredSignal | null> {
  const items: Item[] = await prisma.item.findMany({
    where: { id: { in: cluster.itemIds } },
  })

  if (items.length === 0) return null

  const sources = new Set(items.map((i) => i.source))
  const sourceCount = sources.size
  const totalMentions = items.length

  // --- Minimum thresholds ---
  if (sourceCount < 2) return null
  if (totalMentions < 3) return null

  const timestamps = items.map((i) => i.publishedAt.getTime())
  const minTs = Math.min(...timestamps)
  const maxTs = Math.max(...timestamps)
  const timeSpanHours = (maxTs - minTs) / (1000 * 60 * 60)

  if (timeSpanHours > 72) return null

  // --- Recency bonus ---
  const avgTs = timestamps.reduce((a, b) => a + b, 0) / timestamps.length
  const hoursAgo = (Date.now() - avgTs) / (1000 * 60 * 60)
  const recencyBonus = hoursAgo <= 24 ? 5 : hoursAgo <= 48 ? 2 : 0

  // --- Time-span penalty: loose clusters are noisier ---
  const timeSpanPenalty = timeSpanHours > 48 ? -2 : 0

  const score =
    sourceCount * 3 +
    Math.log(totalMentions + 1) +
    recencyBonus +
    timeSpanPenalty

  const topic = deriveTopicLabel(items)
  const strength = classifyStrength(sourceCount, totalMentions, timeSpanHours)

  return {
    id: randomUUID(),
    topic,
    itemIds: cluster.itemIds,
    sourceCount,
    totalMentions,
    timeSpanHours,
    score,
    strength,
  }
}

function deriveTopicLabel(items: Item[]): string {
  // Pull titles where available, fall back to first 80 chars of content
  const texts = items
    .map((i) => i.title ?? i.content.slice(0, 80))
    .filter(Boolean)

  // Take the shortest title as the provisional label — most titles are descriptive
  const sorted = texts.sort((a, b) => a.length - b.length)
  const label = sorted[0] ?? 'Unknown Topic'
  return label.length > 80 ? label.slice(0, 77) + '...' : label
}
