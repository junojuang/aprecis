import SwiftUI

// MARK: - GPT-3 lesson (beginner-first redesign)
//
// The model that learned to learn from examples in the prompt. Beginner arc:
// teach a friend a new game by showing them a couple of rounds, not by
// sending them to school. Scaling-law formula removed. The few-shot,
// next-token, and scale-emergence studios stay, as does the closing
// "what the paper proved" chart.

extension LearningLesson {

    static let gpt3 = LearningLesson(
        paperId: "loop:foundational:gpt3",
        cards: [

            // Editorial cover.
            .cover(
                id: "gpt3-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "The AI that learned to learn.",
                highlight: "learned to learn",
                standfirst: "2020. A model so large that showing it three examples did the work of training it.",
                hero: PredictionFanGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "gpt3-hook",
                kicker: "Start here",
                title: "How you teach a friend a new game",
                paragraphs: [
                    [.plain("You don\u{2019}t send them to a course. You sit down at the table, "),
                     .highlight("show them a couple of rounds"),
                     .plain(", and they pick it up. After three hands of poker, they can play.")],
                    [.plain("Computers couldn\u{2019}t do that. Until GPT-3.")],
                    [.plain("This was the model that, for the first time, could pick up a brand new job from just a few examples you typed at it. No re-training. No new code. Just a few examples.")],
                ]
            ),

            // The big idea.
            .illustrated(
                id: "gpt3-idea",
                kicker: "The big idea",
                title: "Teach by example, not by training",
                paragraphs: [
                    [.plain("Imagine a new hire who has read every book ever written but has never done your specific job. You don\u{2019}t send them on a course. You hand them a "),
                     .term("sticky note"),
                     .plain(" with two or three worked examples and ask them to do the next one.")],
                    [.plain("That note is called the "),
                     .term("prompt"),
                     .plain(". GPT-3 works exactly this way: it learns a task from a few examples placed in front of it, "),
                     .highlight("and never changes itself to do so"),
                     .plain(".")],
                ],
                caption: "Two examples and a question, all on one note.",
                illustration: PromptNoteArt()
            ),

            // The old way.
            .prose(
                id: "gpt3-oldway",
                kicker: "The old way",
                title: "One model per job",
                paragraphs: [
                    [.plain("Before GPT-3, every task got its own model. A translator was trained on translations. A summariser, separately, on summaries.")],
                    [.plain("Each one needed "),
                     .bold("thousands of labelled examples"),
                     .plain(" and its own long training run. A new task meant starting from scratch.")],
                    [.plain("GPT-3\u{2019}s bet: train "),
                     .highlight("one model, once"),
                     .plain(", big enough to pick up any task from the prompt alone.")],
                ],
                hero: AnyView(TaskZooArt().frame(height: 96))
            ),

            // Try few-shot.
            .interactive(id: "gpt3-fewshot") { progress in
                FewShotPromptPlayground(cardId: "gpt3-fewshot", progress: progress)
            },

            // How it trains, plain.
            .illustrated(
                id: "gpt3-nexttoken",
                kicker: "How it trained",
                title: "One boring game, the whole internet",
                paragraphs: [
                    [.plain("GPT-3 was trained on one boring game, played billions of times: "),
                     .term("guess the next word"),
                     .plain(". Cover the end of a sentence, predict what comes next, check, adjust. (Strictly the model works in "),
                     .term("tokens"),
                     .plain(", chunks that are usually a word or a piece of one.)")],
                    [.plain("Do that across most of the public internet and something wild happens. To guess the next word well, the model has to "),
                     .highlight("pick up grammar, facts, styles, even reasoning"),
                     .plain(". Prediction forces understanding.")],
                ],
                caption: "The model ranks every possible next word, then picks.",
                illustration: NextTokenArt()
            ),

            // Generate yourself.
            .interactive(id: "gpt3-generate") { progress in
                NextTokenPlayground(cardId: "gpt3-generate", progress: progress)
            },

            // The size.
            .illustrated(
                id: "gpt3-scale",
                kicker: "The size",
                title: "A hundred times bigger",
                paragraphs: [
                    [.plain("GPT-3\u{2019}s big bet rested on one number: "),
                     .term("175 billion parameters"),
                     .plain(". Roughly a hundred times bigger than the biggest language model before it.")],
                    [.plain("Training it cost millions of dollars and ran for weeks across thousands of chips. "),
                     .highlight("Size was the whole experiment."),
                     .plain("")],
                ],
                caption: "GPT-3 next to the models that came just before it.",
                illustration: ScaleBarsArt()
            ),

            // Scale demo.
            .interactive(id: "gpt3-emergence") { progress in
                ScaleEmergencePlayground(cardId: "gpt3-emergence", progress: progress)
            },

            // Emergence.
            .prose(
                id: "gpt3-emergent",
                kicker: "What scale unlocked",
                title: "Skills nobody trained for",
                paragraphs: [
                    [.plain("Here\u{2019}s the strange part. At small sizes the model could barely hold a sentence together, and nothing in its training ever mentioned arithmetic.")],
                    [.plain("Yet past a certain size it could "),
                     .highlight("add three-digit numbers, translate, write working code"),
                     .plain(". These are called "),
                     .term("emergent abilities"),
                     .plain(": skills that appear suddenly when the model gets big enough.")],
                    [.plain("Nobody added a maths module. The same next-word game, run on a large enough model, simply produced it.")],
                ]
            ),

            // The honest catch.
            .prose(
                id: "gpt3-catch",
                kicker: "The honest catch",
                title: "It predicts. It doesn\u{2019}t know.",
                paragraphs: [
                    [.plain("GPT-3 is a "),
                     .bold("next-word predictor"),
                     .plain(", not a mind. It has no memory of being right or wrong. It will tell you a confident answer that\u{2019}s completely made up.")],
                    [.plain("But the few-shot result changed the field overnight. If one model could be steered to any task by words alone, the road to a general assistant was suddenly clear.")],
                    [.plain("Two years later that line of work became "),
                     .highlight("ChatGPT"),
                     .plain(".")],
                ],
                hero: AnyView(GPT3Timeline())
            ),

            // Where you've met it.
            .prose(
                id: "gpt3-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s the reason \u{201C}AI\u{201D} is in your life",
                paragraphs: [
                    [.plain("Before GPT-3, AI was something behind the scenes. After GPT-3, you could just\u{2026} chat with it.")],
                    [.plain("Every "),
                     .bold("ChatGPT"),
                     .plain(" reply, every "),
                     .bold("Claude"),
                     .plain(" essay, every "),
                     .bold("Copilot"),
                     .plain(" code suggestion, every "),
                     .bold("Bing/Google AI overview"),
                     .plain(" answer, traces back here. They\u{2019}re all GPT-3\u{2019}s grandchildren.")],
                    [.plain("And the habit it taught the field, "),
                     .highlight("just make the model bigger"),
                     .plain(", still drives every breakthrough today.")],
                ]
            ),

            // Consolidating glossary: every term has now appeared in the flow.
            .glossary(
                id: "gpt3-glossary",
                intro: "The four words GPT-3 brought into everyday use, all in one place.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Prompt",
                        definition: "Everything you type at the model: instructions, examples, your question. All as plain text."),
                    LessonGlossaryTerm(
                        term: "Token",
                        definition: "One chunk of text the model reads or writes. Usually a word or part of a word."),
                    LessonGlossaryTerm(
                        term: "Few-shot",
                        definition: "Showing the model two or three worked examples in the prompt so it picks up the task. No training needed."),
                    LessonGlossaryTerm(
                        term: "Parameter",
                        definition: "One of the model\u{2019}s tunable knobs, set during training. GPT-3 has 175 billion of them."),
                ]
            ),

