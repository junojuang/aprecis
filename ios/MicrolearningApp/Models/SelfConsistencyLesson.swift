import SwiftUI

// MARK: - Self-Consistency lesson
//
// 2022, Wang et al. (Google). Beginner-first, BERT/R1 tier. One idea: a single
// chain of thought can take one wrong turn and ruin the answer, so don't trust
// one. Sample many chains and let their answers vote; the truth is usually
// reachable by the most routes. Three hands-on beats: sample paths and tally,
// see the confident single chain lose to the vote, and dial the diversity that
// makes voting work.

extension LearningLesson {

    static let selfConsistency = LearningLesson(
        paperId: "loop:foundational:self-consistency",
        cards: [

            // 1 - Cover.
            .cover(
                id: "selfcon-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Ask again, then vote.",
                highlight: "vote",
                standfirst: "2022. One chain of reasoning can slip. Sample many and let the answers vote, and the right one usually wins.",
                hero: SelfConsistencyGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "selfcon-hook",
                kicker: "Start here",
                title: "Ask three friends",
                paragraphs: [
                    [.plain("A tricky question goes round a table. One friend reasons their way to an answer. Do you just trust them?")],
                    [.plain("More likely you ask a few people. If most arrive at the "),
                     .highlight("same answer by different routes"),
                     .plain(", you trust it far more, even if one disagrees.")],
                    [.plain("In 2022, researchers gave a model the same instinct, and reasoning scores jumped.")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "selfcon-idea",
                kicker: "The idea",
                title: "One chain is fragile",
                paragraphs: [
                    [.plain("Chain-of-thought writes a single line of reasoning. If it takes "),
                     .highlight("one wrong turn"),
                     .plain(", the whole answer is wrong, and the model still sounds confident.")],
                    [.plain("Self-consistency samples "),
                     .term("many chains"),
                     .plain(" instead, then keeps the answer that the most of them agree on. A slip in one chain gets outvoted.")],
                ],
                caption: "One chain can slip. Many chains vote it down.",
                illustration: OneChainVsManyArt()
            ),

            // 4 - Sample and tally.
            .interactive(id: "selfcon-sample") { progress in
                SamplePathsStudio(cardId: "selfcon-sample", progress: progress)
            },

            // 5 - On-ramp: why not just take the best one?
            .prose(
                id: "selfcon-greedy-rampup",
                kicker: "A puzzle first",
                title: "Why not trust the confident one?",
                paragraphs: [
                    [.plain("A model can pick its single most-likely chain, the one it is most confident in. Surely that is the safest bet?")],
                    [.plain("Not quite. The most fluent-sounding chain can still be "),
                     .highlight("wrong"),
                     .plain(", and confidence is no guarantee of correctness.")],
                    [.plain("What helps is noticing that the right answer tends to be reachable "),
                     .highlight("many different ways"),
                     .plain(", while wrong answers are scattered. See it next.")],
                ]
            ),

            // 6 - Ballot illustration.
            .illustrated(
                id: "selfcon-ballot-art",
                kicker: "The move",
                title: "Count the final answers",
                paragraphs: [
                    [.plain("Self-consistency ignores how pretty each chain is. It only looks at where they "),
                     .highlight("land"),
                     .plain(", and tallies the final answers like a ballot.")],
                    [.plain("This is sometimes called "),
                     .term("sample and marginalise"),
                     .plain(": throw away the differing reasoning, keep the answer the most paths reached.")],
                ],
                caption: "Each chain casts one vote. The leader wins.",
                illustration: BallotArt()
            ),

            // 7 - Greedy vs vote.
            .interactive(id: "selfcon-greedy") { progress in
                GreedyVsVoteStudio(cardId: "selfcon-greedy", progress: progress)
            },

            // 8 - On-ramp: diversity.
            .prose(
                id: "selfcon-diversity-rampup",
                kicker: "One idea first",
                title: "The votes have to differ",
                paragraphs: [
                    [.plain("There is a catch. If every sample is the "),
                     .bold("exact same chain"),
                     .plain(", voting is pointless: a wrong answer can never be outvoted.")],
                    [.plain("So the model samples with a little randomness, called "),
                     .term("temperature"),
                     .plain(", to take different routes each time. Too little and the chains are clones; too much and they turn to nonsense.")],
                    [.plain("The right amount of variety is what makes the vote meaningful.")],
                ]
            ),

            // 9 - Dial diversity.
            .interactive(id: "selfcon-diversity") { progress in
                DiversityStudio(cardId: "selfcon-diversity", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "selfcon-result",
                kicker: "The payoff",
                title: "A free accuracy boost",
                paragraphs: [
                    [.plain("On grade-school maths, swapping one chain for a vote over many lifted accuracy by around "),
                     .bold("18 points"),
                     .plain(", with similar gains across other reasoning benchmarks.")],
                    [.plain("No new training and no new model. Just "),
                     .highlight("sample more and count"),
                     .plain(", trading a little extra computation for a lot more reliability.")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "selfcon-everyday",
                kicker: "Where you've met it",
                title: "Thinking longer, on purpose",
                paragraphs: [
                    [.plain("Self-consistency was an early sign that letting a model do "),
                     .highlight("more work at answer time"),
                     .plain(" buys accuracy, not just bigger training.")],
                    [.plain("That idea, spend more compute when you think, runs straight through to today's reasoning models, which sample and weigh many lines of thought before they commit.")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "selfcon-recap",
                title: "Self-consistency, in three lines",
                points: [
                    "A single chain of thought can take one wrong turn and confidently give the wrong answer.",
                    "Sample many diverse chains and keep the final answer the most of them agree on, so a slip gets outvoted.",
                    "It needs enough diversity to be meaningful, and trades a little extra compute for a clear accuracy gain.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "selfcon-source",
                quote: "Don't trust one line of reasoning. Trust where many of them agree.",
                attribution: "Wang et al. \u{00B7} Google \u{00B7} 2022",
                linkTitle: "Self-Consistency Improves Chain of Thought Reasoning in Language Models",
                url: URL(string: "https://arxiv.org/abs/2203.11171")
            ),
        ]
    )
}
