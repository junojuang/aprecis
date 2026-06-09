# Aprecis Vision

> Last updated: 2026-05-14
> Source: stated by Juno, codified by Claude.
> If you are an agent and you change product direction, update this file and append a one-line note to `Santa-Claude/LOG.md`.

---

## The pain point we solve

People who are sourcing research papers — researchers, students, engineers, curious technologists — hit the same wall every time:

1. Find a candidate paper.
2. Read the abstract. Abstracts are dense, jargon-heavy, written for peer reviewers, and optimized for novelty claims, not for relevance to *your* question.
3. Decide "is this useful to me?"
4. Repeat 10–50 times to find one paper that fits.

This is mentally expensive. Most people give up, miss important work, or fall back on whatever's trending on Twitter.

**Aprecis replaces the "read the abstract" stage of literature discovery.**

---

## What Aprecis is

A research-paper companion that turns the discovery loop from *"read prose, decide"* into *"swipe through cards, see the mechanism, decide."*

For each paper we ingest, Aprecis produces:

- A **hook** — one sentence in plain English that says what the paper unlocked.
- A **core idea** — what the paper actually does, with no author name-drops and no jargon dump.
- An **ELI5 / analogy** — the everyday version, so a non-expert can build intuition before any math shows up.
- An **interactive diagram** — the actual mechanism shown as something you can poke, scrub, or step through. Not a screenshotted figure.
- A **visual takeaway** — the one image or chart that captures what changed in the field because of this paper.
- A **map of where it fits** — Builds on / Led to / Adjacent, so the user can walk the citation graph by interest, not by alphabet.

A user who spends 60–90 seconds in a deck should know more about a paper's place in the field than they would after 5 minutes with the abstract.

---

## What Aprecis is not

- **Not a PDF reader.** We don't host papers; we link out.
- **Not a universal search engine.** We curate the AI/ML frontier on purpose.
- **Not an abstract summarizer.** A summary in the same register as the abstract solves nothing. Aprecis is a *rewrite* into a different format: visual, interactive, short.
- **Not an infinite feed.** Doom-scrolling research papers loses the plot. Aprecis is a one-paper-at-a-time experience; discovery happens through related rails, not a never-ending stack.
- **Not a social network.** No comments, no follows in v1. The signal is the work, not the discourse.

---

## Design principles

These flow directly from the vision. When in doubt, choose the option that honors more of them.

### 1. No jargon by default, jargon on tap

A reasonably curious 14-year-old should understand the hook of every paper. Anyone hungry for depth taps to expand: definitions, equations, original wording. Default surface is plain English; depth is a click away.

> Concretely: "the author trained an 8-layer CNN on two GPUs" is the kind of phrasing we never ship by default. "A deeper image network that halved the world's best error rate" is.

### 2. Show, don't summarize

Where a paper has a mechanism — an architecture, an algorithm, a curve, an attention pattern, a loss landscape — we show it as a small interactive thing, not a sentence describing it. **A working diagram beats a paragraph of description.**

### 3. One paper at a time

The user is never lost. The Focus view shows the paper they're on, the trail of where they came from, and the related rails that lead onward. No infinite scroll, no parallel context.

### 4. No option paralysis

The entry surface is one search bar plus a Surprise-me dice. We do not present 4 buttons of "Trending / Foundational / Frontier / Random" and ask the user to pick a mood. Pick the next paper by typing what you want, or roll for it.

### 5. Author names belong in citations, not descriptions

A description tells you what the work *does*. The citation tells you who did it. Mixing the two ("Krizhevsky, Sutskever, and Hinton trained...") taxes the reader without informing them. Authors go in the `sourceLine`. Descriptions go in `heroBody` / `summary`.

### 6. The app rewards exploration, not consumption

Every card should make the user want to tap the next one or jump to the paper it builds on. We measure depth of exploration, not minutes spent.

### 7. The canon is shared, the path is personal

Every user can find AlexNet, Attention, BERT, GPT-3 — the canon doesn't fragment by feed. Personalization shapes *the order* and *the surfacing*, never *the availability*.

---

## The abstract-replacement walkthrough

To make the vision concrete, here is what Aprecis does that an abstract does not.

| Stage | Abstract | Aprecis card deck |
|---|---|---|
| First impression | Three to five dense sentences in academic register. | One hook sentence in plain English + a cluster tag (Vision / Language / etc.) |
| What the paper does | Hidden inside a thicket of contribution language ("we propose…, we show…"). | A `core_idea` card stating the mechanism in one paragraph with no name-drops. |
| Why it matters | Buried in the last sentence, often as a claim. | A `takeaway` card showing the *change* — before/after metric, a one-image visual, or a single quantitative comparison. |
| Mechanism | A name or acronym ("self-attention", "denoising diffusion") expected to be looked up elsewhere. | An interactive diagram on the visual card — tokens you can click, weights you can scrub, an architecture you can step through. |
| Place in the field | Reference list at the bottom. | Builds on / Led to / Adjacent rails — three taps to walk to the predecessor, the descendant, or the sibling. |
| Decision support | Reader must hold all the above in their head simultaneously. | The deck IS the decision: by the takeaway card, the user knows whether to open the paper. |

The success criterion: **a user reading abstracts at 1 paper / minute can do the same triage on Aprecis at 4–6 papers / minute, with better recall a day later.**

---

## How we measure success

These are the metrics that matter, in priority order:

