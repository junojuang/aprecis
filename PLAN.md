# Aprecis improvement plan

Brief for future Claude sessions: this plan captures the improvements Juno wants to make to the app. Each section is self-contained — point at one and say "do this" and Claude should have enough to execute. File:line citations below were captured on 2026-04-21 and may drift; always re-read the current code before acting.

---

## Priority summary

| # | Workstream | Why first |
|---|---|---|
| ✅ P0 | [BUG] Persist DALL-E images to Supabase Storage | URLs expire in ~1–2h, so most concept images 404 in production |
| P1 | Diagram logic overhaul | Biggest user-facing quality lever; too templated, custom rate too high, match quality uneven |
| P1 | Reduce text density | App reads like a journal paper; the premise is "doom-scroll replacement" |
| P2 | Search + Featured ranking | Current search is title substring; featured is raw score sort |
| P2 | Reading progress v2 | Scroll bars exist; need step indicator + completion celebration |
| P3 | Liveliness / motion | Duolingo-flavored microinteractions — ship as a single pass, not piecemeal |
| P3 | Images audit | Paper hero missing; style guardrails |
| ✅ P4 | Progress bar polish | Small fixes, low risk |

---

## P0 — Persist DALL-E images  ✅ COMPLETED

> Status (2026-04-21): Steps 1–3 were already done (`backend/src/image-storage.ts` exists, both `add-paper` and `process-queue` call `persistConceptImages`). Step 4 backfill script now lives at `backend/scripts/rehost-concept-images.ts` — rehosts live DALL-E URLs and, with `--regenerate`, re-runs `stageConceptImage` (exported from `pipeline.ts`) for dead ones.


**Problem.** `backend/src/pipeline.ts` `stageConceptImage` (~line 352) returns raw DALL-E URLs. `processPaper` (~line 377) puts them straight into `Concept.conceptImageUrl`. `backend/supabase/functions/process-queue/index.ts` writes the deck to `cards` unchanged. DALL-E URLs have short TTLs — they 404 after a couple of hours.

**Evidence the fix pattern already exists.** `backend/supabase/functions/add-paper/index.ts:122-141` downloads the DALL-E image, uploads it to Supabase Storage, and rewrites the URL. The cron path does not do this.

**Work.**
1. Extract the download-and-upload helper into a shared module (`backend/src/image-storage.ts`) that takes `(aiUrl, paperId, conceptTitle) → supabaseStorageUrl`.
2. Call it in `pipeline.ts` inside the concept `Promise.all` block — immediately after `stageConceptImage` returns, replace the URL before the concept is returned.
3. Confirm the storage bucket + RLS policy match what `add-paper` assumes. If `add-paper` works, config is already correct; otherwise add a migration.
4. **Backfill.** Write `backend/scripts/rehost-concept-images.ts` that queries `cards` rows where `conceptImageUrl` matches `oaidalleapi*`, re-fetches from the original DALL-E URL (may already be dead — skip those), or re-calls DALL-E from the concept title/body, uploads, rewrites. Log skips.

**Verify.** Pick a recent deck in the iOS app, confirm `conceptImageUrl` is a `*.supabase.co/storage/*` URL; wait 3h and re-load → image still renders.

---

## P1 — Diagram logic overhaul

Three distinct problems bundled together:
- **Too templated:** only 6 native shapes cover a narrow slice of concept types.
- **Custom-rate too high:** `stageDiagramSpec` returns `custom` → falls through to `stageViz` (Sonnet, ~2.8k tokens each). Expensive and slower.
- **Match quality:** when native types *are* chosen, the match to the concept isn't always sensible.

### 1a. Expand the native diagram DSL

> Status (2026-04-21): **First three types shipped** — `cycle`, `number_box`, `equation`. Wired through `backend/src/types.ts` (DiagramType + StepSpec/EquationTerm + new DiagramSpec fields), `ios/…/Models.swift` (mirrored Codable), `DiagramView.swift` (dispatch + `CycleDiagram` radial/vertical fallback, `NumberBoxDiagram`, `EquationDiagram` with tappable terms), and `DIAGRAM_SPEC_PROMPT` in `pipeline.ts`. Remaining: `tree`, `timeline`, `venn`, `stacked_bar`, `matrix_grid`.


