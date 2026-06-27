import SwiftUI

// MARK: - Least-to-Most lesson
//
// 2022, Zhou et al. (Google). Beginner-first, BERT/R1 tier. One idea: split a
// hard problem into a list of easier subquestions, then solve them in order so
// each answer feeds the next. Because the model only ever faces one small step,
// it solves problems deeper than the examples it was shown. Three hands-on
// beats: decompose, climb the ladder, and push past the example depth.

extension LearningLesson {

    static let leastToMost = LearningLesson(
        paperId: "least-to-most",
        cards: [

            // 1 - Cover.
            .cover(
                id: "l2m-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Easiest step first.",
                highlight: "Easiest",
                standfirst: "2022. Don't solve the hard problem. Break it into easy ones, in order, and let each answer feed the next.",
                hero: LeastToMostGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "l2m-hook",
                kicker: "Start here",
                title: "How you'd actually do it",
                paragraphs: [
                    [.plain("Faced with a messy word problem, you don't answer it whole. You ask a smaller question first, answer that, then use it to ask the next.")],
                    [.plain("Chain of thought reasons in one pass. Least-to-most makes the breaking-down "),
                     .highlight("an explicit first step"),
                     .plain(".")],
                    [.plain("That small change let models solve problems "),
                     .highlight("harder than any example they were given"),
                     .plain(".")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "l2m-idea",
                kicker: "The idea",
                title: "Plan, then solve",
                paragraphs: [
                    [.plain("Least-to-most runs in "),
                     .highlight("two stages"),
                     .plain(". First it decomposes the problem into a list of simpler subquestions, ordered easiest first.")],
                    [.plain("Then it solves them "),
                     .term("in sequence"),
                     .plain(", and the answer to each is fed into the next, so no single step is ever hard.")],
                ],
                caption: "A chain leaps. Least-to-most lists the steps first.",
                illustration: DecomposeVsChainArt()
            ),

            // 4 - Decompose.
            .interactive(id: "l2m-decompose") { progress in
                DecomposeStudio(cardId: "l2m-decompose", progress: progress)
            },

            // 5 - On-ramp: the carry.
            .prose(
                id: "l2m-carry-rampup",
                kicker: "A puzzle first",
                title: "The plan is only half of it",
                paragraphs: [
                    [.plain("A list of subquestions is useless if you answer them in a vacuum. The trick is that each one is solved "),
                     .highlight("using the answers before it"),
                     .plain(".")],
                    [.plain("The result of \"how many in the bags?\" is literally slotted into the next question before the model solves it.")],
                    [.plain("So the steps form a "),
                     .highlight("chain of dependencies"),
                     .plain(", climbed from the bottom.")],
                ]
            ),

            // 6 - Substitution illustration.
            .illustrated(
                id: "l2m-sub-art",
                kicker: "The carry",
                title: "Each answer feeds the next",
                paragraphs: [
                    [.plain("Solving the easiest subquestion produces a value, and that value is "),
                     .highlight("substituted"),
                     .plain(" into the next subquestion.")],
                    [.plain("Step by step the unknowns get filled in, until the last subquestion is just the original problem with every piece already worked out.")],
                ],
                caption: "The 12 from question one slots straight into question two.",
                illustration: SubstitutionArt()
            ),

            // 7 - Solve the ladder.
            .interactive(id: "l2m-solve") { progress in
                SolveLadderStudio(cardId: "l2m-solve", progress: progress)
            },

            // 8 - On-ramp: generalisation.
            .prose(
                id: "l2m-depth-rampup",
                kicker: "One idea first",
                title: "Why bother, if a chain works?",
                paragraphs: [
                    [.plain("On easy problems a chain of thought is fine. The difference shows up when a problem is "),
                     .bold("deeper than the examples"),
                     .plain(" you showed the model.")],
                    [.plain("A chain tends to imitate the length it saw and gives up early. Least-to-most just keeps adding subquestions, however many it takes.")],
                    [.plain("Solving cases harder than the examples has a name: "),
                     .term("compositional generalisation"),
                     .plain(".")],
                ]
            ),

            // 9 - Depth test.
            .interactive(id: "l2m-depth") { progress in
                DepthStudio(cardId: "l2m-depth", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "l2m-result",
                kicker: "The payoff",
                title: "Harder than it was taught",
                paragraphs: [
                    [.plain("On benchmarks built to test composition, least-to-most solved a large majority of problems that were "),
                     .bold("longer and deeper"),
                     .plain(" than anything in its prompt, where chain of thought scored close to zero.")],
                    [.plain("The model was not retrained. It was just asked to "),
                     .highlight("decompose before it solved"),
                     .plain(".")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "l2m-everyday",
                kicker: "Where you've met it",
                title: "Plans inside the answer",
                paragraphs: [
                    [.plain("Least-to-most made "),
                     .highlight("decomposition"),
                     .plain(" a first-class move: figure out the subproblems before touching the answer.")],
                    [.plain("That habit runs through modern agents that draft a plan and work it step by step, and through reasoning models that lay out subgoals before solving them.")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "l2m-recap",
                title: "Least-to-most, in three lines",
                points: [
                    "Stage one decomposes a hard problem into simpler subquestions, ordered easiest first.",
                    "Stage two solves them in sequence, feeding each answer into the next, so no step is ever hard.",
                    "Because it reduces any problem to one-step pieces, it generalises to problems deeper than its examples.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "l2m-source",
                quote: "Don't solve the hard thing. Solve the easy things, in the right order.",
                attribution: "Zhou et al. \u{00B7} Google \u{00B7} 2022",
                linkTitle: "Least-to-Most Prompting Enables Complex Reasoning in Large Language Models",
                url: URL(string: "https://arxiv.org/abs/2205.10625")
            ),
        ]
    )
}
