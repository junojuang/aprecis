import SwiftUI

// MARK: - BERT lesson
//
// 2018, Devlin et al. Gold-standard flow (see LESSON_FLOW_GUIDE.md): a
// 14-year-old walks in curious and walks out with a working mental model,
// and never meets a piece of jargon cold. The ladder is hook -> human
// insight -> old gap -> BERT's fix -> the mechanism -> the payoff. Terms
// (token, mask, pretrain, fine-tune) are defined inline at the moment they
// first matter, not pre-loaded in a glossary card, and resolve to a tap via
// FoundationalGlossaries.bert.

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

            // 2 — HOOK. No AI words yet. You already do the thing this paper
            //     is about. End on a question the next card answers, so we
            //     don't leap to the solution before earning it.
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
                    [.plain("Nobody told you. The missing word just "),
                     .highlight("filled itself in"),
                     .plain(".")],
                    [.plain("Here\u{2019}s the real question: how did you know? You never saw the word. So where did "),
                     .bold("milk"),
                     .plain(" come from?")],
                ]
            ),

            // 3 — THE HUMAN INSIGHT. Name how the reader did it. This is the
            //     concept the whole paper mechanises. Both-sides visual.
            .illustrated(
                id: "bert-bothsides",
                kicker: "How you did it",
                title: "You used both sides",
                paragraphs: [
                    [.plain("You read the words "),
                     .term("before"),
                     .plain(" the blank ("),
                     .highlight("I poured"),
                     .plain(") and the words "),
                     .term("after"),
                     .plain(" it ("),
                     .highlight("on my cereal"),
                     .plain("). Neither half is enough alone.")],
                    [.plain("\u{201C}I poured\u{201D} on its own could be wine, or juice. \u{201C}On my cereal\u{201D} on its own could be sugar, or fruit. Put the two sides together and only one word fits: "),
                     .bold("milk"),
                     .plain(".")],
                    [.plain("That move, leaning on both sides at once, is the whole idea. Hold onto it.")],
                ],
                caption: "Left side and right side, both pointing at the same blank.",
                illustration: ClozeArt()
            ),

            // 4 — THE OLD GAP. What computers couldn't do. Earns the fix.
            //     LeftOnlyStrip shows the one-directional deficit.
            .prose(
                id: "bert-oldway",
                kicker: "The old problem",
                title: "Computers used to read one way",
                paragraphs: [
                    [.plain("Older language programs read a sentence strictly left to right. By the blank they had only seen "),
                     .bold("\"I poured ____\""),
                     .plain(" and nothing after it.")],
                    [.plain("So they were guessing half-blind, the same way "),
                     .highlight("you would be if the page was torn off after the blank"),
                     .plain(". Wine, juice, water, who knows.")],
                    [.plain("The fix sounds obvious once you say it: let the computer look at "),
                     .term("both"),
                     .plain(" sides too. Obvious, but nobody had made it work well. That is what this paper did.")],
                ],
                hero: AnyView(LeftOnlyStrip().frame(height: 90))
            ),

            // 5 — THE FIX. What BERT actually does, as the answer to the gap.
            //     First terms (token, mask) defined inline, at point of need.
            .illustrated(
                id: "bert-idea",
                kicker: "BERT\u{2019}s fix",
                title: "Turn it into a game",
                paragraphs: [
                    [.plain("The researchers gave the computer one simple game. Take any sentence. Chop it into little pieces, called "),
                     .term("tokens"),
                     .plain(" (mostly whole words). Cover one piece, a "),
                     .term("mask"),
                     .plain(", and guess what was under it, using both sides.")],
                    [.plain("Then they had it play that game "),
                     .highlight("billions of times"),
                     .plain(", on every sentence in Wikipedia. No teacher, no answer key. The sentence itself is the answer: the word was right there before they hid it.")],
                    [.plain("That is how it learned language. Not from a textbook. From practice, both ways, at enormous scale. The computer is called "),
                     .bold("BERT"),
                     .plain(".")],
                ],
                caption: "One token hidden. The rest of the sentence still showing.",
                illustration: ClozeArt()
            ),

            // 6 — Try the game yourself.
            .interactive(id: "bert-mask") { progress in
                MaskedTokenStudio(cardId: "bert-mask", progress: progress)
            },

            // 7 — BRIDGE (new scaffolding). Motivates the mechanism before it
            //     lands: filling the blank was never the hard part. Reading
            //     every word in context is. This is the why for card 8.
            .prose(
                id: "bert-everyword",
                kicker: "The part that does the work",
                title: "The blank was the easy bit",
                paragraphs: [
                    [.plain("To fill \u{201C}I poured ___ on my cereal\u{201D}, BERT first had to genuinely understand "),
                     .bold("poured"),
                     .plain(" and "),
                     .bold("cereal"),
                     .plain(". The blank is easy once you understand the words around it.")],
                    [.plain("So BERT does not only study the hidden word. It reads "),
                     .highlight("every word in light of all the others"),
                     .plain(", the same way you just did for the whole sentence, not just the gap.")],
                    [.plain("That habit, reading each word against the rest, is what it carries into every real job later. So it is worth seeing up close.")],
                ]
            ),

            // 8 — THE MECHANISM. Now safe to show: every word reads every
            //     other word. Opens by tying back to the bridge above.
            .illustrated(
                id: "bert-bidirectional",
                kicker: "How it reads, up close",
                title: "Every word listens to every other word",
                paragraphs: [
                    [.plain("Inside BERT, each word "),
                     .highlight("listens to every other word"),
                     .plain(" before settling on what it means here. That listening is called "),
                     .term("attention"),
                     .plain(".")],
                    [.plain("Take the word "),
                     .term("sat"),
                     .plain(" in \u{201C}the cat sat on the mat\u{201D}. To pin it down, BERT pays attention to "),
                     .bold("the cat"),
                     .plain(" before it and "),
                     .bold("on the mat"),
                     .plain(" after it, both at once. Same both-sides move, now for every word.")],
                ],
                caption: "One word in focus, with lines reaching to every other word.",
                illustration: BidirectionalGazeArt()
            ),

            // 9 — Drive the listening yourself.
            .interactive(id: "bert-gaze") { progress in
                BidirectionalGazeStudio(cardId: "bert-gaze", progress: progress)
            },

            // 10 — THE PAYOFF. One brain, many jobs. pretrain + fine-tune
            //      defined inline here, where they finally matter.
            .illustrated(
                id: "bert-pretrain",
                kicker: "Why people care",
                title: "Train once, use everywhere",
                paragraphs: [
                    [.plain("All that fill-in-the-blank practice is the slow, expensive part, called "),
                     .term("pretraining"),
                     .plain(". It happens once and leaves BERT with a "),
                     .highlight("general understanding of English"),
                     .plain(", like a person who has read a great many books.")],
                    [.plain("To give it a specific job, like spotting names in a paragraph, you don\u{2019}t start over. You keep that same brain and add a small "),
                     .term("job-shaped"),
                     .plain(" piece on top, then practise the new job for a few hours. That short second step is called "),
                     .term("fine-tuning"),
                     .plain(".")],
                    [.plain("This is the reason BERT mattered. One slow training run, then every team in the world reuses the same brain for whatever job they have.")],
                ],
                caption: "Big shared brain on the bottom. Small job-shaped piece on top.",
                illustration: PretrainFinetuneArt()
            ),

            // 11 — Try three different jobs on the same brain.
            .interactive(id: "bert-finetune") { progress in
                PretrainFinetuneStudio(cardId: "bert-finetune", progress: progress)
            },

            // 12 — Where the reader has already met BERT.
            .prose(
                id: "bert-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s already in your pocket",
                paragraphs: [
                    [.plain("BERT and its cousins are quietly running in things you use every day.")],
                    [.plain("When you "),
                     .bold("Google something"),
                     .plain(" and the results understand what you meant, even with a typo or odd wording, BERT is part of that.")],
                    [.plain("When your phone "),
                     .bold("autocompletes"),
                     .plain(" a tricky sentence, or your email guesses the "),
                     .term("Reply"),
                     .plain(" text, you\u{2019}re leaning on a BERT-shaped model.")],
                    [.plain("It doesn\u{2019}t write paragraphs like ChatGPT. But it "),
                     .highlight("understands"),
                     .plain(" text really well, and that turns out to be most of the work.")],
                ]
            ),

            // 13 — Recap, plain and short.
            .recap(
                id: "bert-recap",
                title: "BERT, in three lines",
                points: [
                    "You fill in blanks by reading both sides of them. Older computers only read one side, so they guessed half-blind.",
                    "BERT learned language by playing fill-in-the-blank both ways, billions of times, with no teacher. To do it, every word reads every other word.",
                    "That gives one general brain from one slow training run. Anyone can fine-tune it onto a specific job in a few hours.",
                ]
            ),

            // 14 — Closing. Plain quote, no jargon.
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
