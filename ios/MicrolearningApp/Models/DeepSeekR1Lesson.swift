import SwiftUI

// MARK: - DeepSeek-R1 lesson
//
// 2025, DeepSeek-AI. Beginner-first redesign in the BERT mould: a curious
// 14-year-old should walk in and leave with a working mental model. The whole
// lesson rides one idea, told plainly: you can teach a model to *reason* by
// rewarding right answers instead of showing it worked solutions. Around that
// sit three hands-on beats - the reward signal, the group baseline (GRPO), and
// the emergent "aha moment" where the model starts checking its own work.

extension LearningLesson {

    static let deepseekR1 = LearningLesson(
        paperId: "deepseek-r1",
        cards: [

            // 1 - Editorial cover.
            .cover(
                id: "deepseek-r1-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Let it figure out how to think.",
                highlight: "how to think",
                standfirst: "2025. A model that learned to reason with no worked examples, just a reward for getting the answer right.",
                hero: DeepSeekR1Glyph()
            ),

            // 2 - Relatable hook. No AI words yet. You already learned this way.
            .prose(
                id: "deepseek-r1-hook",
                kicker: "Start here",
                title: "How did you get good at maths?",
                paragraphs: [
                    [.plain("Think back to learning times tables. Nobody handed you the "),
                     .bold("one perfect way"),
                     .plain(" to multiply. A teacher just said "),
                     .term("right"),
                     .plain(" or "),
                     .term("wrong"),
                     .plain(".")],
                    [.plain("And slowly, chasing that "),
                     .highlight("right"),
                     .plain(", you invented your own tricks: round up then subtract, double and halve, check the answer back.")],
                    [.plain("DeepSeek-R1 learned to reason the exact same way. No worked solutions. Just a reward for the right answer, millions of times.")],
                ]
            ),

            // 3 - The big idea, in a picture.
            .illustrated(
                id: "deepseek-r1-idea",
                kicker: "What R1 does",
                title: "Reward the answer, not the method",
                paragraphs: [
                    [.plain("The model takes a hard problem, writes out an attempt, and gets one thing back: a "),
                     .highlight("score"),
                     .plain(". Did it land on the right answer or not?")],
                    [.plain("That score flows back and nudges the model to "),
                     .term("do more"),
                     .plain(" of whatever just worked. Repeat at huge scale, and good reasoning habits grow on their own.")],
                ],
                caption: "Model tries, the answer is scored, the reward flows back.",
                illustration: RewardLoopArt()
            ),

            // 4 - The old way, so the new move lands.
            .prose(
                id: "deepseek-r1-oldway",
                kicker: "Why this is a big deal",
                title: "The old way was copying",
                paragraphs: [
                    [.plain("Before R1, you taught a model to reason by showing it "),
                     .bold("thousands of worked solutions"),
                     .plain(" written by humans, and asking it to imitate them.")],
                    [.plain("That's expensive, and the model only ever learns to "),
                     .highlight("copy our methods"),
                     .plain(". R1 asked a bolder question: what if we skip the examples and just reward correct answers?")],
                    [.plain("The first version, "),
                     .term("R1-Zero"),
                     .plain(", did exactly that: pure reward, zero worked examples, and it learned to reason anyway.")],
                ]
            ),

            // 5 - Try it: be the reward.
            .interactive(id: "deepseek-r1-reward") { progress in
                RewardSignalStudio(cardId: "deepseek-r1-reward", progress: progress)
            },

            // 6 - Gentle on-ramp to GRPO: build the intuition before the mechanism.
            .prose(
                id: "deepseek-r1-grpo-rampup",
                kicker: "A puzzle first",
                title: "How do you grade with no answer key?",
                paragraphs: [
                    [.plain("Picture a class sitting a brand-new problem. There is no answer key yet, so nobody can be marked right or wrong outright.")],
                    [.plain("You can still tell who did well. Lay everyone's attempts side by side: whoever beats the "),
                     .highlight("class average"),
                     .plain(" clearly did something right, and whoever trails it has room to improve.")],
                    [.plain("That one idea, grading each answer against its peers, is the entire shortcut behind R1's training. Next, see it in action.")],
                ]
            ),

            // 7 - GRPO, in a picture.
            .illustrated(
                id: "deepseek-r1-grpo-art",
                kicker: "The clever shortcut",
                title: "Judge each answer against the group",
                paragraphs: [
                    [.plain("To know if an answer is "),
                     .highlight("good"),
                     .plain(", you need something to compare it to. The usual fix is to train a whole second model just to grade answers, which is slow and costly.")],
                    [.plain("R1's trick: write a "),
                     .term("group"),
                     .plain(" of answers to the same question, then grade each one against the group's own average. The yardstick is free.")],
                ],
                caption: "Four tries, one dashed average. Beat it, get reinforced.",
                illustration: GRPOGroupArt()
            ),

            // 8 - Drive the group baseline.
            .interactive(id: "deepseek-r1-grpo") { progress in
                GRPOGroupStudio(cardId: "deepseek-r1-grpo", progress: progress)
            },

            // 9 - Gentle on-ramp to chain of thought: show your working.
            .prose(
                id: "deepseek-r1-cot-rampup",
                kicker: "One habit first",
                title: "Show your working",
                paragraphs: [
                    [.plain("On a hard sum, writing each step out instead of blurting the answer lets you catch a slip halfway and fix it before it costs you.")],
                    [.plain("A model can do the same: write its reasoning out before committing to an answer. That written-out reasoning has a name, a "),
                     .term("chain of thought"),
                     .plain(".")],
                    [.plain("Give a model room to think like this, and something nobody asked for starts to happen.")],
                ]
            ),

            // 10 - The aha moment, in a picture.
            .illustrated(
                id: "deepseek-r1-aha-art",
                kicker: "The surprise",
                title: "It started checking its own work",
                paragraphs: [
                    [.plain("Partway through training, with nobody telling it to, the model began writing things like "),
                     .bold("\u{201C}wait, let me re-check that.\u{201D}")],
                    [.plain("It learned to "),
                     .highlight("pause, backtrack, and verify"),
                     .plain(", purely because those habits earned more right answers. The paper calls it the "),
                     .term("aha moment"),
                     .plain(".")],
                ],
                caption: "The thinking loops back on itself to double-check.",
                illustration: AhaLoopArt()
            ),

            // 11 - Drive the difficulty, see the thinking grow.
            .interactive(id: "deepseek-r1-aha") { progress in
                AhaThinkingStudio(cardId: "deepseek-r1-aha", progress: progress)
            },

            // 12 - Distillation: hand the reasoning down.
            .illustrated(
                id: "deepseek-r1-distill",
                kicker: "Why everyone could use it",
                title: "Big model teaches the small ones",
                paragraphs: [
                    [.plain("Reasoning this good usually needs a huge, expensive model. R1's team showed you can "),
                     .highlight("distill"),
                     .plain(" its reasoning into much smaller models.")],
                    [.plain("Those small distilled models then out-reasoned far bigger ones, so good thinking can be "),
                     .term("passed down"),
                     .plain(", not just bought with size.")],
                ],
                caption: "One teacher, several small students that now reason too.",
                illustration: DistillArt()
            ),

            // 13 - Where you've met it.
            .prose(
                id: "deepseek-r1-everyday",
                kicker: "Where you've met it",
                title: "The \u{201C}thinking\u{2026}\u{201D} you see in chatbots",
                paragraphs: [
                    [.plain("When a chatbot shows a little "),
                     .bold("\u{201C}thinking\u{2026}\u{201D}"),
                     .plain(" step before answering a hard maths or coding question, you're watching a chain of thought like R1's.")],
                    [.plain("R1 mattered because it showed this reasoning could be grown with "),
                     .highlight("rewards alone"),
                     .plain(", and shipped with open weights, so anyone could build on it, not just one lab.")],
                ]
            ),

            // 14 - Recap, plain and short.
            .recap(
                id: "deepseek-r1-recap",
                title: "DeepSeek-R1, in three lines",
                points: [
                    "It learned to reason from rewards on right answers, with no worked solutions to copy.",
                    "GRPO judges a group of answers against their own average, so no costly judge model is needed.",
                    "Longer thinking and self-checking emerged on their own, then distilled down into small, cheap models.",
                ]
            ),

            // 15 - Closing.
            .paperLink(
                id: "deepseek-r1-source",
                quote: "Reward the right answer, and the reasoning grows itself.",
                attribution: "DeepSeek-AI \u{00B7} 2025",
                linkTitle: "DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning",
                url: URL(string: "https://arxiv.org/abs/2501.12948")
            ),
        ]
    )
}
