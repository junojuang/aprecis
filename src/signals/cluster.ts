import { prisma } from '../db/client'

interface EmbeddingRow {
  itemId: string
  vector: string
}

function parseVector(raw: string): number[] {
  // pgvector returns text like [0.1,0.2,...] — parse to float array
  return raw
    .replace(/^\[/, '')
    .replace(/\]$/, '')
    .split(',')
    .map(Number)
}

function cosineSimilarity(a: number[], b: number[]): number {
  let dot = 0
  let magA = 0
  let magB = 0
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i]
    magA += a[i] * a[i]
    magB += b[i] * b[i]
  }
  const denom = Math.sqrt(magA) * Math.sqrt(magB)
  return denom === 0 ? 0 : dot / denom
}

export interface Cluster {
  itemIds: string[]
}

/**
 * Loads all embeddings, computes pairwise cosine similarity, and returns
 * connected components where any two items exceed the similarity threshold.
 *
 * O(n²) — fine for MVP scale (< 5k items).
 */
export async function clusterItems(threshold = 0.78): Promise<Cluster[]> {
  const rows = await prisma.$queryRaw<EmbeddingRow[]>`
    SELECT "itemId", vector::text AS vector FROM "Embedding"
  `

  if (rows.length < 2) return []

  // Build vector map
  const vectors = new Map<string, number[]>()
  for (const row of rows) {
    vectors.set(row.itemId, parseVector(row.vector))
  }

  const ids = [...vectors.keys()]
  const n = ids.length

  // Adjacency list: items that are similar enough
  const adj = new Map<string, Set<string>>()
  for (const id of ids) adj.set(id, new Set())

  for (let i = 0; i < n; i++) {
    for (let j = i + 1; j < n; j++) {
      const sim = cosineSimilarity(vectors.get(ids[i])!, vectors.get(ids[j])!)
      if (sim >= threshold) {
        adj.get(ids[i])!.add(ids[j])
        adj.get(ids[j])!.add(ids[i])
      }
    }
  }

  // BFS to find connected components
  const visited = new Set<string>()
  const clusters: Cluster[] = []

  for (const start of ids) {
    if (visited.has(start)) continue

    const component: string[] = []
    const queue = [start]
    visited.add(start)

    while (queue.length > 0) {
      const current = queue.shift()!
      component.push(current)
      for (const neighbor of adj.get(current)!) {
        if (!visited.has(neighbor)) {
          visited.add(neighbor)
          queue.push(neighbor)
        }
      }
    }

    // Only keep clusters with 2+ items — solo items aren't signals
    if (component.length >= 2) {
      clusters.push({ itemIds: component })
    }
  }

  // Largest clusters first
  return clusters.sort((a, b) => b.itemIds.length - a.itemIds.length)
}
