# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Persistent Memory Vault

**Read at session start**: `/Users/juno/Desktop/Aprecis/Santa-Codex/`

- `CONTEXT.md` — current project state, active focus, who/what/why.
- `LOG.md` — append-only journal. Read last 3-5 entries for recent context.
- `STACK.md` — tech stack + commands.
- `DECISIONS.md` — ADR-lite, why past calls were made.
- `IDEAS.md`, `GLOSSARY.md`, `QUESTIONS.md` — backlog, jargon, open Qs.

**Write during/after work**:
- Append a short entry to `LOG.md` at end of each session (what shipped, what blocked, next step).
- Update `CONTEXT.md` "Active focus" + "Where it stands" when reality shifts.
- Add to `DECISIONS.md` whenever a non-trivial choice is made.
- Drop ideas into `IDEAS.md`, new terms into `GLOSSARY.md`, open Qs into `QUESTIONS.md`.

Karpathy rules: plain markdown, append-only LOG, ISO dates, short > long, grep-friendly.

## What This Is

AI microlearning app — a doom-scrolling replacement that converts bleeding-edge AI research papers into swipeable, ELI5-style card decks. Fully automated pipeline, no human review loop.

## Card Content Style

**Never use em dashes in card content.** This is a hard rule with no exceptions. It applies to every user-facing string in the app: loop content, lessons, interactives, glossaries, hooks, headlines, captions, takeaways, blurbs, and any other copy shown to the reader. Use a comma, colon, period, parentheses, or the middle dot (`·`) instead. Prefer rewriting the sentence over reaching for one.

- This covers **both** the literal character (`—`) **and** the Swift escape form `\u{2014}`. When auditing, grep for both, e.g. `rg -- "—|\\\\u\{2014\}"`. The escape form is easy to miss because a search for the literal glyph will not find it.
- This restriction is about in-app card content, not code comments or markdown docs like this file.

## Lesson Authoring (LearningLesson)

Bespoke lessons (`LearningLesson`, in `ios/MicrolearningApp/Models/*Lesson.swift`, rendered by `LearningFlowView`) follow the BERT/Attention "gold standard". When authoring or editing one:

- **No standalone glossary cards.** Do not add a "words, in plain English" style `.glossary` card to the visible flow. `LearningLesson.cards` already filters out any card carrying `glossaryTerms`, so such cards never render. Terms still feed the inline tappable glossary, sourced from `FoundationalGlossaries`, so technical words in prose stay tappable without a dedicated card.
- **Ramp into concepts, don't define them.** Before a card that introduces a technical concept (e.g. GRPO, chain of thought, distillation), place a short, jargon-free on-ramp card that builds the intuition with a relatable analogy first, then let the concept card land. Introduce one idea at a time, in narrative order, rather than dumping a list of definitions. Example: before the "judge answers against the group (GRPO)" card, a "how do you grade with no answer key?" classroom-curve analogy card.
- Keep the beginner-first voice: a curious 14-year-old should walk in and leave with a working mental model.

## Commands

### Backend (Deno / Supabase)
```bash
# Start local Supabase stack (DB + Edge Functions)
cd backend && npx supabase start

# Serve edge functions locally with hot reload
npx supabase functions serve --env-file .env.local

# Push DB schema
npx supabase db push

# Reset local DB
npx supabase db reset

# Test the full LLM pipeline on one paper (requires OPENAI_API_KEY)
deno run --allow-net --allow-env backend/scripts/test-pipeline.ts

# Deploy all edge functions
npx supabase functions deploy
```

### iOS
```bash
# One-time setup: generate the Xcode project from project.yml
cd ios && brew install xcodegen && xcodegen generate

# Then open in Xcode
open MicrolearningApp.xcodeproj
```
Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the scheme's environment variables (Edit Scheme → Run → Environment Variables). Run on simulator (iOS 17+) or device for TestFlight. **Do not commit the generated `.xcodeproj`** — regenerate it with `xcodegen generate` after pulling changes to `project.yml`.

## Architecture

```
arXiv / GitHub / RSS / Twitter
         │
         ▼
  [cron-ingest]  ← runs every 90min (pg_cron → edge function)
  Fetches papers, scores them, deduplicates, stores in `papers` table,
  enqueues paper_ids to pgmq queue "paper_processing"
         │
         ▼
  [process-queue]  ← runs every 5min (pg_cron → edge function)
  Dequeues batch of 5 papers, runs LLM pipeline:
    Stage 1: headline + core ideas  (gpt-4o-mini)
    Stage 2+3: ELI5 + analogy + visual DSL  (parallel, gpt-4o-mini)
    Stage 4: packages into Card[]
  Stores results in `processed_content` and `cards` tables
         │
         ▼
  [serve-cards]  ← public edge function called by iOS
  GET  /serve-cards?page=N   → paginated CardDeck[]
  POST /serve-cards/interaction → logs swipe/save/share
         │
         ▼
  iOS SwiftUI App (MVVM)
  FeedView → swipeable ZStack of CardDeckViews
  Each deck has 6 cards: hook → core_idea → eli5 → analogy → visual → takeaway
```

## Key Design Decisions

**Deno runtime for all backend code.** Supabase Edge Functions run Deno, so `backend/src/` uses Deno-compatible imports (URL-based for std lib, `esm.sh` for npm packages). Do not add `package.json` inside `backend/src/`.

**Shared source between functions.** `backend/src/` (types, scoring, ingestion, pipeline) is shared across all edge functions via relative imports. Supabase bundles these at deploy time.

**Scoring formula** (`backend/src/scoring.ts`): composite score = 0.4×recency + 0.3×social + 0.2×keyword + 0.1×author. Minimum score threshold: 0.25. Papers below this are dropped before queuing.

**LLM pipeline parallelism** (`backend/src/pipeline.ts`): Stages 2 (simplify) and 3 (visual) run in parallel after Stage 1 completes. All stages use `gpt-4o-mini` for cost/speed. Target: <10s per paper end-to-end.

**Visual DSL**: The backend generates a structured JSON schema (`VisualSchema` type) describing nodes and edges. The iOS `VisualRenderer.swift` renders this purely with SwiftUI shapes — no third-party chart libraries.

**Card types** (in order): `hook` → `core_idea` → `eli5` → `analogy` → `visual` → `takeaway`. Each type has a distinct visual treatment in `CardView.swift`.

## Database Tables

| Table | Purpose |
|---|---|
| `paper_catalog` | Unified catalog of every paper in the app (ingested + curated canon) with lightweight display metadata (title, published date, topic). Ingested rows auto-sync from `papers` via trigger; the Swift-authored canon is seeded by `scripts/seed-paper-catalog.ts`. |
| `papers` | Raw ingested papers with score and status |
| `processed_content` | LLM-extracted insights (headline, ELI5, analogy, visual DSL) |
| `cards` | Final packaged CardDeck JSON ready for the app |
| `user_interactions` | Swipe/save/share events per paper |

Paper status lifecycle: `queued` → `processing` → `processed` (or `failed`).

## Environment Variables

Copy `.env.example` → `.env.local`. Required: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `OPENAI_API_KEY`. Optional: `GITHUB_TOKEN` (increases GitHub API rate limits), `TWITTER_BEARER_TOKEN` (enables Twitter source).

## Adding a New Ingestion Source

1. Add a fetch function to `backend/src/ingestion.ts` returning `RawPaper[]`
2. Call it inside `cron-ingest/index.ts` in the `Promise.allSettled` block
3. Add the new source value to the `source` check constraint in `001_schema.sql`
