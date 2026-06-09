# Research: Displaying a Distilled Paper on aprecis.app

Scope: what the web page should show after a user pastes a research-paper link, so they
(a) learn the paper well, (b) feel Aprecis did real distillation work, (c) come back.

Status: research only. Implementation is a separate, later task.

---

## 1. The job to be done

When a user pastes a link, they are in one of three intents:

1. **Triage** — "Is this paper worth my time? What is it actually about?" (most common)
2. **Understand** — "I will use this; explain it so I get it without reading 12 pages."
3. **Recall** — "I read this before; remind me / let me lock it in."

A single linear summary serves intent 1 weakly and intents 2-3 badly. The page must be
**layered**: a fast top layer that resolves triage in ~15 seconds, then deeper layers
the user opts into. This maps directly onto how expert readers already work.

### How experts read papers: the three-pass method (Keshav, 2007)

- **Pass 1 (5-10 min):** title, abstract, intro, headings, conclusion. Decide relevance.
- **Pass 2:** read figures and arguments, ignore proofs. Grasp the content.
- **Pass 3:** reconstruct the work mentally; find assumptions and gaps.

The product insight: do not invent a new mental model. **Mirror the three-pass method in
the page layout.** The page is a compressed, guided version of the passes the reader
would do anyway. That framing is itself the perceived-value story: "Aprecis did pass 1
and 2 for you in 10 seconds."

