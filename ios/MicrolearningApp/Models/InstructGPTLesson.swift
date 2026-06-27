import SwiftUI

// MARK: - InstructGPT lesson
//
// 2022, OpenAI. Beginner-first, in the BERT and R1 mould: a curious
// 14-year-old should walk in and leave with a working mental model. The whole
// lesson rides one idea, told plainly: a giant model that knows a lot is not
// the same as a model that does what you ask, and you can close that gap with
// human feedback. Around it sit three hands-on beats, mirroring the paper's
// recipe: feel the gap, rank answers to build a reward model (SFT plus reward
// model), then run the RLHF loop and watch a reply improve.

extension LearningLesson {

    static let instructGPT = LearningLesson(
        paperId: "instructgpt",
        cards: [

            // 1 - Editorial cover.
            .cover(
                id: "instructgpt-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Teach it to listen.",
                highlight: "listen",
                standfirst: "2022. The paper that turned a know-it-all model into one that actually follows what you ask. The blueprint behind ChatGPT.",
                hero: InstructGPTGlyph()
            ),

            // 2 - Relatable hook. No AI words yet.
            .prose(
                id: "instructgpt-hook",
                kicker: "Start here",
                title: "The brilliant intern problem",
                paragraphs: [
                    [.plain("Imagine a new intern who has read the entire internet. They know an astonishing amount. But on day one you ask for a short email, and they hand you a "),
                     .bold("ten-page essay"),
                     .plain(" on the history of email.")],
                    [.plain("They are not dumb. They just don't yet know "),
                     .highlight("what you actually want"),
                     .plain(". Knowing a lot and being useful are two different things.")],
                    [.plain("In 2020, GPT-3 was exactly this intern. InstructGPT is the story of how we taught it to listen.")],
                ]
            ),

            // 3 - The big idea, in a picture.
            .illustrated(
                id: "instructgpt-idea",
                kicker: "The gap",
                title: "Predicting words is not following orders",
                paragraphs: [
                    [.plain("A raw language model is trained to do one thing: guess the "),
                     .highlight("next likely word"),
                     .plain(". Feed it your request and it just continues the text in a plausible way.")],
                    [.plain("Plausible is not the same as "),
                     .term("helpful"),
                     .plain(". Ask it to write a note and it might list more things to write. The intent gets lost.")],
                ],
                caption: "Same prompt. One predicts text, one does what you asked.",
                illustration: AlignmentGapArt()
            ),

            // 4 - Feel the gap yourself.
            .interactive(id: "instructgpt-gap") { progress in
                InstructionGapStudio(cardId: "instructgpt-gap", progress: progress)
            },

            // 5 - The fix, in three moves.
            .illustrated(
                id: "instructgpt-recipe",
                kicker: "The fix",
                title: "Three moves to close the gap",
                paragraphs: [
                    [.plain("You cannot just tell the model to "),
                     .bold("be helpful"),
                     .plain(". Helpful has no formula. So InstructGPT used people in three steps.")],
                    [.plain("First, "),
                     .term("show"),
                     .plain(" it good answers to copy. Then have people "),
                     .term("rank"),
                     .plain(" its tries to build a sense of taste. Then "),
                     .term("nudge"),
                     .plain(" it toward what people preferred.")],
                ],
                caption: "Demonstrate, rank, reinforce. The spine of the paper.",
                illustration: ThreeStepArt()
            ),

            // 6 - Gentle on-ramp to the reward model: you can't write the rule.
            .prose(
                id: "instructgpt-reward-rampup",
                kicker: "A puzzle first",
                title: "How do you grade \u{201C}good\u{201D}?",
                paragraphs: [
                    [.plain("Try to write down the rule for a good answer. Helpful? Honest? Kind? The moment you pin one down, you can picture an answer that ticks it and still feels wrong.")],
                    [.plain("Here is the trick people actually use every day. You may not be able to "),
                     .highlight("define"),
                     .plain(" the best answer, but shown a few, you can easily "),
                     .highlight("rank"),
                     .plain(" them.")],
                    [.plain("InstructGPT leaned on exactly that. Don't write the rule, just rank the options, and let the model learn the pattern. See it next.")],
                ]
            ),

            // 7 - The reward model, in a picture.
            .illustrated(
                id: "instructgpt-reward-art",
                kicker: "Step two",
                title: "Turn rankings into a scorer",
                paragraphs: [
                    [.plain("People rank a handful of answers best to worst. On its own that is just a pile of opinions.")],
                    [.plain("So those rankings train a second model, the "),
                     .term("reward model"),
                     .plain(", whose only job is to give any answer a "),
                     .highlight("score"),
                     .plain(" that matches what people preferred, even on prompts nobody ranked.")],
                ],
                caption: "Ranked answers in, a reusable answer-scorer out.",
                illustration: RankArt()
            ),

            // 8 - Do the ranking yourself.
            .interactive(id: "instructgpt-rank") { progress in
                RankStudio(cardId: "instructgpt-rank", progress: progress)
            },

            // 9 - Gentle on-ramp to RLHF: learning from a score, not an answer key.
            .prose(
                id: "instructgpt-rlhf-rampup",
                kicker: "One idea first",
                title: "Getting warmer, getting colder",
                paragraphs: [
                    [.plain("Think of the game where a friend says "),
                     .bold("warmer"),
                     .plain(" or "),
                     .bold("colder"),
                     .plain(" as you hunt for a hidden object. No one tells you the answer. A single hint per try is enough to home in.")],
                    [.plain("A model can learn the same way. It writes an answer, gets a "),
                     .highlight("score"),
                     .plain(" instead of a correction, and shifts toward whatever scored higher.")],
                    [.plain("Learning from a score like this has a name: "),
                     .term("reinforcement learning"),
                     .plain(". Point it at the reward model you just built, and the loop begins.")],
                ]
            ),

            // 10 - RLHF, in a picture.
            .illustrated(
                id: "instructgpt-rlhf-art",
                kicker: "Step three",
                title: "Generate, score, nudge",
                paragraphs: [
                    [.plain("The model writes an answer. The reward model scores it. That score "),
                     .highlight("nudges"),
                     .plain(" the model to do more of what scored well. Round after round, the answers get better.")],
                    [.plain("One safety rope: a "),
                     .term("leash"),
                     .plain(" that stops the model drifting too far from sensible language while it chases the score.")],
                ],
                caption: "A loop: write, score, nudge, repeat.",
                illustration: PPOLoopArt()
            ),

            // 11 - Run the RLHF loop.
            .interactive(id: "instructgpt-rlhf") { progress in
                RLHFLoopStudio(cardId: "instructgpt-rlhf", progress: progress)
            },

            // 12 - The headline result.
            .prose(
                id: "instructgpt-result",
                kicker: "The payoff",
                title: "Small and tuned beat big and raw",
                paragraphs: [
                    [.plain("Here is the line that stunned people. A tuned InstructGPT with "),
                     .bold("1.3 billion"),
                     .plain(" parameters was preferred by humans over GPT-3 with "),
                     .bold("175 billion"),
                     .plain(", a model over a hundred times larger.")],
                    [.plain("It was also more truthful and a little less toxic. The lesson: past a point, "),
                     .highlight("alignment beats raw size"),
                     .plain(". How you tune matters more than how big you build.")],
                ]
            ),

            // 13 - Where you've met it.
            .prose(
                id: "instructgpt-everyday",
                kicker: "Where you've met it",
                title: "This is the recipe behind ChatGPT",
                paragraphs: [
                    [.plain("Every time a chatbot answers your actual question instead of rambling, you are feeling InstructGPT's recipe at work.")],
                    [.plain("Demonstrate, rank, reinforce, now usually shortened to "),
                     .term("RLHF"),
                     .plain(", became the standard final polish for nearly every assistant that followed, ChatGPT first among them.")],
                ]
            ),

            // 14 - Recap, plain and short.
            .recap(
                id: "instructgpt-recap",
                title: "InstructGPT, in three lines",
                points: [
                    "A model that knows a lot is not the same as one that does what you ask.",
                    "You cannot write the rule for a good answer, but people can rank answers, and those rankings train a reward model.",
                    "Reinforcement learning then nudges the model toward preferred replies, so a small tuned model beat one a hundred times larger.",
                ]
            ),

            // 15 - Closing.
            .paperLink(
                id: "instructgpt-source",
                quote: "Bigger did not mean better aligned. Human feedback did.",
                attribution: "Ouyang et al. \u{00B7} OpenAI \u{00B7} 2022",
                linkTitle: "Training language models to follow instructions with human feedback",
                url: URL(string: "https://arxiv.org/abs/2203.02155")
            ),
        ]
    )
}
