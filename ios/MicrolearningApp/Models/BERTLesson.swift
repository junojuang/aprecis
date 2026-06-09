import SwiftUI

// MARK: - BERT lesson
//
// 2018, Devlin et al. Beginner-first redesign: a 14-year-old should walk in
// curious and walk out with a working mental model. We strip out anything
// scary (no formula card, no pseudocode, no benchmark names), lead with a
// relatable moment, hand over one idea per card, and use the same study
// buddy / fill-in-the-blank metaphor end to end.

extension LearningLesson {

    static let bert = LearningLesson(
        paperId: "loop:foundational:bert",
        cards: [

            // 1 — Editorial cover.
            .cover(
                id: "bert-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Read both sides at once.",
                highlight: "both sides",
                standfirst: "2018. A computer that taught itself language by playing fill-in-the-blank, billions of times.",
                hero: BERTGlyph()
            ),

            // 2 — The relatable hook. No AI words yet. Build a tiny moment of
            //     surprise: you already do the thing this paper is about.
            .prose(
                id: "bert-hook",
                kicker: "Start here",
                title: "You do this every day",
                paragraphs: [
                    [.plain("Read this slowly: "),
                     .bold("\"I poured ____ on my cereal.\""),
                     .plain(" You knew the word, didn\u{2019}t you? Probably "),
                     .term("milk"),
                     .plain(".")],
                    [.plain("Nobody told you. You just "),
                     .highlight("read the rest of the sentence"),
                     .plain(" and the missing word filled itself in.")],
                    [.plain("This whole paper is about a computer learning to do the same thing. That\u{2019}s it. That\u{2019}s the trick.")],
                ]
            ),

            // 3 — The big idea, in a picture.
            .illustrated(
                id: "bert-idea",
                kicker: "What BERT does",
                title: "It plays the fill-in-the-blank game",
                paragraphs: [
                    [.plain("Researchers gave BERT a simple game. Take any sentence. Cover one word. Guess what was there.")],
                    [.plain("Then they had it play that game "),
                     .highlight("billions of times"),
                     .plain(" using every sentence on Wikipedia.")],
                    [.plain("That\u{2019}s how it learned language. Not from a textbook. From practice.")],
                ],
                caption: "One word hidden. The rest of the sentence still showing.",
                illustration: ClozeArt()
            ),

            // 4 — Where it gets clever. The bidirectional move, told as
            //     something the reader already does.
            .prose(
                id: "bert-bothsides",
                kicker: "The clever part",
                title: "You used both sides",
                paragraphs: [
                    [.plain("Go back to "),
                     .bold("\"I poured ____ on my cereal.\""),
                     .plain(" Notice what your brain did.")],
                    [.plain("You read the words "),
                     .term("before"),
                     .plain(" the blank ("),
                     .highlight("I poured"),
                     .plain("). You also read the words "),
                     .term("after"),
                     .plain(" the blank ("),
                     .highlight("on my cereal"),
                     .plain("). Together they pointed to "),
                     .bold("milk"),
                     .plain(".")],
                    [.plain("Computers before BERT only read one direction. They\u{2019}d see "),
                     .bold("\"I poured ____\""),
                     .plain(" and guess wine, juice, anything. BERT looks both ways. That\u{2019}s why it\u{2019}s sharper.")],
                ],
                hero: AnyView(LeftOnlyStrip().frame(height: 90))
            ),

            // 5 — Try it yourself.
            .interactive(id: "bert-mask") { progress in
                MaskedTokenStudio(cardId: "bert-mask", progress: progress)
            },

            // 6 — Small in-context glossary. Four words, plainest possible.
            .glossary(
                id: "bert-glossary",
                intro: "Four words BERT-people use a lot. Worth knowing, easy to remember.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Token",
                        definition: "One little piece of a sentence. Usually one word, sometimes half of a long word. BERT reads sentences one token at a time."),
                    LessonGlossaryTerm(
                        term: "Mask",
                        definition: "A blank where a word used to be. During training, BERT covers up some tokens and has to guess them back."),
                    LessonGlossaryTerm(
                        term: "Pretrain",
                        definition: "The long, slow part: BERT plays fill-in-the-blank billions of times until it understands language in general."),
                    LessonGlossaryTerm(
                        term: "Fine-tune",
                        definition: "The short, easy part: now that BERT understands language, teach it one specific job (like spotting names) in just a few hours."),
                ]
            ),

