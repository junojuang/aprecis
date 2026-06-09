import SwiftUI

// MARK: - Attention lesson (beginner-first redesign)
//
// The Transformer. Beginner arc: you do this every time you read a pronoun
// and link it to the right noun. Two formula cards (scaled dot-product,
// positional encoding) and the code card removed. The four bespoke
// interactives (self-attention, match, heads, plus the existing
// illustrations) are kept.

extension LearningLesson {

    static let attention = LearningLesson(
        paperId: "loop:foundational:attention",
        cards: [

            // Editorial cover.
            .cover(
                id: "attention-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "The idea behind every chatbot.",
                highlight: "every chatbot",
                standfirst: "2017. Eight researchers threw out the old way of reading and started the modern AI era.",
                hero: AttentionWebGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "attention-hook",
                kicker: "Start here",
                title: "Your brain just did the thing",
                paragraphs: [
                    [.plain("Read this: "),
                     .bold("\u{201C}The cat sat on the mat because it was tired.\u{201D}"),
                     .plain("")],
                    [.plain("What does "),
                     .bold("it"),
                     .plain(" mean? The cat, obviously. You knew it instantly.")],
                    [.plain("To figure that out, your brain just "),
                     .highlight("glanced back across the sentence"),
                     .plain(", checked which noun \u{201C}it\u{201D} could mean, and decided. That tiny glance is what this paper is about.")],
                ]
            ),

            // The big idea.
            .illustrated(
                id: "attention-idea",
                kicker: "The big idea",
                title: "Words that read each other",
                paragraphs: [
                    [.plain("Read \u{201C}the cat sat as it dozed.\u{201D} The word "),
                     .bold("it"),
                     .plain(" means the cat. You knew at once, because you let "),
                     .bold("it"),
                     .plain(" "),
                     .highlight("glance back"),
                     .plain(" across the sentence.")],
                    [.plain("That glance is called "),
                     .term("attention"),
                     .plain(". A Transformer gives every word the same power: each one looks at every other word at the same time and pulls in whatever it needs.")],
                    [.plain("No reading left to right. No waiting. All at once.")],
                ],
                caption: "The word \u{201C}it\u{201D} reaches back to \u{201C}cat.\u{201D}",
                illustration: AttentionArcArt()
            ),

            // The old way.
            .prose(
                id: "attention-oldway",
                kicker: "The old way",
                title: "A game of telephone",
                paragraphs: [
                    [.plain("Before 2017, a language network read one word at a time and passed a single memory forward, "),
                     .term("like a game of telephone"),
                     .plain(".")],
                    [.plain("Two problems. The message "),
                     .bold("blurs"),
                     .plain(" by the end of a long sentence, so words far apart can barely reach each other. And every word has to wait its turn, so the work can\u{2019}t be split across many computers.")],
                    [.plain("Attention fixes both at once: every word talks to every other word directly, "),
                     .highlight("all in parallel"),
                     .plain(".")],
                ],
                hero: AnyView(TelephoneChainArt().frame(height: 124))
            ),

            // Drive attention.
            .interactive(id: "attention-selfattn") { progress in
                SelfAttentionPlayground(cardId: "attention-selfattn", progress: progress)
            },

            // Trimmed glossary.
            .glossary(
                id: "attention-glossary",
                intro: "Five words. Three of them are roles each word plays inside attention.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Token",
                        definition: "One piece of text the model handles. Usually a word or part of a word."),
                    LessonGlossaryTerm(
                        term: "Query",
                        definition: "What a word is looking for. The question it asks the rest of the sentence."),
                    LessonGlossaryTerm(
                        term: "Key",
                        definition: "What a word advertises about itself. The label other words match their questions against."),
                    LessonGlossaryTerm(
                        term: "Value",
                        definition: "What a word actually shares when another word reaches out to it. Its real contribution."),
                    LessonGlossaryTerm(
                        term: "Attention weight",
                        definition: "How much one word listens to another. A set of numbers for each word that always adds up to one."),
                ]
            ),

            // Q/K/V illustrated.
            .illustrated(
                id: "attention-qkv",
                kicker: "Three roles per word",
                title: "Every word asks, offers, and gives",
                paragraphs: [
                    [.plain("To attend, each word splits itself into three parts.")],
                    [.plain("A "),
                     .term("query"),
                     .plain(" is the question it asks the room. A "),
                     .term("key"),
                     .plain(" is the label it holds up in answer. A "),
                     .term("value"),
                     .plain(" is what it actually shares.")],
                    [.plain("A word\u{2019}s query is compared against every other word\u{2019}s key. A strong match means a loud voice. The word then "),
                     .highlight("collects a blend of the values"),
                     .plain(", weighted by those matches. That blend becomes its new meaning, in context.")],
                ],
                caption: "One word, split into a question, a label, and a note.",
                illustration: QKVTriadArt()
            ),

            // Drive the match.
            .interactive(id: "attention-match") { progress in
                AttentionMatchPlayground(cardId: "attention-match", progress: progress)
            },

            // Many heads.
            .illustrated(
                id: "attention-multihead",
                kicker: "Many heads at once",
                title: "Ask many questions in parallel",
                paragraphs: [
                    [.plain("One round of attention captures one kind of link. But a sentence holds many at once: grammar, meaning, who-did-what-to-whom.")],
                    [.plain("So the Transformer runs attention "),
                     .term("eight times in parallel"),
                     .plain(". Each copy is called a "),
                     .term("head"),
                     .plain(". One head tracks grammar. Another tracks meaning. Another tracks word order.")],
                    [.plain("Their answers get "),
                     .highlight("joined back together"),
                     .plain(" into one richer picture per word.")],
                ],
                caption: "Three of the eight heads, each chasing a different pattern.",
                illustration: MultiHeadStrip()
            ),

            // Drive the heads.
            .interactive(id: "attention-heads") { progress in
                AttentionHeadsPlayground(cardId: "attention-heads", progress: progress)
            },

            // Why it took over.
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

            // Where you've met it.
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
                     .plain(". All of them. They\u{2019}re all the Transformer from this paper, just grown to be unimaginably big.")],
                    [.plain("Same trick. Every word looks at every other word, all at once. "),
                     .highlight("That\u{2019}s the whole modern AI era in one sentence."),
                     .plain("")],
                ]
            ),

            // Recap.
            .recap(
                id: "attention-recap",
                title: "Attention, in three lines",
                points: [
                    "Old language networks passed a memory forward word by word, like a game of telephone. The message blurred on long sentences and the work couldn\u{2019}t be parallelised.",
                    "Attention lets every word read every other word directly, all at once. Each word asks a question (query), every other word answers with a label (key) and a contribution (value).",
                    "Run that many times in parallel and you have the Transformer, the architecture behind ChatGPT, Claude, Gemini, and every modern AI you have used.",
                ]
            ),

            // Closing.
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
