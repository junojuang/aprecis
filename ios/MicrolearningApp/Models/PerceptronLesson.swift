import SwiftUI

// MARK: - Perceptron lesson (beginner-first redesign)
//
// One artificial neuron, taught by its own mistakes. The lesson opens on a
// relatable everyday moment (judging a thing by weighing a few clues), then
// hands over the neuron in plain words, one bespoke interactive at a time.
// Scary cards (decision-rule formula, update-rule formula, eight-line code)
// are gone. A short "where you've met it" beat closes the arc before the
// recap.

extension LearningLesson {

    static let perceptron = LearningLesson(
        paperId: "loop:foundational:perceptron",
        cards: [

            // 1 — Editorial cover.
            .cover(
                id: "perceptron-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "The first machine that learned.",
                highlight: "learned",
                standfirst: "1958. One little artificial neuron, taught entirely by its own mistakes.",
                hero: NeuronGlyph()
            ),

            // 2 — Relatable hook. No AI words yet.
            .prose(
                id: "perceptron-hook",
                kicker: "Start here",
                title: "You already do this",
                paragraphs: [
                    [.plain("A friend says, \u{201C}You\u{2019}ll love this new band.\u{201D} How do you decide if you\u{2019}ll really love them?")],
                    [.plain("You probably weigh a few things in your head. Are they your kind of music? Do you trust this friend\u{2019}s taste? Is the song short enough to even try?")],
                    [.plain("You add it all up and "),
                     .highlight("decide yes or no"),
                     .plain(". The first AI ever built worked exactly like that. It\u{2019}s called the perceptron.")],
                ]
            ),

            // 3 — The big idea, illustrated.
            .illustrated(
                id: "perceptron-idea",
                kicker: "What it is",
                title: "One tiny decision maker",
                paragraphs: [
                    [.plain("A perceptron is a maths gadget with three jobs:")],
                    [.plain("It takes in a "),
                     .term("few clues"),
                     .plain(" (numbers). It decides "),
                     .term("how much each clue counts"),
                     .plain(". It adds them up. If the total is high enough, it says "),
                     .bold("yes"),
                     .plain(". Otherwise it says "),
                     .bold("no"),
                     .plain(".")],
                    [.plain("That\u{2019}s it. "),
                     .highlight("Three clues in, one yes-or-no out."),
                     .plain(" The whole machine.")],
                ],
                caption: "A few signals in, one decision out.",
                illustration: SignalFlowArt()
            ),

            // 4 — Try it yourself: become the weights.
            .interactive(id: "perceptron-neuron") { progress in
                PerceptronNeuronPlayground(cardId: "perceptron-neuron", progress: progress)
            },

            // 5 — Trimmed glossary.
            .glossary(
                id: "perceptron-glossary",
                intro: "Four words you just used. Worth knowing, easy to remember.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Input",
                        definition: "One clue. A number the neuron looks at. Could be \u{201C}is it loud?\u{201D} as a 0 or a 1, or \u{201C}how loud?\u{201D} as 0.7."),
                    LessonGlossaryTerm(
                        term: "Weight",
                        definition: "How much one clue counts. Big weight means that clue matters a lot. Small weight means the neuron mostly ignores it."),
                    LessonGlossaryTerm(
                        term: "Threshold",
                        definition: "The line the total has to cross for the neuron to say yes. Below it, the neuron stays quiet."),
                    LessonGlossaryTerm(
                        term: "Fire",
                        definition: "The yes. Borrowed from real brain cells, which \u{201C}fire\u{201D} a little electric pulse when their signal is strong enough."),
                ]
            ),

            // 6 — Learning, narrated. No formula.
            .prose(
                id: "perceptron-learns-prose",
                kicker: "How it learns",
                title: "Tiny nudges, one mistake at a time",
                paragraphs: [
                    [.plain("On day one the neuron is hopeless. It guesses randomly. Most calls are wrong.")],
                    [.plain("After every wrong guess, someone tells it the right answer. That\u{2019}s the only feedback it gets. No rules, no rules-of-thumb, no explanation.")],
                    [.plain("The neuron does the simplest thing possible: "),
                     .highlight("it nudges its weights a tiny bit toward right"),
                     .plain(". Mistake, nudge. Mistake, nudge. Do this enough times and the neuron just\u{2026} starts getting it.")],
                ],
                hero: AnyView(ThreeNightsStrip().frame(height: 100))
            ),

