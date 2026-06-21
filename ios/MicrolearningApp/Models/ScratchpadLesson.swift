import SwiftUI

// MARK: - Scratchpad lesson
//
// 2021, Nye et al. (Google). Beginner-first, BERT/R1 tier. One idea, told
// plainly: a model forced to answer in one shot has no room to compute, so it
// fails long, algorithmic problems. Give it a scratchpad to write intermediate
// state and it succeeds, and keeps succeeding as the input grows. Three
// hands-on beats: add on the pad, run code on the pad, then stretch the input
// and watch the pad keep climbing.

extension LearningLesson {

    static let scratchpad = LearningLesson(
        paperId: "loop:foundational:scratchpad",
        cards: [

            // 1 - Cover.
            .cover(
                id: "scratchpad-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Give it room to think.",
                highlight: "room",
                standfirst: "2021. A model that must answer in one breath fails hard sums. Hand it a notepad for the working, and it succeeds.",
                hero: ScratchpadGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "scratchpad-hook",
                kicker: "Start here",
                title: "Try it in your head",
                paragraphs: [
                    [.plain("Multiply "),
                     .bold("456 by 678"),
                     .plain(" in your head, right now, no writing. Hard, isn't it? The pieces slip before you can combine them.")],
                    [.plain("Now do it on paper. Suddenly it is easy: small steps, each written down, nothing held in your head at once.")],
                    [.plain("A language model has the same problem, and in 2021 researchers found the same fix: "),
                     .highlight("give it paper"),
                     .plain(".")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "scratchpad-idea",
                kicker: "The idea",
                title: "One shot leaves no room",
                paragraphs: [
                    [.plain("A model normally has to produce the answer "),
                     .highlight("in one shot"),
                     .plain(". For a long calculation there is nowhere to put the half-finished work, so it guesses, and misses.")],
                    [.plain("A "),
                     .term("scratchpad"),
                     .plain(" changes that. The model writes the "),
                     .term("intermediate steps"),
                     .plain(" first, then reads its own working to give the answer.")],
                ],
                caption: "One shot guesses. The pad works it out.",
                illustration: DirectVsScratchpadArt()
            ),

            // 4 - Add on the pad.
            .interactive(id: "scratchpad-add") { progress in
                ColumnCarryStudio(cardId: "scratchpad-add", progress: progress)
            },

            // 5 - On-ramp: where do the steps come from?
            .prose(
                id: "scratchpad-teach-rampup",
                kicker: "A puzzle first",
                title: "But who teaches it the habit?",
                paragraphs: [
                    [.plain("A model will not reach for a notepad on its own. So how do you get it to write the steps instead of blurting an answer?")],
                    [.plain("You show it. The training examples don't just pair a question with an answer; they pair it with the "),
                     .highlight("full working"),
                     .plain(" in between. Trained on enough of those, the model learns to lay out its own steps.")],
                    [.plain("That habit is the whole trick, and it carries to problems far beyond sums.")],
                ]
            ),

            // 6 - Not just sums: run code.
            .illustrated(
                id: "scratchpad-code-art",
                kicker: "Wider than maths",
                title: "It can run code in its head",
                paragraphs: [
                    [.plain("The same notepad lets a model "),
                     .highlight("execute a program"),
                     .plain(". It writes down each variable after every line, the way you would trace code by hand.")],
                    [.plain("Keeping that running "),
                     .term("execution trace"),
                     .plain(" means it never has to predict the final output cold. It just reads off the last line.")],
                ],
                caption: "Program on the left, the running state it writes on the right.",
                illustration: ProgramTraceArt()
            ),

            // 7 - Run code on the pad.
            .interactive(id: "scratchpad-trace") { progress in
                ProgramTraceStudio(cardId: "scratchpad-trace", progress: progress)
            },

            // 8 - On-ramp: what about bigger problems?
            .prose(
                id: "scratchpad-length-rampup",
                kicker: "One idea first",
                title: "What happens when it gets longer?",
                paragraphs: [
                    [.plain("A one-shot model might scrape a two-digit sum. But stretch it to five digits, or a longer program, and the odds collapse: more to juggle, more to drop.")],
                    [.plain("The scratchpad barely notices. A longer problem is just "),
                     .highlight("more of the same small steps"),
                     .plain(", and each step is no harder than before.")],
                    [.plain("Holding up as inputs grow has a name: "),
                     .term("length generalisation"),
                     .plain(". It is the result that made people pay attention.")],
                ]
            ),

            // 9 - Stretch the input.
            .interactive(id: "scratchpad-ladder") { progress in
                LengthLadderStudio(cardId: "scratchpad-ladder", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "scratchpad-result",
                kicker: "The payoff",
                title: "Small steps beat one big leap",
                paragraphs: [
                    [.plain("On long addition, polynomial evaluation, and executing code, the scratchpad turned near-zero accuracy into "),
                     .highlight("near-perfect"),
                     .plain(", and held up on inputs longer than anything seen in training.")],
                    [.plain("Nothing about the model got smarter. It was simply allowed to "),
                     .bold("show its work"),
                     .plain(", one small step at a time.")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "scratchpad-everyday",
                kicker: "Where you've met it",
                title: "The seed of step-by-step AI",
                paragraphs: [
                    [.plain("The scratchpad was the early, concrete version of an idea that took over the field: let the model think on the page before it answers.")],
                    [.plain("Chain-of-thought made it a prompt, and reasoning models like DeepSeek-R1 made it a habit. When a chatbot writes out its working, you are watching a scratchpad, grown up.")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "scratchpad-recap",
                title: "Scratchpads, in three lines",
                points: [
                    "Forced to answer in one shot, a model has no room to compute and fails long, step-by-step problems.",
                    "Let it write the intermediate steps to a scratchpad, and it works the problem out the way you would on paper.",
                    "Because each step stays small, it keeps working even as the input grows far longer than its training examples.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "scratchpad-source",
                quote: "The model did not need to be smarter. It needed somewhere to think.",
                attribution: "Nye et al. \u{00B7} Google \u{00B7} 2021",
                linkTitle: "Show Your Work: Scratchpads for Intermediate Computation with Language Models",
                url: URL(string: "https://arxiv.org/abs/2112.00114")
            ),
        ]
    )
}
