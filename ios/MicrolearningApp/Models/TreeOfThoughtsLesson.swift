import SwiftUI

// MARK: - Tree-of-Thoughts lesson
//
// 2023, Yao et al. Beginner-first, BERT/R1 tier. One idea: a chain commits to
// a single line of reasoning and cannot recover from a wrong turn. Let the
// model branch into several thoughts, judge each, and search, pruning dead
// ends and backing up. Three hands-on beats: the model judges a partial
// thought, search a real Game-of-24 tree, and see why backtracking beats a
// single chain.

extension LearningLesson {

    static let treeOfThoughts = LearningLesson(
        paperId: "loop:foundational:tot",
        cards: [

            // 1 - Cover.
            .cover(
                id: "tot-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Let it explore.",
                highlight: "explore",
                standfirst: "2023. A chain of thought can't take back a wrong turn. A tree of thoughts can branch, judge, prune, and back up.",
                hero: TreeOfThoughtsGlyph()
            ),

            // 2 - Relatable hook.
            .prose(
                id: "tot-hook",
                kicker: "Start here",
                title: "Finding your way out of a maze",
                paragraphs: [
                    [.plain("In a maze you don't pick one path and march to the end no matter what. You try a turn, and if it dead-ends, you "),
                     .bold("walk back"),
                     .plain(" and try another.")],
                    [.plain("A chain of thought can't do that. It commits to one route and follows it off a cliff.")],
                    [.plain("In 2023, researchers let a model "),
                     .highlight("explore like a maze-solver"),
                     .plain(" instead, and hard puzzles fell.")],
                ]
            ),

            // 3 - Big idea.
            .illustrated(
                id: "tot-idea",
                kicker: "The idea",
                title: "Grow a tree, not a line",
                paragraphs: [
                    [.plain("A chain is a single line of steps. One wrong turn early and there is "),
                     .highlight("no way back"),
                     .plain(".")],
                    [.plain("A "),
                     .term("tree of thoughts"),
                     .plain(" branches: at each step the model proposes several next "),
                     .term("thoughts"),
                     .plain(", and a search explores them, abandoning the ones that lead nowhere.")],
                ],
                caption: "A chain hits a wall. A tree finds a way around.",
                illustration: ChainVsTreeArt()
            ),

            // 4 - Self-evaluation.
            .interactive(id: "tot-evaluate") { progress in
                EvaluateStudio(cardId: "tot-evaluate", progress: progress)
            },

            // 5 - On-ramp: what to do with those judgments.
            .prose(
                id: "tot-search-rampup",
                kicker: "A puzzle first",
                title: "A judge is not yet a plan",
                paragraphs: [
                    [.plain("Knowing a branch is hopeless is useful, but only if you act on it. So what does the model do with all those verdicts?")],
                    [.plain("It "),
                     .highlight("searches"),
                     .plain(". It keeps exploring the promising branches, drops the dead ones, and when a path stalls it "),
                     .highlight("backs up"),
                     .plain(" to the last good fork.")],
                    [.plain("Branch, judge, prune, repeat. That loop is the whole method.")],
                ]
            ),

            // 6 - Evaluate-and-prune illustration.
            .illustrated(
                id: "tot-prune-art",
                kicker: "The loop",
                title: "Keep the live branches",
                paragraphs: [
                    [.plain("From any state the model lists a few moves and labels each "),
                     .term("sure, maybe, or impossible"),
                     .plain(", judging whether the goal is still reachable.")],
                    [.plain("The impossible ones are "),
                     .highlight("pruned"),
                     .plain(" so no effort is wasted on them, and the search spends its time only where a solution might still live.")],
                ],
                caption: "Three moves, three verdicts. Prune the dead one.",
                illustration: EvaluatePruneArt()
            ),

            // 7 - Search the tree.
            .interactive(id: "tot-search") { progress in
                Game24TreeStudio(cardId: "tot-search", progress: progress)
            },

            // 8 - On-ramp: backtracking is the point.
            .prose(
                id: "tot-backtrack-rampup",
                kicker: "One idea first",
                title: "The power is in backing up",
                paragraphs: [
                    [.plain("It is easy to miss what just happened. The real magic was not the branching, it was the "),
                     .bold("backing up"),
                     .plain(".")],
                    [.plain("A wrong first move was not fatal. The search simply returned to the fork and chose differently, something a straight line of reasoning can never do.")],
                    [.plain("See the same dead-end move, handled both ways.")],
                ]
            ),

            // 9 - Chain vs tree.
            .interactive(id: "tot-chainvtree") { progress in
                ChainVsTreeStudio(cardId: "tot-chainvtree", progress: progress)
            },

            // 10 - Payoff.
            .prose(
                id: "tot-result",
                kicker: "The payoff",
                title: "From 4% to 74%",
                paragraphs: [
                    [.plain("On the Game of 24, the same model that solved about "),
                     .bold("4%"),
                     .plain(" of puzzles with a single chain solved around "),
                     .bold("74%"),
                     .plain(" once it could search a tree.")],
                    [.plain("Nothing was retrained. The model was simply allowed to "),
                     .highlight("explore and backtrack"),
                     .plain(" instead of guessing in one straight line.")],
                ]
            ),

            // 11 - Where you've met it.
            .prose(
                id: "tot-everyday",
                kicker: "Where you've met it",
                title: "When the AI 'thinks' before answering",
                paragraphs: [
                    [.plain("Tree of thoughts showed that reasoning could be a "),
                     .highlight("search"),
                     .plain(", not just a single confident guess, trading more thinking for better answers on hard problems.")],
                    [.plain("That idea, deliberate over many possibilities before committing, lives on in agents that plan and in reasoning models that weigh several lines of thought before they reply.")],
                ]
            ),

            // 12 - Recap.
            .recap(
                id: "tot-recap",
                title: "Tree of thoughts, in three lines",
                points: [
                    "A chain of thought commits to one line of reasoning and cannot recover from an early wrong turn.",
                    "A tree branches into several thoughts, has the model judge each as sure, maybe, or impossible, and prunes the dead ones.",
                    "By searching and backtracking it solves puzzles a single chain cannot, like jumping Game of 24 from 4% to 74%.",
                ]
            ),

            // 13 - Closing.
            .paperLink(
                id: "tot-source",
                quote: "Reasoning is not one straight line. It is a search you can back out of.",
                attribution: "Yao et al. \u{00B7} 2023",
                linkTitle: "Tree of Thoughts: Deliberate Problem Solving with Large Language Models",
                url: URL(string: "https://arxiv.org/abs/2305.10601")
            ),
        ]
    )
}