            // 7 — Picture: dots on a map, line across it.
            .illustrated(
                id: "perceptron-map",
                kicker: "Picture it on paper",
                title: "Dots on a map, a line across it",
                paragraphs: [
                    [.plain("Here\u{2019}s the picture researchers use. Every example is a dot on a small map. The dot\u{2019}s position is just its clues.")],
                    [.plain("Teal dots are yes-people. Rose dots are no-people. The perceptron\u{2019}s job is to draw "),
                     .highlight("one straight line"),
                     .plain(" with teals on one side and roses on the other.")],
                    [.plain("Every time it makes a mistake, that line tilts a tiny bit. Eventually it lands in the right spot.")],
                ],
                caption: "Each example is a dot. The line is the perceptron\u{2019}s rule.",
                illustration: LinearSeparationDiagram()
            ),

            // 8 — Drive the learning yourself.
            .interactive(id: "perceptron-learns") { progress in
                PerceptronBoundaryLearner(cardId: "perceptron-learns", progress: progress)
            },

            // 9 — The ceiling, in plain words.
            .prose(
                id: "perceptron-wall-prose",
                kicker: "The catch",
                title: "And here\u{2019}s where it stops",
                paragraphs: [
                    [.plain("One perceptron only knows one trick: drawing a single straight line.")],
                    [.plain("Sometimes a straight line is enough. Sometimes the yes-dots and no-dots are tangled together in a pattern "),
                     .bold("no straight line"),
                     .plain(" can split. Try whatever angle you like, you\u{2019}ll always get at least two wrong.")],
                    [.plain("This was the wall that stopped the field for a decade. The way past it (we\u{2019}ll see in the very next paper) was to "),
                     .highlight("stack many perceptrons together"),
                     .plain(".")],
                ],
                hero: AnyView(WallTypographicMoment())
            ),

            // 10 — Feel the wall.
            .interactive(id: "perceptron-catch") { progress in
                XORWall(cardId: "perceptron-catch", progress: progress)
            },

            // 11 — Where you've met it (modern relevance).
            .prose(
                id: "perceptron-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It never really left",
                paragraphs: [
                    [.plain("The perceptron is from 1958, but the idea is still everywhere.")],
                    [.plain("Your "),
                     .bold("email spam filter"),
                     .plain(" works like this. It weighs clues (does the subject shout? are there weird links?), adds them up, and either drops the email in your inbox or in spam.")],
                    [.plain("Every modern AI, even ChatGPT, is built from "),
                     .highlight("billions of neurons stacked into layers"),
                     .plain(". Each one is still doing the perceptron\u{2019}s tiny job: weigh, add, decide.")],
                ]
            ),

            // 12 — Recap.
            .recap(
                id: "perceptron-recap",
                title: "The perceptron, in three lines",
                points: [
                    "It weighs a few clues, adds them up, and says yes when the total crosses a line.",
                    "It teaches itself: every mistake nudges its weights a little closer to right.",
                    "One perceptron can only draw a straight line. Stack a bunch of them and you get every modern AI.",
                ]
            ),

            // 13 — Closing.
            .paperLink(
                id: "perceptron-source",
                quote: "All later neural networks are just very deep perceptrons.",
                attribution: "Rosenblatt \u{00B7} Psychological Review \u{00B7} 1958",
                linkTitle: "The Perceptron \u{00B7} Frank Rosenblatt, 1958",
                url: URL(string: "https://psycnet.apa.org/doi/10.1037/h0042519")
            ),
        ]
    )

    // MARK: registry

    private static let registry: [String: LearningLesson] = [
        perceptron.paperId: perceptron,
        backprop.paperId: backprop,
        lenet.paperId: lenet,
        alexnet.paperId: alexnet,
        resnet.paperId: resnet,
        seq2seq.paperId: seq2seq,
        gans.paperId: gans,
        attention.paperId: attention,
        gpt3.paperId: gpt3,
        word2vec.paperId: word2vec,
        bert.paperId: bert,
        instructGPT.paperId: instructGPT,
        chainOfThought.paperId: chainOfThought,
        scratchpad.paperId: scratchpad,
        selfConsistency.paperId: selfConsistency,
        treeOfThoughts.paperId: treeOfThoughts,
        leastToMost.paperId: leastToMost,
        reAct.paperId: reAct,
        toolformer.paperId: toolformer,
        grokking.paperId: grokking,
        deepseekR1.paperId: deepseekR1,
    ]

    static func forPaperId(_ id: String) -> LearningLesson? {
        registry[RelatedPapers.preferredId(for: id)]
    }
}
