# Lesson Flow: the gold standard

Every curated paper lesson follows the same pedagogical contract. BERT
(`BERTLesson.swift`) is the reference implementation.

## The one rule

**No card introduces a term or mechanism before an earlier card has given
the reader a reason to need it.** Every "how" is preceded by a "why". The
reader should never meet a piece of jargon cold (the old failure: Attention
naming `query`/`key`/`value` before the reader knew why a word would ask or
answer anything).

## The ladder

Order cards as a single conceptual climb, not a topic dump:

1. **Hook**: a thing the reader already does. No AI words. Build one small
   moment of "huh, I do that".
2. **The human insight**: name *how* they did it. This is the concept the
   paper mechanises.
3. **The old gap**: what computers couldn't do before, framed as the
   problem this paper exists to solve. This earns the solution.
4. **The fix**: what the paper actually does, introduced as the answer to
   the gap above. Define the first terms here, inline, at point of need.
5. **The mechanism**: only now, the inner workings. Each new moving part
   gets a one-sentence bridge from what the reader already accepted.
6. **The payoff**: train once then reuse, scale, why anyone cares.
7. **Everyday**: where the reader has already met it.
8. **Recap**: three lines, plain.
9. **Source**: quote plus paper link.

Interactives go immediately after the card that motivates them, so the
reader plays with an idea they were just handed, never one they have to
guess at.

## Definitions: inline, at point of need

Do not front-load a glossary card of words the reader hasn't met. Define
each term in prose the first time it appears (`.term(...)` run), and make it
tappable by registering it in `FoundationalGlossaries` under the paper slug.
The tap surfaces the formal definition; the prose carries the plain one.

A standalone glossary card is allowed only as a *consolidation* near the end,
after every term in it has already appeared in the flow.

## Bridges, not jumps

When a card escalates from a specific case to a general mechanism (e.g. "fill
the one blank" -> "every word reads every other word"), open it with one
sentence that ties back to what the reader just accepted. That sentence is
the whole difference between scaffolding and a cold jump.

## Voice

Plain, concrete, one idea per card. No em or en dashes. No redundant copy:
titles must not echo the kicker or restate the body. No throat-clearing
intros. Numbers and nouns over adjectives.
