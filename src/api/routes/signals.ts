import { Router, Request, Response } from 'express'
import { prisma } from '../../db/client'

const router = Router()

// GET /signals — top signals sorted by score
router.get('/', async (_req: Request, res: Response) => {
  try {
    const signals = await prisma.signal.findMany({
      orderBy: { score: 'desc' },
      include: {
        signalItems: {
          include: { item: true },
        },
      },
    })

    res.json({
      count: signals.length,
      signals: signals.map(formatSignal),
    })
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Failed to fetch signals' })
  }
})

// GET /signals/:id — single signal with full metadata
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const signal = await prisma.signal.findUnique({
      where: { id: req.params.id },
      include: {
        signalItems: {
          include: { item: true },
        },
      },
    })

    if (!signal) {
      res.status(404).json({ error: 'Signal not found' })
      return
    }

    res.json(formatSignal(signal))
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Failed to fetch signal' })
  }
})

type SignalWithItems = Awaited<ReturnType<typeof prisma.signal.findUnique>> & {
  signalItems: Array<{ item: { id: string; source: string; title: string | null; content: string; author: string | null; publishedAt: Date } }>
}

function formatSignal(signal: any) {
  return {
    id: signal.id,
    topic: signal.topic,
    strength: signal.strength,
    score: Math.round(signal.score * 100) / 100,
    metadata: {
      sourceCount: signal.sourceCount,
      totalMentions: signal.totalMentions,
      timeSpanHours: Math.round(signal.timeSpanHours * 10) / 10,
      sources: [...new Set((signal.signalItems ?? []).map((si: any) => si.item.source))],
    },
    summary: {
      hook: signal.hook,
      coreIdea: signal.coreIdea,
      eli5: signal.eli5,
      whyItMatters: signal.whyItMatters,
    },
    items: (signal.signalItems ?? []).map((si: any) => ({
      id: si.item.id,
      source: si.item.source,
      title: si.item.title,
      excerpt: si.item.content.slice(0, 220),
      author: si.item.author,
      publishedAt: si.item.publishedAt,
    })),
    detectedAt: signal.detectedAt,
  }
}

export default router