Sources: [Keshav three-pass](https://blog-sc.hku.hk/reading-papers-efficiently-with-the-three-pass-approach/), [three-pass guide](https://richardmathewsii.substack.com/p/three-pass-research-literature-review)

---

## 2. Learning-science principles that should drive the design

### 2.1 Cognitive load theory (Sweller)

Three load types: **intrinsic** (the paper's real difficulty), **germane** (effort that
builds understanding — good), **extraneous** (effort wasted on bad layout — kill it).

- A research paper is high intrinsic load. The page's only job is to **cut extraneous
  load and convert effort into germane load.**
- Working memory holds ~4 chunks. Never show more than a handful of new ideas on one
  screen. Chunk aggressively.
- This is the scientific justification for the existing 6-card structure and for
  one-concept-per-screen.

### 2.2 Progressive disclosure (Nielsen, 1995)

Show essentials first; reveal complexity on demand. It is the primary tool for cutting
extraneous load. Three flavors, all useful here:

- **Step-by-step** — the deck/scroll sequence (hook → ... → takeaway).
- **Conditional** — "show the math", "read the original passage", "see the methods" stay
  collapsed until requested.
- **Contextual** — tap a jargon term to expand its definition inline.

Rule: the first viewport must be understandable with **zero interaction**. Everything
deeper is opt-in.

Sources: [progressive disclosure (UXPin)](https://www.uxpin.com/studio/blog/what-is-progressive-disclosure/), [cognitive load in UX](https://www.aufaitux.com/blog/cognitive-load-theory-ui-design/)

### 2.3 Dual coding / multimedia learning (Paivio, Mayer)

Words + matching visuals are processed in two channels and remembered far better than
words alone (Mayer reports up to ~89% test-score gains for well-designed multimedia).
Key sub-principles to obey:

- **Multimedia principle:** pair every core idea with a visual, not just prose.
- **Contiguity principle:** put the visual *next to* its text, on the same screen, at the
  same time — never "diagram below, caption far away".
- **Coherence principle:** strip decorative imagery. Every visual must carry information.
  A pretty but empty graphic *adds* extraneous load.

Implication: the existing per-concept `VisualSchema` / diagram is not garnish — it is a
load-bearing learning device. The web display should treat the diagram as co-equal with
the text, not as an afterthought.

Sources: [Mayer's 12 principles](https://www.digitallearninginstitute.com/blog/mayers-principles-multimedia-learning), [dual coding guide](https://www.structural-learning.com/post/dual-coding-a-teachers-guide)

### 2.4 The curiosity / information-gap effect (Loewenstein)

Curiosity is "deprivation from a perceived gap in knowledge." It fires hardest in the
**Goldilocks zone**: the user has *some* context and sees a specific hole.

Design moves:

- The **hook** should open a gap, not summarize. "Transformers dropped recurrence
  entirely — and got faster *and* better. Here is the trick." A gap, not a verdict.
- Between layers, **tease the next layer**: name what is behind the fold before the user
  opens it ("3 assumptions this result depends on →").
- Frame deeper content as a question the user can try to answer before revealing it.

Sources: [information-gap theory](https://www.cmu.edu/dietrich/sds/docs/golman/golman_loewenstein_curiosity.pdf), [curiosity & memory](https://par.nsf.gov/servlets/purl/10062657)

### 2.5 Generation & self-explanation effect

People remember what they **produce** far better than what they **read**. A predicted
answer — even a wrong one — primes curiosity and boosts retention of the real answer.

Design moves (cheap, high impact):

- Before revealing a key result, show a one-tap prediction prompt: "Will adding more
  attention heads help? [Yes] [No] [Plateaus]". Then reveal.
- Optional "explain it back" field on the takeaway card.
- These convert a passive read into an active one — the single biggest retention lever
  and a strong differentiator vs. plain summarizers.

Sources: [prediction stimulates curiosity](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6803639/)

### 2.6 Spacing & retrieval practice

Distributed retrieval beats massed reading for long-term retention. Microlearning sessions
of ~8-12 min are near-optimal for working memory and attention.

Web-page implications (the web is a weaker spacing surface than the app, but still):

- End every distilled paper with a **save / "review later"** action that feeds a spaced
  queue (and is the natural bridge to the iOS app).
- Offer 2-3 **retrieval questions** at the end — low-stakes, self-graded. This is also a
  perceived-value signal: a summarizer that *quizzes* you feels like it taught you.
- The recall queue is the retention-and-retention(user) flywheel. The web page should
  plant it even if full spacing lives in the app.

Sources: [spaced repetition & retrieval](https://journals.zeuspress.org/index.php/IJASSR/article/view/425), [microlearning retention](https://www.eduresearchjournal.com/index.php/ijep/article/download/270/279/660)

---

## 3. Competitive landscape — what exists, where the gaps are

| Tool | What it does | Weakness Aprecis can exploit |
|---|---|---|
| **Scholarcy** | Section-based summary "flashcards": background, methods, findings, citations | Structured but dry; mirrors paper sections, not human curiosity. No simplification, no visuals, no retention loop. |
| **SciSpace** | Q&A over the paper; explains terms/claims on demand | Reactive — user must know what to ask. No guided narrative. Good model for the "ask" layer, weak as a default view. |
| **Elicit** | Cross-paper extraction, systematic-review screening | Multi-paper tool, not a single-paper *understanding* tool. Different job. |
| **explainpaper** | Click a confusing paragraph → plain-language explanation | Still anchored to reading the original PDF top-to-bottom. No distillation of the whole. |

**The open gap:** every competitor either (a) reproduces the paper's structure, or (b)
waits for the user to ask. None delivers a **guided, curiosity-driven, visual narrative**
that takes a non-expert from zero to "I get it" without reading the PDF. That is exactly
Aprecis's card model (hook → core_idea → eli5 → analogy → visual → takeaway). The web page
should lead with that narrative — it is the moat. Do not regress toward a section-by-
section summary to look "serious."

Sources: [AI summarizer comparison](https://paperguide.ai/blog/ai-research-paper-summarizers/), [Elicit vs SciSpace](https://paperguide.ai/blog/elicit-vs-scispace/)

---

## 4. Trust & perceived value — why the user believes Aprecis distilled something real

Research on AI summaries: perceived credibility is driven by **algorithmic transparency,
understandability, and verifiability**, and credibility → perceived helpfulness →
adoption. Known failure mode: AI summaries drift from the source and compound bias.

So the page must constantly **anchor to the original** and **show its work**:

1. **Source provenance, always visible** — paper title, authors, venue, date, arXiv ID,
   link to PDF. Cheap, and it signals "this is grounded, not hallucinated."
2. **Traceable claims** — each distilled claim links back to the section/figure/quote it
   came from. "Tap to see the original passage" turns a summary into a *verifiable* one.
   This is the single strongest trust lever and most competitors skip it.
3. **Show the transformation, not just the output** — a one-line "12 pages → 6 cards →
   ~4 min" or a visible pipeline stamp. Users value distillation they can *see happened*.
4. **Calibrated confidence** — mark anything inferred/uncertain. Honest hedging raises
   trust more than false crispness.
5. **Visible structure of effort** — extracted key terms, the concept graph, "what's
   novel vs. background" labels. Each is an artifact that proves analysis occurred.

Perceived value heuristic: the user should feel Aprecis **read it so they didn't have
to**, AND **could check it if they wanted to**. Both halves matter.

Sources: [credibility of AI summaries](https://www.sciencedirect.com/science/article/abs/pii/S0306457325003450), [transparency & trust](https://www.tandfonline.com/doi/full/10.1080/0144929X.2025.2533358), [AI summary citation bias](https://arxiv.org/pdf/2511.22809)

---

## 5. Recommended display model — the layered paper page

A vertical, scroll-or-swipe page in **four layers**. Each layer = one pass. The user can
stop at any layer and feel complete.

### Layer 0 — Identity strip (instant, ~2s)
Title, authors, venue/date, arXiv link, a 1-line "what field / what kind of paper" tag,
and the distillation stamp ("~4 min read · 6 concepts · distilled from 14 pages").
Purpose: provenance + trust + set expectations.

### Layer 1 — The Hook + TL;DR (the triage layer, ~15s)
- One **curiosity-gap hook** sentence (opens a gap, see 2.4).
- A 2-3 sentence **plain-language TL;DR** (the `summary` field) — what the paper claims
  and why it matters.
- The **"so what"** — one line on impact / who should care.
- This layer alone must fully serve intent 1 (triage). Everything below is opt-in.

### Layer 2 — The concept narrative (the understand layer, ~3-4 min)
The core of the page. The `concepts[]` array, one concept per screen/section:
- A short headline (the chunk).
- ELI5 explanation + an analogy.
- The paired **diagram** (dual coding — visual beside text, same screen).
- Collapsed "go deeper" affordances: original passage, the math, methods detail.
- A prediction prompt before the key result of the concept (generation effect).
Concepts flow as a narrative (problem → idea → mechanism → result → implication), not as
paper sections. Tease the next concept at the bottom of each.

### Layer 3 — Anchor & verify (the trust layer, on demand)
- Concept graph / how this paper relates to others (the `graph` stage already exists).
- Key terms glossary (tap-to-expand, contextual disclosure).
- Claim-to-source mapping: every claim → its figure/quote in the PDF.
- "Limitations / what's uncertain" — honest section.

### Layer 4 — Lock it in & return (the retention layer)
- 2-3 **retrieval questions**, self-graded.
- **Save to recall queue** → spaced review (bridge to the iOS app; primary return hook).
- "Next paper" / related-paper suggestion to continue the session.
- Optional "explain it back" capture.

### Why this ordering works
- Matches three-pass reading → feels natural, not novel UI to learn.
- Progressive disclosure → first viewport is zero-interaction comprehensible.
- Each layer is a complete stopping point → no user leaves empty-handed.
- Curiosity teases pull the user *down*; retention layer pulls them *back*.

---

## 6. Anti-patterns to avoid

- **The wall of summary.** One long AI paragraph. High extraneous load, looks
  un-distilled, indistinguishable from ChatGPT. The layering is the product.
- **Section-mirroring.** Abstract/Methods/Results headings. Reproduces the paper's
  structure instead of a human learning path. That is Scholarcy's ceiling.
- **Decorative visuals.** Stock-art graphics violate the coherence principle and *add*
  load. Every visual must teach.
- **Hooks that spoil.** A hook that states the conclusion kills the curiosity gap. Open
  the loop; let Layer 1-2 close it.
- **Disconnected text and images.** Diagram far from its prose breaks contiguity.
- **No path back.** A page that ends at "the end" wastes the retention opportunity and
  the funnel into the app.
- **Front-loading depth.** Math/methods visible by default → triage users bounce.
- **Unanchored claims.** No link to source → reads as possibly-hallucinated → low trust.

---

## 7. Suggested success metrics

- **Triage success:** % sessions that read Layer 1 fully (scroll/time proxy).
- **Depth:** distribution of deepest layer reached; median concepts viewed.
- **Active engagement:** prediction-prompt and retrieval-question interaction rate.
- **Trust signal:** "view original passage" / PDF-link click rate.
- **Retention/return:** save-to-recall rate; D1/D7 return; web→app conversion.
- **Perceived value (qual):** post-read 1-tap "did this save you time? / do you get the
  paper?" micro-survey.

---

## 8. One-paragraph summary for implementation

After a link is pasted, render a four-layer page that mirrors how experts read papers:
an identity/provenance strip; a curiosity-gap hook + plain TL;DR that resolves triage in
~15s; a one-concept-per-screen visual narrative (ELI5 + analogy + paired diagram, with
depth collapsed behind progressive disclosure and a prediction prompt before each key
result); a verify layer that anchors every claim back to the source PDF; and a retention
layer with retrieval questions and a save-to-spaced-review action that bridges to the
iOS app. The design is governed by cognitive load theory (chunk, cut extraneous load),
dual coding (visual beside text), the curiosity gap (hooks open loops, layers tease),
the generation effect (predict before reveal), and trust research (provenance + traceable
claims always visible). The moat is the guided curiosity-driven narrative — competitors
either mirror paper sections or wait to be asked; none guide a non-expert from zero to
understanding. Do not regress toward a flat summary to look serious.
