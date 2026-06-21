import SwiftUI

// MARK: - Grokking lesson
//
// 2022, Power et al. (OpenAI). Beginner-first, BERT/R1 tier. One idea: a model
// can memorise its training data, look hopelessly overfit, and then, far later
// in training, suddenly generalise. Three hands-on beats: fast-forward the
// training to see the late leap, see what memorise vs generalise means on
// unseen pairs, and find the weight-decay setting that makes it grok.

extension LearningLesson {

    static let grokking = LearningLesson(
        paperId: "loop:foundational:grokking",
        cards: [

            // 1 - Cover.
            .cover(
                id: "gk-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "It clicks, eventually.",
                highlight: "clicks",
                standfirst: "2022. A model memorises its data, looks overfit, then keeps training and suddenly understands. Generalisation, arriving fashionably late.",
                hero: GrokkingGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "gk-hook",
                kicker: "Start here",
                title: "The penny that drops late",
                paragraphs: [
                    [.plain("You drill something for ages, getting nowhere, feeling like you've only memorised it. Then one day, long after you'd given up expecting it, it just "),
                     .bold("clicks"),
                     .plain(".")],
                    [.plain("In 2022, researchers caught a neural network doing exactly that. It memorised its training set, sat there looking overfit, then "),
                     .highlight("suddenly generalised"),
                     .plain(".")],
                    [.plain("They called it "),
                     .term("grokking"),
                     .plain(".")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "gk-idea",
                kicker: "The idea",
                title: "Generalisation, fashionably late",
                paragraphs: [
                    [.plain("Train a small network on a task like modular arithmetic. It hits "),
                     .term("100% training accuracy"),
                     .plain(" fast while validation stays at chance: textbook overfitting.")],
                    [.plain("Keep training, far past where anyone would stop, and validation accuracy "),
                     .highlight("suddenly snaps to near 100%"),
                     .plain(". The model found the rule.")],
                ],
                caption: "Stop at overfitting and you miss it. Keep going and it groks.",
                illustration: OverfitVsGrokArt()
            ),

            // 4 - The curve.
            .interactive(id: "gk-curve") { progress in
                GrokCurveStudio(cardId: "gk-curve", progress: progress)
            },

            // 5 - On-ramp: what actually changed.
            .prose(
                id: "gk-memorize-rampup",
                kicker: "A puzzle first",
                title: "Memorise or understand?",
                paragraphs: [
                    [.plain("Both a memoriser and a generaliser can score 100% on the training set. So what's the real difference?")],
                    [.plain("A memoriser is a "),
                     .highlight("lookup table"),
                     .plain(": perfect on pairs it has seen, lost on anything new.")],
                    [.plain("A generaliser has the "),
                     .highlight("rule"),
                     .plain(", so it answers pairs it has never seen. Grokking is the switch from the first to the second.")],
                ]
            ),

            // 6 - Table vs rule illustration.
            .illustrated(
                id: "gk-table-art",
                kicker: "The difference",
                title: "A table with holes vs a rule",
                paragraphs: [
                    [.plain("Memorising fills in only the cells it was trained on and leaves the rest "),
                     .term("blank"),
                     .plain(".")],
                    [.plain("Grokking learns the function behind the table, so every cell, seen or unseen, fills itself in.")],
                ],
                caption: "The grokked model completes the squares it was never shown.",
                illustration: TableVsRuleArt()
            ),

            // 7 - Memorize vs generalize.
            .interactive(id: "gk-memorize") { progress in
                MemorizeVsGeneralizeStudio(cardId: "gk-memorize", progress: progress)
            },

            // 8 - On-ramp: why it groks at all.
            .prose(
                id: "gk-decay-rampup",
                kicker: "One idea first",
                title: "Why would it ever switch?",
                paragraphs: [
                    [.plain("If memorising already scores 100% on training, why would the model bother finding the rule?")],
                    [.plain("The push comes from "),
                     .term("weight decay"),
                     .plain(", a gentle pressure toward simpler weights. The rule is a simpler solution than a giant lookup table.")],
                    [.plain("Turn that pressure off and the model "),
                     .highlight("never groks"),
                     .plain(". It is happy to stay a memoriser forever.")],
                ]
            ),

            // 9 - Weight decay.
            .interactive(id: "gk-decay") { progress in
                WeightDecayStudio(cardId: "gk-decay", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "gk-result",
                kicker: "The payoff",
                title: "Overfitting isn't the end",
                paragraphs: [
                    [.plain("Grokking broke a comfortable assumption: that once training accuracy is perfect and validation has stalled, there's "),
                     .bold("nothing left to learn"),
                     .plain(".")],
                    [.plain("It showed that generalisation can be a "),
                     .highlight("separate, later phase"),
                     .plain(", and that regularisation, not just more data, can drive it.")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "gk-everyday",
                kicker: "Why it matters",
                title: "A window into learning",
                paragraphs: [
                    [.plain("Grokking became a favourite testbed for "),
                     .highlight("interpretability"),
                     .plain(": because the moment of understanding is so sharp, researchers can watch a clean rule form inside the weights.")],
                    [.plain("It feeds the bigger question behind every large model: when does a network truly "),
                     .highlight("understand"),
                     .plain(", rather than just memorise?")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "gk-recap",
                title: "Grokking, in three lines",
                points: [
                    "A small model memorises its training data fast, hitting 100% train while validation stays at chance.",
                    "Far later in training, validation suddenly leaps to near 100%: it has grokked the underlying rule.",
                    "Weight decay drives the switch, by making the simple rule a better deal than a giant lookup table.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "gk-source",
                quote: "Generalisation can arrive long after a model looks hopelessly overfit.",
                attribution: "Power et al. \u{00B7} OpenAI \u{00B7} 2022",
                linkTitle: "Grokking: Generalization Beyond Overfitting on Small Algorithmic Datasets",
                url: URL(string: "https://arxiv.org/abs/2201.02177")
            ),
        ]
    )
}
