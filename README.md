# Aprecis — Signal Detection Engine

Detects early emerging ideas by finding semantically similar content appearing across multiple sources (arXiv papers, expert posts, news) within tight time windows.

---

## Prerequisites

- Node.js 18+
- PostgreSQL 15+ with **pgvector** extension
- OpenAI API key

Install pgvector: https://github.com/pgvector/pgvector#installation

---

## Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env — add your DATABASE_URL and OPENAI_API_KEY
```

### 3. Create the database

```bash
createdb aprecis
```

### 4. Run Prisma migration

```bash
npx prisma migrate dev --name init
```

### 5. Enable pgvector + add vector column

```bash
psql $DATABASE_URL -f scripts/init-pgvector.sql
```

### 6. Generate Prisma client

```bash
npx prisma generate
```

---

## Running the pipeline

### Option A — Full pipeline in one command

```bash
npm run pipeline
```

This runs: ingest → embed → signal detection sequentially.

### Option B — Step by step

```bash
# 1. Seed mock data (X posts + news articles)
npm run seed

# 2. Ingest live arXiv papers (requires network)
npm run ingest

# 3. Generate embeddings via OpenAI
npm run embed

# 4. Cluster items and detect signals
npm run signals
```

---

## Starting the API server

```bash
npm run dev
```

Server starts at `http://localhost:3000` and kicks off cron jobs.

---

## API Endpoints

### `GET /health`
```json
{ "status": "ok", "service": "aprecis", "ts": "..." }
```

### `GET /signals`
Returns all detected signals sorted by score.

```json
{
  "count": 5,
  "signals": [
    {
      "id": "uuid",
      "topic": "Autonomous AI Agents",
      "strength": "emerging",
      "score": 12.4,
      "metadata": {
        "sourceCount": 3,
        "totalMentions": 8,
        "timeSpanHours": 36.2,
        "sources": ["arxiv", "x", "news"]
      },
      "summary": {
        "hook": "Agentic AI is crossing from demo to production deployment.",
        "coreIdea": "...",
        "eli5": "...",
        "whyItMatters": "..."
      },
      "items": [...],
      "detectedAt": "..."
    }
  ]
}
```

### `GET /signals/:id`
Returns a single signal with full item details.

---

## Architecture

```
src/
├── ingestion/     arXiv RSS, X posts (mock), news (mock)
├── processing/    OpenAI embeddings via text-embedding-3-small
├── signals/
│   ├── cluster.ts  Cosine similarity → connected components
│   ├── score.ts    Signal scoring formula + strength classification
│   └── summarize.ts  GPT-4o-mini summary generation
├── api/           Express routes
├── cron/          Scheduled jobs (ingest 6h, embed 2h, signals 4h)
├── jobs/          Runnable one-shot scripts
└── seed/          Mock data + seed script
```

### Signal scoring formula

```
score = (sourceCount × 3) + log(totalMentions + 1) + recencyBonus + timeSpanPenalty
```

- **recencyBonus**: +5 if avg age < 24h, +2 if < 48h
- **timeSpanPenalty**: −2 if timeSpan > 48h

### Signal thresholds

| Strength   | Sources | Mentions | Time window |
|------------|---------|----------|-------------|
| `weak`     | ≥ 2     | ≥ 3      | ≤ 72h       |
| `emerging` | ≥ 2     | ≥ 4      | ≤ 48h       |
| `strong`   | ≥ 3     | ≥ 7      | ≤ 24h       |

---

## Cron Schedule

| Job       | Schedule     | Description                        |
|-----------|--------------|------------------------------------|
| Ingest    | Every 6h     | Fetch arXiv + reload mock sources  |
| Embed     | Every 2h     | Embed any new unprocessed items    |
| Signals   | Every 4h+30m | Recluster + rescore all signals    |

---

## Database Schema

```
Item         — raw content from all sources
Embedding    — pgvector(1536) per item
Signal       — a detected signal cluster with scores
SignalItem   — join table (Signal ↔ Item)
```