1. **Time-to-understand.** How long until a user can describe a paper they didn't know in their own words. Self-reported and observed via deck completion + concept retention.
2. **Discovery breadth.** Distinct papers touched per session. We want users walking the graph, not getting stuck on one.
3. **Return.** Users come back to *find* their next paper, not just to consume content. (DAU is downstream of this; don't optimize it directly.)
4. **Convert.** Users actually save papers, open the source PDF, or cite the paper in their own work. The end of an Aprecis session should be the *start* of real engagement with research, not a dead end.

---

## Anti-goals

We will say no to:

- Long-form text walls.
- Reproducing the abstract verbatim "for completeness."
- Becoming another arXiv mirror or a search wrapper.
- Personalization that fragments the canon — every user should be able to find AlexNet, regardless of their reading history.
- Engagement loops that exist for retention, not for learning. No infinite feed, no streak guilt, no "you're missing out" prompts.
- "AI chat with this paper" as the primary interaction. Chat is fine as a depth tool; it is not what makes Aprecis different.

---

## Where we are today (2026-05-13)

| Vision principle | Status in the product |
|---|---|
| Plain-language descriptions | Shipped. `heroBody` / `summary` rewritten to drop author names + jargon (2026-05-13). |
| Interactive diagrams | Partial. Several foundational papers (AlexNet, Word2Vec, Backprop, LeNet, Attention) have hand-crafted studios; most newly-ingested papers still get static visuals from the LLM pipeline. **Biggest open lever.** |
| One paper at a time | Shipped. Focus view + back-only swipe + breadcrumb. |
| No option paralysis | Shipped. Single search + Surprise-me dice. |
| Builds on / Led to / Adjacent | Shipped. Segmented tab control on Focus view. |
| Hub tabs | Reduced to Discover + Profile (2026-05-13). Home and Bundles hidden until the Discover (search / braces) experience is the front door we want. |
| Author names in `sourceLine` only | Shipped for foundational papers; need to enforce in the LLM pipeline output for newly-ingested ones. |

---

## What this implies for the next stretch

In rough priority order — these are the workstreams that move us toward the vision fastest:

1. **Interactive diagrams as a first-class output of the LLM pipeline.** Today, custom studios are hand-crafted per paper. The vision demands that every paper get *some* interactive treatment automatically. Likely path: extend the visual DSL so the pipeline can emit "minimum viable interactivity" (scrubbable attention heatmap, before/after metric slider, architecture step-through) for any paper that fits one of N templates.
2. **Pipeline-level enforcement of the no-jargon, no-author-names contract.** Add a post-processing step that flags author surnames in `heroBody` / `summary` and rewrites them. Same for top jargon terms ("CNN", "LSTM", "softmax") without an inline gloss.
3. **A real "abstract → card deck" conversion view.** A tool that lets the user paste an arXiv URL and watch the deck assemble in real time. This is both a debug surface and a marketing demo: it makes the value visible in 10 seconds.
4. **Builds on / Led to graph coverage.** Today's `RelatedPapers.bundle` is hand-curated for the foundational set. To make discovery feel limitless, the graph needs to grow with every ingested paper — either from citation data or from concept overlap.
5. **Conversion measurement.** Wire `markInteraction` to capture "opened source paper" and "saved" events, surface them in a private dashboard. We cannot improve what we don't see.

Anything we ship that doesn't move at least one of these forward should be questioned.

---

## Braces and duplicate rows

**Brace** — the product name for **one distilled work** users see as a deck in Aprecis (not “yet another listing for the same arXiv preprint”). Prefer *brace* in copy and prompts to Juno/Code when talking about entities in the corpus.

Duplicates happen when:

- The same arXiv work is stored under different `paper_id`s (for example `arxiv:2401.00000`, `twitter:…` with an arXiv link, `hn:…` with the same link).
- Rarely when the same ingest runs twice — only if the backend allows two rows past the uniqueness of `papers.paper_id`.

**Shipped.** The iOS app merges rows that share the same canonical arXiv id (derived from `paper_id` prefixes and from `cards.url` when decoded). Across a collision we keep the “richer” `CardDeck` (more concepts, score, prefers `arxiv:` id over aggregator ids). Implemented in `ios/MicrolearningApp/Models/Models.swift` (`BraceIdentity` + `mergingCanonicalBraceDuplicates`) and applied after feed merges and combined search corpora (`SearchView.allDecks`, `HomeView.previewPapers`).

**To delete redundant rows permanently in the backend:** keep one row per canonical work in Postgres (or add a nullable `canonical_work_id`/`arxiv_id_normalized` column, backfill unique values, dedupe FK children, drop extras). Optionally enforce `unique` on normalized arXiv in `cron-ingest` before insert. Until that migration runs, UI merge keeps the corpus clean client-side only.

---

## Glossary

- **Brace** — one distilled work in Aprecis (canonical unit of browsing). Prefer this term over “paper” when ambiguity matters.
- **Deck** — the six-card sequence for one brace: hook → core idea → ELI5 → analogy → visual → takeaway.
- **Studio** — a hand-crafted SwiftUI view that renders a paper's mechanism interactively (e.g. `AlexNetStudioViews.swift`).
- **Focus view** — the Explore-tab UI showing one paper at a time with its related rails.
- **Rail** — Builds on / Led to / Adjacent — the three relationship lists between papers.
- **Cluster** — a topical grouping (Vision / Language / Reasoning / Alignment / …). Used for accent color and the cluster chip.

---

## Change log

- 2026-05-14 — **Brace** vocabulary established; glossary + brace dedupe (canonical arXiv) documented; client merges duplicate braces in feed + Explore corpus.
- 2026-05-13 — Vision codified by Claude from Juno's stated pain point. Captured current state, principles, and anti-goals.
