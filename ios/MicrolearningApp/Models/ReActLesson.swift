import SwiftUI

// MARK: - ReAct lesson
//
// 2022, Yao et al. (Princeton / Google). Beginner-first, BERT/R1 tier. One
// idea: a model that only reasons can drift into confident nonsense, so let it
// act too. ReAct interleaves a Thought, an Action (use a tool), and an
// Observation (what came back), looping until done. Reasoning chooses what to
// look up; observations keep it honest. Three hands-on beats: run the loop,
// see grounding beat guessing, and choose the right action.

extension LearningLesson {

    static let reAct = LearningLesson(
        paperId: "loop:foundational:react",
        cards: [

            // 1 - Cover.
            .cover(
                id: "react-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Think, then look.",
                highlight: "look",
                standfirst: "2022. A model that only reasons can talk itself into nonsense. ReAct lets it act, check the world, and reason again.",
                hero: ReActGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "react-hook",
                kicker: "Start here",
                title: "Don't reason in the dark",
                paragraphs: [
                    [.plain("Asked a question you half-remember, you don't just think harder and harder until you are sure. At some point you "),
                     .bold("look it up"),
                     .plain(".")],
                    [.plain("Chain of thought only reasons. With nothing to check against, it can reason its way to a confident wrong answer.")],
                    [.plain("ReAct adds the missing half: the model can "),
                     .highlight("act on the world"),
                     .plain(" and react to what it finds.")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "react-idea",
                kicker: "The idea",
                title: "Reasoning and acting, together",
                paragraphs: [
                    [.plain("ReAct interleaves three moves: a "),
                     .term("thought"),
                     .plain(", an "),
                     .term("action"),
                     .plain(" such as a search, and an "),
                     .term("observation"),
                     .plain(" of what the action returned.")],
                    [.plain("The thoughts decide what to do; the observations feed real facts back in, so the reasoning stays "),
                     .highlight("anchored to reality"),
                     .plain(".")],
                ],
                caption: "Reason-only drifts. ReAct breaks the chain with a real lookup.",
                illustration: ReasonOnlyVsReActArt()
            ),

            // 4 - Run the loop.
            .interactive(id: "react-loop") { progress in
                ReActLoopStudio(cardId: "react-loop", progress: progress)
            },

            // 5 - On-ramp: why acting matters.
            .prose(
                id: "react-ground-rampup",
                kicker: "A puzzle first",
                title: "Why not just reason well?",
                paragraphs: [
                    [.plain("A model's memory is vast but imperfect, and it cannot tell which of its memories are wrong. So pure reasoning has no way to catch its own mistakes.")],
                    [.plain("An action breaks that trap. A single lookup can "),
                     .highlight("overrule a plausible-sounding belief"),
                     .plain(" with a fact.")],
                    [.plain("This is the main reason ReAct "),
                     .highlight("hallucinates less"),
                     .plain(" than reasoning alone.")],
                ]
            ),

            // 6 - Loop trace illustration.
            .illustrated(
                id: "react-trace-art",
                kicker: "The shape",
                title: "A trace you can read",
                paragraphs: [
                    [.plain("Every ReAct run leaves a readable trail: thought, action, observation, repeating until a "),
                     .term("finish"),
                     .plain(".")],
                    [.plain("You can see exactly what it looked up and why, which makes its answer far easier to "),
                     .highlight("trust and debug"),
                     .plain(" than a single opaque guess.")],
                ],
                caption: "One compact loop: think, search, observe, conclude.",
                illustration: LoopTraceArt()
            ),

            // 7 - Ground vs guess.
            .interactive(id: "react-ground") { progress in
                GroundVsGuessStudio(cardId: "react-ground", progress: progress)
            },

            // 8 - On-ramp: choosing actions.
            .prose(
                id: "react-action-rampup",
                kicker: "One idea first",
                title: "Acting is a decision too",
                paragraphs: [
                    [.plain("Having actions is not enough; the model has to pick the "),
                     .bold("right one"),
                     .plain(" at the right time.")],
                    [.plain("Search when a fact is missing. Finish when you already have it. A careless action just "),
                     .highlight("wastes a step"),
                     .plain(".")],
                    [.plain("So the reasoning is also choosing, at each turn, what to do next.")],
                ]
            ),

            // 9 - Action menu.
            .interactive(id: "react-action") { progress in
                ActionMenuStudio(cardId: "react-action", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "react-result",
                kicker: "The payoff",
                title: "Fewer made-up facts",
                paragraphs: [
                    [.plain("On question-answering and fact-verification tasks, interleaving reasoning with lookups beat reasoning alone and "),
                     .bold("cut hallucinated facts"),
                     .plain(", because every claim could be checked against an observation.")],
                    [.plain("It also made the model's behaviour "),
                     .highlight("legible"),
                     .plain(": you can read exactly what it did and why.")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "react-everyday",
                kicker: "Where you've met it",
                title: "Every AI that uses tools",
                paragraphs: [
                    [.plain("ReAct is the blueprint behind "),
                     .highlight("tool-using agents"),
                     .plain(": assistants that browse, run code, or call APIs, then read the results before continuing.")],
                    [.plain("When a chatbot says it is searching the web and then answers from what it found, it is running a ReAct-style loop.")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "react-recap",
                title: "ReAct, in three lines",
                points: [
                    "Pure reasoning has nothing to check against, so it can produce confident wrong answers.",
                    "ReAct interleaves thought, action, and observation, so the model can use tools and react to real results.",
                    "Grounding each step in an observation cuts hallucination and leaves a readable, trustworthy trail.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "react-source",
                quote: "Reasoning decides what to do. Acting tells you whether you were right.",
                attribution: "Yao et al. \u{00B7} 2022",
                linkTitle: "ReAct: Synergizing Reasoning and Acting in Language Models",
                url: URL(string: "https://arxiv.org/abs/2210.03629")
            ),
        ]
    )
}
