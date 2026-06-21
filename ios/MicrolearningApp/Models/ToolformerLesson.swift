import SwiftUI

// MARK: - Toolformer lesson
//
// 2023, Schick et al. (Meta). Beginner-first, BERT/R1 tier. One idea: instead
// of hand-wiring tools, let the model teach itself when to call them. It tries
// candidate API calls in its own text, runs them, and keeps only the ones whose
// results make the next words easier to predict, then trains on that. Three
// hands-on beats: splice in a call, run the self-supervised filter, and pick
// the right tool.

extension LearningLesson {

    static let toolformer = LearningLesson(
        paperId: "loop:foundational:toolformer",
        cards: [

            // 1 - Cover.
            .cover(
                id: "tf-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "It learns to use tools.",
                highlight: "tools",
                standfirst: "2023. Nobody taught it where a calculator helps. The model figured that out itself, by trying calls and keeping the ones that paid off.",
                hero: ToolformerGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "tf-hook",
                kicker: "Start here",
                title: "Reach for the calculator",
                paragraphs: [
                    [.plain("You don't multiply big numbers in your head. You grab a calculator, and you "),
                     .bold("know when to"),
                     .plain(" without being told.")],
                    [.plain("A language model is great at words but shaky at arithmetic, fresh facts, and dates. The obvious fix is to let it call tools.")],
                    [.plain("The clever part of Toolformer is that it learned "),
                     .highlight("when and how to call them by itself"),
                     .plain(".")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "tf-idea",
                kicker: "The idea",
                title: "Write the call into the text",
                paragraphs: [
                    [.plain("A tool call is just text the model writes, like "),
                     .term("[Calculator(400/1400)]"),
                     .plain(", which an external program runs, pasting the result back into the sentence.")],
                    [.plain("So the same model that writes words can write "),
                     .highlight("API calls"),
                     .plain(" exactly where a fact or a sum is needed.")],
                ],
                caption: "No tool: a wrong guess. With a tool: the call is run and spliced in.",
                illustration: WithoutVsWithToolArt()
            ),

            // 4 - Splice in a call.
            .interactive(id: "tf-inline") { progress in
                InlineCallStudio(cardId: "tf-inline", progress: progress)
            },

            // 5 - On-ramp: who labels the data?
            .prose(
                id: "tf-filter-rampup",
                kicker: "A puzzle first",
                title: "But who marks where calls go?",
                paragraphs: [
                    [.plain("To train this you would seem to need a person tagging every spot a tool belongs, across billions of words. That does not scale.")],
                    [.plain("Toolformer's trick is to let the model "),
                     .highlight("grade its own calls"),
                     .plain(". It tries a call, runs it, and checks one thing: did the result make the next words easier to predict?")],
                    [.plain("Calls that help are kept; calls that don't are thrown away. No human labels needed.")],
                ]
            ),

            // 6 - Toolbox illustration.
            .illustrated(
                id: "tf-toolbox-art",
                kicker: "The toolbox",
                title: "A handful of tools",
                paragraphs: [
                    [.plain("Toolformer learned a small set: a "),
                     .highlight("calculator"),
                     .plain(", a question-answering search, a "),
                     .highlight("calendar"),
                     .plain(", and a translator.")],
                    [.plain("Each has a narrow job, and the model learned which blanks call for which tool from its own filtered data.")],
                ],
                caption: "Four tools, each with one clear job.",
                illustration: ToolboxArt()
            ),

            // 7 - Self-supervised filter.
            .interactive(id: "tf-filter") { progress in
                SelfFilterStudio(cardId: "tf-filter", progress: progress)
            },

            // 8 - On-ramp: choosing the tool.
            .prose(
                id: "tf-pick-rampup",
                kicker: "One idea first",
                title: "The right tool, not just a tool",
                paragraphs: [
                    [.plain("Calling a tool only helps if it is the "),
                     .bold("right"),
                     .plain(" tool. A calculator will not tell you a future date, and a calendar will not translate a word.")],
                    [.plain("From its self-graded data the model learned to "),
                     .highlight("match each situation to the tool that fits"),
                     .plain(".")],
                ]
            ),

            // 9 - Pick the tool.
            .interactive(id: "tf-toolbox") { progress in
                ToolboxStudio(cardId: "tf-toolbox", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "tf-result",
                kicker: "The payoff",
                title: "A small model that punches up",
                paragraphs: [
                    [.plain("With tools, a modest model "),
                     .bold("beat far larger ones"),
                     .plain(" on tasks needing arithmetic, facts, and dates, while keeping its ordinary language skills intact.")],
                    [.plain("And it was all "),
                     .highlight("self-taught"),
                     .plain(": the only supervision was whether a call helped predict the next words.")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "tf-everyday",
                kicker: "Where you've met it",
                title: "Plugins, function calling, agents",
                paragraphs: [
                    [.plain("Toolformer made "),
                     .highlight("tool use"),
                     .plain(" a native skill of a language model, not a bolt-on.")],
                    [.plain("It is the ancestor of function calling, plugins, and the tool-using agents that now run code, query databases, and search the web on your behalf.")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "tf-recap",
                title: "Toolformer, in three lines",
                points: [
                    "A tool call is just text the model writes, run by an external program, with the result pasted back in.",
                    "The model teaches itself where calls belong by keeping only those whose results help predict the next words.",
                    "Self-taught tool use let a small model beat much larger ones on arithmetic, facts, and dates.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "tf-source",
                quote: "It did not need to be told where a tool helps. It found out, and kept what worked.",
                attribution: "Schick et al. \u{00B7} Meta \u{00B7} 2023",
                linkTitle: "Toolformer: Language Models Can Teach Themselves to Use Tools",
                url: URL(string: "https://arxiv.org/abs/2302.04761")
            ),
        ]
    )
}
