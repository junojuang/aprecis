import SwiftUI

// MARK: - LeNet lesson (beginner-first redesign)
//
// The first network that could really see. Beginner arc: a relatable moment
// (you recognise the same drawing wherever it sits on paper), then the
// sliding-window trick that lets a computer do the same. Formula card gone.
// Sliding-filter / pooling / digit-vote interactives kept.

extension LearningLesson {

    static let lenet = LearningLesson(
        paperId: "loop:foundational:lenet",
        cards: [

            // 1 — Editorial cover.
            .cover(
                id: "lenet-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Teach it to see.",
                highlight: "see",
                standfirst: "1998. The network that learned to read handwriting, one tiny patch at a time.",
                hero: LeNetScanGlyph()
            ),

            // 2 — Relatable hook.
            .prose(
                id: "lenet-hook",
                kicker: "Start here",
                title: "Same drawing, anywhere on the page",
                paragraphs: [
                    [.plain("Draw a heart at the top of a page. Draw the same heart at the bottom. You see them and instantly know: same shape.")],
                    [.plain("Now imagine a computer. To it, the top heart and the bottom heart are "),
                     .highlight("completely different"),
                     .plain(" pictures. Not one matching pixel between them.")],
                    [.plain("How do you teach a computer to see past that? That\u{2019}s exactly what this paper figured out.")],
                ]
            ),

            // 3 — The problem in a picture.
            .illustrated(
                id: "lenet-shift",
                kicker: "The problem",
                title: "The same 7, never the same",
                paragraphs: [
                    [.plain("Write the digit seven a dozen times. Each one lands in a slightly different spot. A bit higher. A bit left. A bit bigger.")],
                    [.plain("To you, all sevens. To a computer, "),
                     .highlight("a dozen different pixel grids"),
                     .plain(" with almost nothing in common.")],
                ],
                caption: "One digit, three positions. Barely a shared pixel.",
                illustration: ShiftingSevenArt()
            ),

            // 4 — The trick, in plain words.
            .prose(
                id: "lenet-trick",
                kicker: "The trick",
                title: "Slide a little detector across the page",
                paragraphs: [
                    [.plain("Here\u{2019}s the move. Instead of looking at the whole page at once, you build a "),
                     .term("tiny detector"),
                     .plain(": a small grid of weights that lights up when it sees a certain shape, say, a vertical edge.")],
                    [.plain("Then you "),
                     .highlight("slide it across the whole page"),
                     .plain(", one spot at a time, and write down where it lit up.")],
                    [.plain("The detector finds its shape wherever it lives. Top, bottom, middle. Same answer.")],
                ]
            ),

            // 5 — Slide it yourself.
            .interactive(id: "lenet-conv") { progress in
                ConvSlideStudio(cardId: "lenet-conv", progress: progress)
            },

            // 6 — Trimmed glossary.
            .glossary(
                id: "lenet-glossary",
                intro: "Three words for the parts you just used. Worth knowing, easy to remember.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Filter",
                        definition: "The tiny detector itself. A small grid of numbers the network learns. One filter looks for one little pattern."),
                    LessonGlossaryTerm(
                        term: "Convolution",
                        definition: "The slide. Move the filter across the whole image and check at every spot. Fancy word for a simple action."),
                    LessonGlossaryTerm(
                        term: "Feature map",
                        definition: "The map of where the filter lit up. One per filter. Tells you where in the image that shape lives."),
                ]
            ),

            // 7 — Why it works: one detector, used everywhere.
            .illustrated(
                id: "lenet-share",
                kicker: "Why it works",
                title: "Learn the shape once. Use it everywhere.",
                paragraphs: [
                    [.plain("Because the "),
                     .term("same filter"),
                     .plain(" slides across every spot, the network only needs to learn one copy of each detector.")],
                    [.plain("A handful of tiny filters can replace hundreds of thousands of separate weights. "),
                     .highlight("Faster to train. Way less to remember."),
                     .plain(" And you get something for free: a detector trained in one spot already works in every spot.")],
                ],
                caption: "One learned filter, fanned out everywhere.",
                illustration: WeightShareArt()
            ),

            // 7b — Introduce pooling before its interactive, at point of need.
            .prose(
                id: "lenet-pool-why",
                kicker: "One more trick",
                title: "Stop sweating the exact spot",
                paragraphs: [
                    [.plain("Your detector might report a vertical edge at pixel 14. But you don\u{2019}t really care if it\u{2019}s at 14 or 15. A hair left or right, it\u{2019}s the "),
                     .highlight("same stroke"),
                     .plain(".")],
                    [.plain("So after each slide, the network does a quick shrink called "),
                     .term("pooling"),
                     .plain(": it sweeps the feature map in little blocks and keeps only the strongest hit in each. The map gets smaller, and the network stops fussing over the exact pixel.")],
                    [.plain("That tolerance is what finally makes a seven a seven, wherever on the page you wrote it.")],
                ]
            ),

            // 8 — Pooling demo.
            .interactive(id: "lenet-pool") { progress in
                PoolShiftStudio(cardId: "lenet-pool", progress: progress)
            },

            // 9 — Stack the trick.
            .prose(
                id: "lenet-hierarchy",
                kicker: "Stack the trick",
                title: "Edges, then shapes, then digits",
                paragraphs: [
                    [.plain("LeNet stacks this idea. The first layer finds the simplest things: little edges and strokes.")],
                    [.plain("The next layer doesn\u{2019}t look at raw pixels. It looks at the layer below. So it combines edges into "),
                     .highlight("corners, curves, loops"),
                     .plain(".")],
                    [.plain("Stack a few more times and the top layer is thinking in "),
                     .bold("whole digits"),
                     .plain(". Nobody told it that\u{2019}s how digits are built. It worked it out from a pile of examples.")],
                ]
            ),

            // 10 — Watch it read your drawing.
            .interactive(id: "lenet-vote") { progress in
                DigitVoteStudio(cardId: "lenet-vote", progress: progress)
            },

            // 11 — Where you've met it.
            .prose(
                id: "lenet-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s how computers see",
                paragraphs: [
                    [.plain("LeNet (1998) was actually reading the handwritten amount on real bank cheques in the United States by the late 90s. It worked.")],
                    [.plain("Then hardware caught up, and the same trick exploded outward. Every photo your phone "),
                     .bold("auto-tags"),
                     .plain(", every "),
                     .bold("face unlock"),
                     .plain(", every "),
                     .bold("instant translate"),
                     .plain(" of a sign through your camera, traces back to this paper.")],
                    [.plain("Slide a learned filter. Shrink the map. Repeat. "),
                     .highlight("That\u{2019}s still how computers see today."),
                     .plain("")],
                ]
            ),

            // 12 — Recap.
            .recap(
                id: "lenet-recap",
                title: "LeNet, in three lines",
                points: [
                    "The same drawing in different spots looks totally different to a computer. A plain network would have to relearn the shape everywhere.",
                    "The fix: a tiny detector that slides across the whole page. Learn the shape once, find it anywhere.",
                    "Stack a few of these and the network builds its own vocabulary: edges, then shapes, then whole objects. The blueprint every computer-vision model still uses.",
                ]
            ),

            // 13 — Closing.
            .paperLink(
                id: "lenet-paper",
                quote: "Better pattern recognition systems can be built by relying more on automatic learning and less on hand-designed rules.",
                attribution: "LeCun, Bottou, Bengio, Haffner \u{00B7} 1998",
                linkTitle: "Gradient-Based Learning Applied to Document Recognition",
                url: URL(string: "https://yann.lecun.com/exdb/publis/pdf/lecun-98.pdf")
            ),
        ]
    )
}