Existing types (`backend/src/types.ts:33-40`, rendered in `ios/.../DiagramView.swift`):
`flow`, `bar_chart`, `comparison`, `attention_heatmap`, `multi_head`, `sine_waves`, `custom`.

**Gaps** — common paper-concept shapes that currently fall to `custom`:

| New type | Shape | Example concepts |
|---|---|---|
| `cycle` | iterative loop with numbered steps | RLHF loop, diffusion denoise, self-refine |
| `tree` | hierarchy / decision / MoE routing | MoE experts, beam search, task decomposition |
| `number_box` | one headline statistic | "1000× fewer params", "97% accuracy" |
| `equation` | rendered formula with labelled terms | attention formula, loss functions, Adam update |
| `timeline` | ordered events on an axis | model size progression, training curriculum |
| `venn` | overlapping sets | multi-modal alignment, benchmark overlap |
| `stacked_bar` | proportions summing to 100% | parameter budget, compute breakdown |
| `matrix_grid` | 2D cell grid with labels | sparse attention patterns, token embeddings |

**Per new type:**
- Add enum case + Codable fields to `backend/src/types.ts` and `ios/.../Models.swift`
- Add dispatch case in `DiagramView.swift`
- Add a SwiftUI `struct` that renders it
- Add the type spec line to `DIAGRAM_SPEC_PROMPT` in `pipeline.ts`

**Start order:** `cycle`, `number_box`, `equation`. Highest-value three.

### 1b. Smarter diagram selection

`stageDiagramSpec` (pipeline.ts ~213) does a single Haiku call that returns the full spec or `custom`.

**Upgrades:**
- **Two-stage classify → generate.** First call returns only `{"shape": "process|metric|comparison|relation|cycle|formula|tree|hierarchy|no_match", "rationale": "..."}`. Second call generates the spec for the chosen shape. Smaller search space per call → better picks, and rationale is loggable for auditing.
- **Few-shot the prompt.** Three worked examples (e.g. "Concept: reward model training" → `flow` with specific nodes, "Concept: 1000× fewer parameters" → `number_box`) anchor model choices.
- **Rename `custom` to `no_match`** and only permit it after the model explicitly explains why none of the expanded types fit. Target: <10% `no_match` rate.

### 1c. Model tier experiments

`stageViz` (pipeline.ts ~260) uses Sonnet for custom HTML. Juno asked about Opus.

- Pick 20 concepts that currently generate `custom` HTML. Re-generate with Opus. Render side-by-side in a simple viewer (or print to an HTML page). Judge quality + inspect tokens used.
- Cost check: Opus is ~5× Sonnet input, ~5× output. Worth it only if perceived quality lift is large.
- If mixed, keep Sonnet default and allow Opus upgrade for concepts where `stageDiagramSpec` classifier has low confidence.
- Add `viz_model` column to `cards` for traceability.

### 1d. Diagram quality audit

Before tuning prompts blind, measure.

- Write `backend/scripts/audit-diagrams.ts`:
  - Join `cards` + `papers`, sample 30 recent decks
  - For each concept, print `{paper_title, concept_title, concept_body[:200], diagram_type, spec_summary}`
- Add a "judge" prompt (Haiku, cheap) rating each concept+spec on 1–5 for:
  - (a) right type chosen for this concept shape
  - (b) labels are paper-specific, not generic ("Input"/"Step 1")
  - (c) the visual actually reveals the concept's insight
- Dashboard: histogram of types chosen, `no_match` rate, mean judge score per type.
- Re-run the audit after each prompt change. This is the feedback loop.

---

## P1 — Reduce text density

**Current** (`ios/.../PaperDetailView.swift`):
Hero block (hook + paper title + 3 stat pills) → `AprecisCard` with 40–55-word summary → 4 `ConceptFeedCard`s each with image + title + 2–3-sentence body + diagram. Reads like a journal paper.