            // 7 — Picture: every word listens to every other word.
            .illustrated(
                id: "bert-bidirectional",
                kicker: "How it actually reads",
                title: "Every word listens to every other word",
                paragraphs: [
                    [.plain("Inside BERT, each word in a sentence "),
                     .highlight("listens to every other word"),
                     .plain(" before deciding what it means here.")],
                    [.plain("Pick the word "),
                     .term("sat"),
                     .plain(". To work out what it means, BERT pays attention to "),
                     .bold("the cat"),
                     .plain(" before it AND "),
                     .bold("on the mat"),
                     .plain(" after it. All at the same time.")],
                ],
                caption: "One word in focus, with lines reaching to every other word.",
                illustration: BidirectionalGazeArt()
            ),

            // 8 — Drive the listening yourself.
            .interactive(id: "bert-gaze") { progress in
                BidirectionalGazeStudio(cardId: "bert-gaze", progress: progress)
            },

            // 9 — One brain, many jobs.
            .illustrated(
                id: "bert-pretrain",
                kicker: "Why people care",
                title: "Train once. Use everywhere.",
                paragraphs: [
                    [.plain("After all that fill-in-the-blank practice, BERT has built up a "),
                     .highlight("general understanding of English"),
                     .plain(". Like a person who has read a lot of books.")],
                    [.plain("To teach it a specific job, like spotting names in a paragraph, you don\u{2019}t start over. You keep the same brain and add a tiny "),
                     .term("job-shaped"),
                     .plain(" piece on top. A few hours of practice on the new job and it\u{2019}s ready.")],
                    [.plain("This is huge. One slow training run, then every team in the world can use the same brain for whatever job they have.")],
                ],
                caption: "Big shared brain on the bottom. Small job-shaped piece on top.",
                illustration: PretrainFinetuneArt()
            ),

            // 10 — Try three different jobs on the same brain.
            .interactive(id: "bert-finetune") { progress in
                PretrainFinetuneStudio(cardId: "bert-finetune", progress: progress)
            },

            // 11 — Where the reader has already met BERT. Concrete, modern,
            //     no benchmark talk.
            .prose(
                id: "bert-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s already in your pocket",
                paragraphs: [
                    [.plain("BERT (and BERTs cousins) are quietly running in things you use every day.")],
                    [.plain("When you "),
                     .bold("Google something"),
                     .plain(" and the results understand what you meant, even with a typo or a weird wording, BERT is part of that.")],
                    [.plain("When your phone "),
                     .bold("autocompletes"),
                     .plain(" a tricky sentence, or your email guesses the "),
                     .term("Reply"),
                     .plain(" button text, you\u{2019}re leaning on a BERT-shaped model.")],
                    [.plain("It doesn\u{2019}t write paragraphs like ChatGPT. But it "),
                     .highlight("understands"),
                     .plain(" text really well, and that turns out to be most of the work.")],
                ]
            ),

            // 12 — Recap, plain and short.
            .recap(
                id: "bert-recap",
                title: "BERT, in three lines",
                points: [
                    "It learned language by playing fill-in-the-blank, billions of times, with no teacher.",
                    "It reads both sides of every blank at once. That is the trick the older models missed.",
                    "One slow training run gives one general brain. Anyone can teach it a specific job in a few hours.",
                ]
            ),

            // 13 — Closing. Plain quote, no jargon.
            .paperLink(
                id: "bert-source",
                quote: "Look both ways. The rest will follow.",
                attribution: "Devlin, Chang, Lee, Toutanova \u{00B7} NAACL \u{00B7} 2019",
                linkTitle: "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
                url: URL(string: "https://arxiv.org/abs/1810.04805")
            ),
        ]
    )
}
