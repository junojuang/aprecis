import SwiftUI

// MARK: - Chain-of-Thought lesson
//
// 2022, Wei et al. (Google). Beginner-first, in the BERT and R1 mould: a
// curious 14-year-old should walk in and leave with a working mental model.
// The whole lesson rides one idea, told plainly: a big model often already
// knows how to reason, it just answers too fast. Ask it to show its working,
// by showing it worked examples, and the answers get far better. The twist:
// this only kicks in once the model is large enough. Three hands-on beats:
// trust the worked answer, build the prompt, and feel the emergence at scale.

extension LearningLesson {

    static let chainOfThought = LearningLesson(
        paperId: "chain-of-thought",
        cards: [

            // 1 - Editorial cover.
            .cover(
                id: "cot-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Show your working.",
                highlight: "working",
                standfirst: "2022. The discovery that a big model can already reason. It just has to be asked to slow down and write the steps.",
                hero: ChainOfThoughtGlyph()
            ),

            // 2 - Relatable hook. No AI words yet.
            .prose(
                id: "cot-hook",
                kicker: "Start here",
                title: "The maths-class trick",
                paragraphs: [
                    [.plain("Remember being told to "),
                     .bold("show your working"),
                     .plain(" on a hard sum? It felt like a chore. But it was a real trick: writing the steps stops you slipping.")],
                    [.plain("Blurt the answer to a multi-step problem and you often trip. Walk through it, "),
                     .highlight("one step at a time"),
                     .plain(", and you get it right.")],
                    [.plain("In 2022, researchers found that large language models are exactly the same. This is the story of that finding.")],
                ]
            ),

            // 3 - The big idea, in a picture.
            .illustrated(
                id: "cot-idea",
                kicker: "The idea",
                title: "Make it think out loud",
                paragraphs: [
                    [.plain("Ask a model a tricky question and it tends to jump "),
                     .highlight("straight to an answer"),
                     .plain(", often the wrong one. It is fast, but it skips the thinking.")],
                    [.plain("Chain-of-thought prompting asks it to write the steps first, then answer. That run of steps has a name: a "),
                     .term("chain of thought"),
                     .plain(". Same model, far better answers.")],
                ],
                caption: "Jump straight to the answer, or walk the steps.",
                illustration: StandardVsCoTArt()
            ),

            // 4 - Feel the difference yourself.
            .interactive(id: "cot-straight") { progress in
                StraightVsWorkingStudio(cardId: "cot-straight", progress: progress)
            },

            // 5 - Gentle on-ramp to few-shot prompting: teach by example, no retraining.
            .prose(
                id: "cot-fewshot-rampup",
                kicker: "A puzzle first",
                title: "How do you teach it a habit, fast?",
                paragraphs: [
                    [.plain("You cannot retrain a giant model every time you want it to behave differently. So how do you change what it does?")],
                    [.plain("The trick is older than it sounds: "),
                     .highlight("show it a couple of examples"),
                     .plain(" first, right there in your question. The model copies the pattern it sees.")],
                    [.plain("Give it a few solved examples before the real one. That is called "),
                     .term("few-shot prompting"),
                     .plain(", and it is the lever chain-of-thought pulls.")],
                ]
            ),

            // 6 - Few-shot exemplars, in a picture.
            .illustrated(
                id: "cot-fewshot-art",
                kicker: "The move",
                title: "Put the working in the examples",
                paragraphs: [
                    [.plain("Normally the examples you show are just "),
                     .term("question then answer"),
                     .plain(". The model copies that: it answers fast and skips the steps.")],
                    [.plain("Chain-of-thought changes one thing. The examples now show the "),
                     .highlight("working too"),
                     .plain(". Seeing that, the model writes its own working before answering your real question.")],
                ],
                caption: "Two solved examples that show their steps, then your question.",
                illustration: FewShotArt()
            ),

            // 7 - Build the prompt yourself.
            .interactive(id: "cot-prompt") { progress in
                PromptBuilderStudio(cardId: "cot-prompt", progress: progress)
            },

            // 8 - Gentle on-ramp to emergence: a skill that needs a certain size.
            .prose(
                id: "cot-scale-rampup",
                kicker: "One catch first",
                title: "Some tricks need a big brain",
                paragraphs: [
                    [.plain("Think of a young child. Hand them a long, multi-step instruction and the extra steps just confuse them. The same instruction helps an older kid enormously.")],
                    [.plain("Chain-of-thought is like that. On a small model it barely helps, and can even "),
                     .highlight("make things worse"),
                     .plain(". The chains come out fluent but muddled.")],
                    [.plain("Only once the model is large does the trick suddenly pay off. A skill that appears only past a certain size has a name: an "),
                     .term("emergent ability"),
                     .plain(".")],
                ]
            ),

            // 9 - The scale curve, in a picture.
            .illustrated(
                id: "cot-scale-art",
                kicker: "The surprise",
                title: "It only works once it's big",
                paragraphs: [
                    [.plain("Plot accuracy against model size. Standard prompting climbs slowly. Chain-of-thought tracks it on small models, then "),
                     .highlight("shoots up"),
                     .plain(" once the model is large.")],
                    [.plain("The gap that opens is the emergent ability: the reasoning was sitting inside the big model all along, waiting for the right nudge.")],
                ],
                caption: "Two curves that stay together, then split wide at scale.",
                illustration: ScaleCurveArt()
            ),

            // 10 - Drive the scale, watch the gap open.
            .interactive(id: "cot-scale") { progress in
                CoTScaleStudio(cardId: "cot-scale", progress: progress)
            },

            // 11 - The headline result.
            .prose(
                id: "cot-result",
                kicker: "The payoff",
                title: "A prompt change, not a new model",
                paragraphs: [
                    [.plain("On a set of grade-school maths word problems, a large model went from about "),
                     .bold("18% to 57%"),
                     .plain(" correct, just by switching to chain-of-thought examples.")],
                    [.plain("No fine-tuning. No new data. No bigger model. The same weights, asked to "),
                     .highlight("show their working"),
                     .plain(". That is what made the field sit up.")],
                ]
            ),

            // 12 - Where you've met it.
            .prose(
                id: "cot-everyday",
                kicker: "Where you've met it",
                title: "\u{201C}Let's think step by step\u{201D}",
                paragraphs: [
                    [.plain("A follow-up found you often don't even need the examples. Just adding "),
                     .bold("\u{201C}let's think step by step\u{201D}"),
                     .plain(" to a question nudges a big model into reasoning.")],
                    [.plain("When a chatbot shows a little "),
                     .bold("\u{201C}thinking\u{2026}\u{201D}"),
                     .plain(" before a hard answer, that is this idea. Chain-of-thought is the seed that grew into full "),
                     .highlight("reasoning models"),
                     .plain(" like DeepSeek-R1.")],
                ]
            ),

            // 13 - Recap, plain and short.
            .recap(
                id: "cot-recap",
                title: "Chain-of-thought, in three lines",
                points: [
                    "Ask a model to write its steps before answering, and it gets multi-step problems right far more often.",
                    "You do it by example: show a few questions solved with their working, and the model copies the habit. No retraining.",
                    "It is an emergent ability: it barely helps small models, but unlocks a big jump once the model is large.",
                ]
            ),

            // 14 - Closing.
            .paperLink(
                id: "cot-source",
                quote: "The reasoning was already in there. The prompt just let it out.",
                attribution: "Wei et al. \u{00B7} Google \u{00B7} 2022",
                linkTitle: "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models",
                url: URL(string: "https://arxiv.org/abs/2201.11903")
            ),
        ]
    )
}