**Proposals — align with user before building:**
- **Demote the summary.** Move below the concepts, or hide behind a "Read AI summary" expander at top.
- **Concept body as bullets.** Change Stage-1 prompt in `pipeline.ts` so `concepts[].body` returns as a 3-item bullet list instead of prose. Render as bullets at 12pt instead of a prose block.
- **Hero-y concept cards.** Enlarge the 100pt cover image to ~180pt; move title overlay onto image; collapse body to 2 lines with "more" expand.
- **Skim / Read toggle.** Single segmented control at top of `PaperDetailView`:
  - Skim = hook + concept titles + diagrams + bullets collapsed
  - Read = adds full body text + summary
  - Persist last choice per-user (`UserDefaults`).

**Recommendation:** default to Skim. The whole premise is scrolling replacement, not journal-reading.

---

## P2 — Search + Featured ranking

### Search

`ExploreView.filteredDecks` (`ios/.../SearchView.swift:12-19`) is title substring only.

> Status (2026-04-21): **Step 1 shipped.** Weighted relevance scoring lives in `SearchRanking` at the bottom of `SearchView.swift`; matches across title / hook / summary / concept title / concept body with the weights below, plus score + recency bonuses. Also added `FeedViewModel.loadAll()` so Explore pages through the entire feed on appear — search now sees every paper, not just page 0. Step 2 (pgvector embeddings) and the topic-chip replacement remain open.

**Step 1 (client-side, good enough for now):**
```
relevance =
    3.0 × title_contains(q)
  + 2.0 × hook_contains(q)
  + 1.5 × concept_title_contains(q)
  + 0.8 × concept_body_contains(q)
  + 0.4 × paper.score
  + 0.3 × recency_boost
```
Tie-break: higher `paper.score`.

**Step 2 (server-side, later):**
- Embed each paper (title + hook + concept titles) via `text-embedding-3-small`
- Store in `papers.embedding vector(1536)` with pgvector
- Query: embed the search term, cosine-rank; fall back to keyword if query is very short
- Requires pgvector migration + a new edge function

**Topic chips:** hard-coded list at `SearchView.swift:10` — replace with top-N derived from recent papers' keyword distribution, or add a `tags text[]` column to `papers` populated by Stage-1 LLM.

### Featured

`HomeView.featuredDecks` (`ios/.../HomeView.swift:85-88`) just sorts by score.

**Better ranking:**
```
featured_score =
    0.5 × paper.score
  + 0.3 × recency_boost(published_at, half_life = 7 days)
  + 0.2 × engagement_boost(saves + shares per view)
```
- Diversity constraint: no two top-3 featured share the same source.
- Freshness window: only consider papers from last 14 days.
- Cache the ordering in a `featured_papers` materialized view refreshed by each cron ingest run — cheap to compute, app stops re-ranking client-side on every load.

---

## P2 — Reading progress v2

**Already in place** (confirmed):
- `HomeView.swift:58-64` — 3px top scroll-progress bar for home
- `PaperDetailView.swift:17-30` — 3px top scroll-progress bar for paper detail, persisted via `ReadingProgressStore`
- `FeaturedPaperCard`, `PaperRowView`, `TrendingRowView` all surface per-paper progress

**Add:**
- **Concept step indicator** in `PaperDetailView`: small row of 4 dots below the hero block, lit up when the matching `ConceptFeedCard` enters the viewport. Tap a dot to jump-scroll to that concept.
- **Completion celebration** when paper hits 100%:
  - `ProgressRing` bounces (spring animation)
  - Single `UIImpactFeedbackGenerator.impactOccurred(.soft)`
  - Optional subtle confetti (~5 shapes, 700ms). One-time per paper — guard with a `completed_paper_ids: Set<String>` in `ReadingProgressStore`.
- **Daily-papers streak** on `ProfileView`: persist `last_read_date` + streak counter in `UserDefaults`; show "🔥 5 days in a row".

**Defer:** bundle-completion tracking beyond what already exists.

---

## P3 — Liveliness / motion

Ship as one coordinated pass, not piecemeal. Motion that isn't tied to accomplishment feels twitchy.

