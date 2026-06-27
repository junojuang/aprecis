import SwiftUI

// MARK: - Attention lesson (gold-standard flow)
//
// The Transformer. Ladder (see LESSON_FLOW_GUIDE.md): you already glance
// back across a sentence to resolve a pronoun -> the old telephone-line way
// blurred -> attention lets every word read every other word -> only THEN,
// once the reader asks "but how does a word find the right word?", do we
// name query / key / value as the answer. The standalone glossary card is
// gone; query/key/value/attention-weight are defined inline at point of
// need and resolve to a tap via FoundationalGlossaries.transformer.

extension LearningLesson {

    static let attention = LearningLesson(
        paperId: "attention",
        cards: [

            // 1 — Editorial cover.
            .cover(
                id: "attention-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "The idea behind every chatbot.",
                highlight: "every chatbot",
                standfirst: "2017. Eight researchers threw out the old way of reading and started the modern AI era.",
                hero: AttentionWebGlyph()
            ),

            // 2 — HOOK. You already do the thing. No jargon.
            .prose(
                id: "attention-hook",
                kicker: "Start here",
                title: "Your brain just did the thing",
                paragraphs: [
                    [.plain("Read this: "),
                     .bold("\u{201C}The cat sat on the mat because it was tired.\u{201D}")],
                    [.plain("What does "),
                     .bold("it"),
                     .plain(" mean? The cat, obviously. You knew instantly.")],
                    [.plain("But notice the work you did. To be sure "),
                     .bold("it"),
                     .plain(" meant the cat and not the mat, your brain "),
                     .highlight("glanced back across the sentence"),
                     .plain(" and weighed the options. That tiny glance is the whole paper.")],
                ]
            ),

            // 3 — THE INSIGHT. Name the glance: attention.
            .illustrated(
                id: "attention-idea",
                kicker: "The big idea",
                title: "Words that read each other",
                paragraphs: [
                    [.plain("That glance back, letting one word reach across to another, is called "),
                     .term("attention"),
                     .plain(". It is how "),
                     .bold("it"),
                     .plain(" found the cat.")],
                    [.plain("The Transformer gives "),
                     .highlight("every word"),
                     .plain(" that same power at once: each one looks across the whole sentence and pulls in whatever it needs to make sense here.")],
                    [.plain("No reading strictly left to right. No waiting. Every word reads every other word, all at the same time.")],
                ],
                caption: "The word \u{201C}it\u{201D} reaches back to \u{201C}cat.\u{201D}",
                illustration: AttentionArcArt()
            ),

            // 4 — THE OLD GAP. Why this was needed. Telephone analogy.
            .prose(
                id: "attention-oldway",
                kicker: "The old problem",
                title: "A game of telephone",
                paragraphs: [
                    [.plain("Before 2017, a language network read one word at a time and passed a single running memory forward, "),
                     .term("like a game of telephone"),
                     .plain(".")],
                    [.plain("Two problems. The message "),
                     .bold("blurs"),
                     .plain(" by the end of a long sentence, so words far apart can barely reach each other. And every word has to wait its turn, so the work can\u{2019}t be split across many computers.")],
                    [.plain("Attention fixes both at once: every word talks to every other word directly, "),
                     .highlight("all in parallel"),
                     .plain(". No blur, no waiting.")],
                ],
                hero: AnyView(TelephoneChainArt().frame(height: 124))
            ),

            // 5 — Feel the glance: drive attention.
            .interactive(id: "attention-selfattn") { progress in
                SelfAttentionPlayground(cardId: "attention-selfattn", progress: progress)
            },

            // 6 — BRIDGE (new scaffolding). Pose the question the QKV card
            //     answers, so the three roles arrive as a need, not a decree.
            .prose(
                id: "attention-matchmaking",
                kicker: "The question underneath",
                title: "How does a word find the right one?",
                paragraphs: [
                    [.plain("You just watched the links light up. But something had to "),
                     .highlight("decide"),
                     .plain(" them. When "),
                     .bold("it"),
                     .plain(" glances back, what makes "),
                     .bold("cat"),
                     .plain(" light up and "),
                     .bold("mat"),
                     .plain(" stay quiet?")],
                    [.plain("Picture a room full of people. One word calls out what it is after: \u{201C}I need the thing this sentence is about.\u{201D} Every other word answers with a short label of what it is. The labels that "),
                     .term("match"),
                     .plain(" get the loudest reply.")],
                    [.plain("So each word plays two parts at once: it "),
                     .bold("asks"),
                     .plain(" for what it wants, and it "),
                     .bold("advertises"),
                     .plain(" what it offers. Hold that picture, it is the whole machine.")],
                ]
            ),

            // 7 — THE MECHANISM. Now name the three roles, as the answer.
            .illustrated(
                id: "attention-qkv",
                kicker: "Three roles per word",
                title: "Ask, advertise, give",
                paragraphs: [
                    [.plain("Those parts have names. The question a word asks is its "),
                     .term("query"),
                     .plain(". The label it holds up in answer is its "),
                     .term("key"),
                     .plain(". And what it actually hands over once matched is its "),
                     .term("value"),
                     .plain(".")],
                    [.plain("A word\u{2019}s query is compared against every other word\u{2019}s key. A strong match means a loud voice. The word then "),
                     .highlight("collects a blend of the values"),
                     .plain(", weighted by those matches.")],
                    [.plain("That blend becomes the word\u{2019}s new meaning, in context. How loudly one word answers another is its "),
                     .term("attention weight"),
                     .plain(".")],
                ],
                caption: "One word, split into a question, a label, and a note.",
                illustration: QKVTriadArt()
            ),

            // 8 — Drive the match.
            .interactive(id: "attention-match") { progress in
                AttentionMatchPlayground(cardId: "attention-match", progress: progress)
            },

            // 9 — Many heads. Builds on one round of matching.
            .illustrated(
                id: "attention-multihead",
                kicker: "Many heads at once",
                title: "Ask many questions in parallel",
                paragraphs: [
                    [.plain("One round of asking and matching captures one kind of link. But a sentence holds many at once: grammar, meaning, who-did-what-to-whom.")],
                    [.plain("So the Transformer runs attention "),
                     .term("eight times in parallel"),
                     .plain(", each copy a "),
                     .term("head"),
                     .plain(" asking its own kind of question. One head tracks grammar, another meaning, another word order.")],
                    [.plain("Their answers get "),
                     .highlight("joined back together"),
                     .plain(" into one richer picture per word.")],
                ],
                caption: "Three of the eight heads, each chasing a different pattern.",
                illustration: MultiHeadStrip()
            ),

            // 10 — Drive the heads.
            .interactive(id: "attention-heads") { progress in
                AttentionHeadsPlayground(cardId: "attention-heads", progress: progress)
            },

            // 11 — THE PAYOFF. Why it took over.
            .prose(
                id: "attention-won",
                kicker: "Why it took over",
                title: "Attention scales. Memory didn\u{2019}t.",
                paragraphs: [
                    [.plain("Because every word is handled at once, a Transformer can drive a whole rack of chips at full tilt. The 2017 paper trained in "),
                     .highlight("three and a half days"),
                     .plain(" and beat models that had taken weeks.")],
                    [.plain("And it kept getting better the more data and chips you fed it. That one property, "),
                     .bold("it scales"),
                     .plain(", set off the race.")],
                    [.plain("A year later: BERT and GPT. Then GPT-3. Then ChatGPT. Every one is this same architecture, grown larger. "),
                     .highlight("The model behind everything you call \u{201C}AI\u{201D} runs on this."),
                     .plain("")],
                ],
                hero: AnyView(TransformerLineage())
            ),

            // 12 — Where you've met it.
            .prose(
                id: "attention-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s in every chatbot you\u{2019}ve used",
                paragraphs: [
                    [.plain("Open "),
                     .bold("ChatGPT"),
                     .plain(", "),
                     .bold("Claude"),
                     .plain(", "),
                     .bold("Gemini"),
                     .plain(", "),
                     .bold("Copilot"),
                     .plain(". All of them are the Transformer from this paper, just grown unimaginably big.")],
                    [.plain("Same trick. Every word looks at every other word, all at once. "),
                     .highlight("That\u{2019}s the whole modern AI era in one sentence."),
                     .plain("")],
                ]
            ),

            // 13 — Recap.
            .recap(
                id: "attention-recap",
                title: "Attention, in three lines",
                points: [
                    "Old language networks passed a memory forward word by word, like telephone. The message blurred on long sentences and the work couldn\u{2019}t be parallelised.",
                    "Attention lets every word read every other word directly, all at once. Each word asks a question (query), every other word answers with a label (key) and a contribution (value).",
                    "Run that many times in parallel and you have the Transformer, the architecture behind ChatGPT, Claude, Gemini, and every modern AI you have used.",
                ]
            ),

            // 14 — Closing.
            .paperLink(
                id: "attention-source",
                quote: "Attention is all you need.",
                attribution: "Vaswani, Shazeer, Parmar et al. \u{00B7} NeurIPS \u{00B7} 2017",
                linkTitle: "Attention Is All You Need \u{00B7} Vaswani et al., 2017",
                url: URL(string: "https://arxiv.org/abs/1706.03762")
            ),
        ]
    )
}
