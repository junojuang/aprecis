import SwiftUI

// MARK: - Backpropagation lesson (beginner-first redesign)
//
// The fix that let neural networks finally have a "middle" and learn it.
// Beginner arc: an everyday moment of figuring out which step ruined a
// recipe, then the same idea inside a stack of neurons. Formula card and
// pseudocode card removed. The kitchen-blame metaphor and the three
// bespoke interactives (blame flow, gradient valley, XOR breakthrough)
// stay.

extension LearningLesson {

    static let backprop = LearningLesson(
        paperId: "backprop",
        cards: [

            // 1 — Editorial cover.
            .cover(
                id: "backprop-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Send the mistake backward.",
                highlight: "backward",
                standfirst: "1986. The trick that finally let a neural network have a middle, and learn it.",
                hero: BackpropNetworkGlyph()
            ),

            // 2 — Relatable hook.
            .prose(
                id: "backprop-hook",
                kicker: "Start here",
                title: "Ever tried to figure out who messed up?",
                paragraphs: [
                    [.plain("Imagine you and three friends cook a meal together. Each of you does one step. You chop. The next person seasons. The next cooks. You serve.")],
                    [.plain("The meal tastes wrong. Whose fault was it? You can\u{2019}t blame everyone equally, that\u{2019}s lazy. You have to "),
                     .highlight("trace the mistake backward"),
                     .plain(" through the steps and work out which one really messed up.")],
                    [.plain("Backpropagation is a neural network doing exactly this, after every wrong answer.")],
                ]
            ),

            // 3 — The setup: a line of cooks. Existing illustration.
            .illustrated(
                id: "backprop-stack",
                kicker: "The setup",
                title: "A line of little decision-makers",
                paragraphs: [
                    [.plain("Picture a neural network as a "),
                     .term("line of cooks"),
                     .plain(". Each cook does a small step. The first cook works with the raw ingredients. The last cook plates the dish for you.")],
                    [.plain("In between are the "),
                     .highlight("middle cooks"),
                     .plain(", and they\u{2019}re the tricky ones.")],
                    [.plain("The middle cook never touches the ingredients. They never see the diner\u{2019}s face. When the meal is bad, how do you tell them what to fix?")],
                ],
                caption: "Each cook does one small step. The dish comes out at the end.",
                illustration: StackedCutsArt()
            ),

            // 4 — The puzzle this paper solved.
            .prose(
                id: "backprop-credit",
                kicker: "The puzzle",
                title: "Nobody could coach the middle",
                paragraphs: [
                    [.plain("For seventeen years this was the problem. Networks with just one neuron could learn. Networks with two layers could too.")],
                    [.plain("But the moment you added a "),
                     .term("middle layer"),
                     .plain(", nobody knew how to teach it. There was no way to tell the middle neurons whether they had helped or hurt.")],
                    [.plain("This paper fixed that.")],
                ]
            ),

            // 5 — Watch the blame travel backward.
            .interactive(id: "backprop-blame") { progress in
                BackpropBlameFlow(cardId: "backprop-blame", progress: progress)
            },

            // 6 — Trimmed glossary.
            .glossary(
                id: "backprop-glossary",
                intro: "Three words for what you just saw. Worth knowing, easy to remember.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Forward pass",
                        definition: "The cooking. The network takes an input, hands it down the line, and a guess comes out the other end."),
                    LessonGlossaryTerm(
                        term: "Loss",
                        definition: "One number for how wrong the guess was. Big number means \u{201C}very wrong.\u{201D} Zero means \u{201C}perfect.\u{201D}"),
                    LessonGlossaryTerm(
                        term: "Backpropagation",
                        definition: "The blame trace. Carrying the mistake backward through the network so every neuron, even the middle ones, gets told what to fix."),
                ]
            ),

            // 7 — From blame to fix, plain language.
            .prose(
                id: "backprop-downhill",
                kicker: "From blame to fix",
                title: "Every cook makes a tiny fix",
                paragraphs: [
                    [.plain("Once a cook has been told their share of the blame, they do the obvious thing. They tweak their work a little, "),
                     .highlight("in the opposite direction"),
                     .plain(" of the mistake.")],
                    [.plain("Researchers picture this as a ball rolling downhill. The mistake is a valley. Each cook puts a foot down on its side and "),
                     .term("rolls a tiny step downhill"),
                     .plain(". How big that step is, is called the "),
                     .term("learning rate"),
                     .plain(": too small and it crawls, too big and it overshoots the bottom.")],
                    [.plain("They can\u{2019}t see the whole landscape. They just feel the slope under them and step. Do this enough times and everyone settles at the bottom of the valley together.")],
                ]
            ),

            // 8 — Drive the rolling-ball yourself.
            .interactive(id: "backprop-valley") { progress in
                GradientDescentValley(cardId: "backprop-valley", progress: progress)
            },

            // 9 — The quiet surprise: the middle invents its own features.
            .illustrated(
                id: "backprop-representations",
                kicker: "The quiet surprise",
                title: "The middle invents its own helpers",
                paragraphs: [
                    [.plain("Once the middle could be coached, something nobody expected happened. The middle cooks "),
                     .highlight("invented their own specialties"),
                     .plain(", with no one telling them what to do.")],
                    [.plain("Show the network photos. One middle neuron drifts into noticing edges. Another notices corners. Another notices round blobs.")],
                    [.plain("No human wrote that down. The line of cooks worked out for itself which little patterns were worth caring about.")],
                ],
                caption: "Patterns no one programmed: a hidden layer's self-made specialties.",
                illustration: FeatureGridArt()
            ),

            // 10 — The payoff: the old wall, broken live.
            .interactive(id: "backprop-xor") { progress in
                XORBreakthrough(cardId: "backprop-xor", progress: progress)
            },

            // 11 — Where you've met it.
            .prose(
                id: "backprop-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It trains every AI alive",
                paragraphs: [
                    [.plain("Backpropagation didn\u{2019}t just unlock the field. It "),
                     .bold("became the field"),
                     .plain(".")],
                    [.plain("Every AI you\u{2019}ve heard of, ChatGPT, Midjourney, the model that recognises your face, the one in your phone keyboard, was taught by this exact process: guess, measure the mistake, "),
                     .highlight("send the blame backward"),
                     .plain(", make a tiny fix. Then do it a few billion more times.")],
                    [.plain("It\u{2019}s 40 years old. It never left.")],
                ],
                hero: AnyView(BackpropTimeline())
            ),

            // 12 — Recap.
            .recap(
                id: "backprop-recap",
                title: "Backprop, in three lines",
                points: [
                    "A network guesses, then measures how wrong it was. That mistake is one number.",
                    "The mistake is sent backward through the layers. Every neuron, even the buried middle ones, gets told its share of the blame.",
                    "Each neuron makes a tiny fix. Repeat billions of times and the network just\u{2026} works. This is how every AI is trained today.",
                ]
            ),

            // 13 — Closing.
            .paperLink(
                id: "backprop-source",
                quote: "The hidden units come to represent important features of the task domain.",
                attribution: "Rumelhart, Hinton & Williams \u{00B7} Nature \u{00B7} 1986",
                linkTitle: "Learning representations by back-propagating errors \u{00B7} 1986",
                url: URL(string: "https://www.nature.com/articles/323533a0")
            ),
        ]
    )
}