| Effect | Where | Notes |
|---|---|---|
| Concept-card entrance | `ConceptFeedCard` in `PaperDetailView` | `.opacity` + `.offset(y: 12)` keyed on `GeometryReader` minY. Stagger by index. |
| Diagram staggered appear | `DiagramView` dispatcher | Extend the existing `BarChart`/`SineWaves` pattern to `Flow` (nodes draw sequentially) and `Comparison` (rows slide in). |
| Tap feedback | All card-wrapping `NavigationLink`s | Wrap in a `.pressable()` modifier: `.scaleEffect(pressed ? 0.98 : 1.0)` + light haptic. |
| Number roll-up | `StatPill` in `PaperHeroSection` | Animate from 0 → value on appear (250ms ease-out). |
| Hero parallax | `PaperHeroSection` background image | Shift image y by `scrollOffset × 0.3`. |
| Tab-icon bounce | `MainTabView` | `.symbolEffect(.bounce, value: selectedTab)` on SF Symbol. |
| Completion confetti | See progress v2 | |

**Principle:** Duolingo's feel comes from *functional* feedback — right/wrong, streak-up, owl reacts. Tie our motion to accomplishment moments: finish paper, finish bundle, hit streak. No animation for animation's sake.

---

## P3 — Images audit

**Image types and locations:**

| Type | Current | Action |
|---|---|---|
| Concept cover (DALL-E) | ✓ in `FeaturedPaperCard`, `PaperRowView`, `ConceptFeedCard` | Keep. Tighten prompt (see below). |
| Paper-level hero | ✗ missing — `PaperHeroSection` is text-only | Add. Either reuse first-concept image, or generate one dedicated per-paper image with a different prompt ("editorial magazine cover for paper X"). |
| Source/author badge | ✗ | Skip for now. |
| Diagram accents | ✗ | Likely noise. Skip. |

**Style consistency:**
- Current DALL-E prompt (`pipeline.ts` ~357) is good. Tweaks:
  - Add "no text, no symbols, no letters, no typography" — DALL-E 3 sometimes tries to render words.
  - Consider `gpt-image-1` (OpenAI) or Imagen-3 (Vertex AI) for higher-quality, lower-cost images. Compare side-by-side on 10 concepts before switching.
- **Post-generation guard:** optional small vision call that rejects images containing text/faces/UI elements and re-rolls once. Don't ship this until after the P0 caching fix.

---

## P4 — Progress bar polish  ✅ COMPLETED

> Status (2026-04-21): All three items shipped.
> - `HomeView.swift` progress bar now uses `GeometryReader.size.width` instead of `UIScreen.main.bounds.width` so it renders correctly on iPad / Split View.
> - `BundleDetailView` now has the same scroll-driven 3px top bar as Home and PaperDetail, using a local `BundleScrollOffsetKey`.
> - Fill color animates teal → amber (≥70%) → green (≥95%) via the shared `progressBarColor(_:)` helper in `ColorExtensions.swift`; a 0.3s `.easeInOut` animation keyed on the color smooths the transitions. Home, PaperDetail, and Bundle all use it.

Both home and paper detail already have the 3px top bar. Remaining issues:
- `HomeView.swift:61` uses `UIScreen.main.bounds.width` — wrong on iPad / split view. Replace with `GeometryReader`.
- Add the same top-bar affordance on `BundleDetailView` (and `ConceptDeepDiveView` if revived).
- Animate fill color from teal → amber → green as progress approaches 1.0 (subtle "nearly there" cue).

---

## Decisions needed from Juno before executing

- **Text density default:** Skim or Read? (Recommendation: Skim.)
- **Opus test for diagrams:** OK to A/B 20 concepts with Opus vs Sonnet? Cost ~$3–5.
- **Embeddings search:** ship now (new migration, new function) or defer to later?
- **PR grouping:** suggest (A) DALL-E bug fix, (B) diagram DSL + prompt rework, (C) text density + skim mode, (D) search ranking, (E) featured ranking, (F) progress v2 + motion, (G) image polish + audit harness. Seven PRs.

---

## Out of scope (for this plan)

- Authentication / user accounts beyond what exists
- Push notifications
- Paid tier / payments
- Non-English papers
- Bundle editor / user-generated bundles

Move these into their own plans if they become priorities.