            // Recap.
            .recap(
                id: "gpt3-recap",
                title: "GPT-3, in three lines",
                points: [
                    "GPT-3 learns a new task from a few examples in the prompt. No re-training, no new code, no extra data.",
                    "It was built by playing one boring game: guess the next word, across most of the public internet.",
                    "Scale was the trick. At 175 billion parameters, skills nobody trained for, arithmetic, translation, code, just appeared.",
                ]
            ),

            // What the paper proved.
            .illustrated(
                id: "gpt3-finding",
                kicker: "What the paper proved",
                title: "Bigger models use the prompt better",
                paragraphs: [
                    [.plain("Here\u{2019}s the honest surprise. GPT-3 introduced no new method. Its design was already two years old. What this paper contributed was "),
                     .term("evidence"),
                     .plain(".")],
                    [.plain("Across dozens of tasks, accuracy climbs with size. And the bigger the model, "),
                     .highlight("the better it uses the examples in its own prompt"),
                     .plain(".")],
                    [.plain("That reframed the whole field. Progress no longer meant inventing new tricks. It meant building bigger models.")],
                ],
                caption: "Three prompt settings, four model sizes. The few-shot line pulls away.",
                illustration: FewShotScalingChart()
            ),

            // Closing.
            .paperLink(
                id: "gpt3-source",
                quote: "Just show it a few examples. It will do the rest.",
                attribution: "Brown, Mann, Ryder et al. \u{00B7} NeurIPS \u{00B7} 2020",
                linkTitle: "Language Models are Few-Shot Learners \u{00B7} 2020",
                url: URL(string: "https://arxiv.org/abs/2005.14165")
            ),
        ]
    )
}
