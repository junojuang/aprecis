import SwiftUI

// MARK: - ResNet lesson (beginner-first redesign)
//
// The shortcut that let networks go from 8 layers to 152. Beginner arc:
// passing a note through a long line of friends, the message fades. ResNet's
// move is letting it skip ahead. Formula card and code card removed.
// Degradation studio, skip flow studio, identity tower studio kept.

extension LearningLesson {

    static let resnet = LearningLesson(
        paperId: "loop:foundational:resnet",
        cards: [

            .cover(
                id: "resnet-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Let it skip ahead.",
                highlight: "skip",
                standfirst: "2015. One little shortcut wire. Image networks went from 8 layers to over 150.",
                hero: ResNetGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "resnet-hook",
                kicker: "Start here",
                title: "Ever played telephone?",
                paragraphs: [
                    [.plain("You whisper a sentence in a friend\u{2019}s ear. They whisper it to the next person. And so on, down a long line.")],
                    [.plain("By the end, the sentence is "),
                     .highlight("a mess"),
                     .plain(". Every person changed it a little. Across twenty people, the original is gone.")],
                    [.plain("This paper noticed that neural networks have the exact same problem when they get really deep, and figured out one tiny fix that saved everything.")],
                ]
            ),

            // What depth is for.
            .illustrated(
                id: "resnet-idea",
                kicker: "First, why depth matters",
                title: "Seeing happens in stages",
                paragraphs: [
                    [.plain("A network doesn\u{2019}t understand a photo in one glance. It works in stages. The first stage just sees dots of colour: "),
                     .term("raw pixels"),
                     .plain(".")],
                    [.plain("The next stage groups dots into edges. The next combines edges into shapes (a curve, an ear). The next assembles shapes into whole objects.")],
                    [.plain("Each stage is one layer. "),
                     .highlight("More layers means more stages of understanding."),
                     .plain(" So obviously more layers should be better, right?")],
                ],
                caption: "Pixels become edges become shapes become a face.",
                illustration: FeatureHierarchyArt()
            ),

            // The puzzle.
            .illustrated(
                id: "resnet-puzzle",
                kicker: "The puzzle",
                title: "Deeper made it worse",
                paragraphs: [
                    [.plain("Researchers tried it. They stacked more layers. And\u{2026} the deeper network did "),
                     .highlight("worse"),
                     .plain(".")],
                    [.plain("Not on new photos. On the exact same photos it had already studied. That ruled out the usual problem of memorising.")],
                    [.plain("A 56-layer network was worse than a 20-layer one. Something inside was just\u{2026} breaking.")],
                ],
                caption: "More layers, more errors. The opposite of what should happen.",
                illustration: DegradationPlotArt()
            ),

            // Turn the depth dial yourself.
            .prose(
                id: "resnet-degrade-intro",
                kicker: "See it for yourself",
                title: "Turn the depth dial",
                paragraphs: [
                    [.plain("This diagram lets you do what broke the field\u{2019}s plan.")],
                    [.plain("Drag a plain network deeper. Watch how well it does on photos it already studied. Then flip the same network to use skip connections. Compare.")],
                    [.plain("One keeps improving with depth. The other doesn\u{2019}t.")],
                ]
            ),

            .interactive(id: "resnet-degrade") { progress in
                DegradeStudio(cardId: "resnet-degrade", progress: progress)
            },

            // Why it happens.
            .illustrated(
                id: "resnet-why",
                kicker: "What was breaking",
                title: "The fix-it message faded",
                paragraphs: [
                    [.plain("Remember how networks learn (from the backprop paper)? The mistake is sent "),
                     .term("backward"),
                     .plain(" through every layer, telling each one how to adjust.")],
                    [.plain("Every layer it passes through shrinks the message a little. Cross a hundred layers and the message is a "),
                     .highlight("whisper by the time it reaches the early layers"),
                     .plain(".")],
                    [.plain("It\u{2019}s the telephone game, in reverse. The early layers never hear what to fix. They just sit there, untrained, and drag the whole network down.")],
                ],
                caption: "Loud at the top, a whisper at the bottom.",
                illustration: FadingSignalArt()
            ),

            // Watch the signal fade or survive.
            .interactive(id: "resnet-skip") { progress in
                SkipFlowStudio(cardId: "resnet-skip", progress: progress)
            },

            // The fix.
            .illustrated(
                id: "resnet-block",
                kicker: "The fix",
                title: "Give every layer a shortcut",
                paragraphs: [
                    [.plain("ResNet\u{2019}s move: around every small group of layers, add a "),
                     .term("shortcut wire"),
                     .plain(", a "),
                     .term("skip connection"),
                     .plain(", that carries the input straight across, unchanged.")],
                    [.plain("Now the fix-it message has a "),
                     .highlight("clear road"),
                     .plain(" all the way down. It runs the skip connections without fading.")],
                    [.plain("And there\u{2019}s a bonus. The layers don\u{2019}t have to redo their input from scratch. They only learn the small leftover change to add on top, called the "),
                     .term("residual"),
                     .plain(". That is where the name ResNet comes from, and it is far easier to learn.")],
                ],
                caption: "Input takes the shortcut. The layers add only a small correction.",
                illustration: ResidualBlockArt()
            ),

            // Stack the block.
            .interactive(id: "resnet-tower") { progress in
                IdentityTowerStudio(cardId: "resnet-tower", progress: progress)
            },

            // The payoff.
            .illustrated(
                id: "resnet-deep",
                kicker: "The payoff",
                title: "8 layers became 152",
                paragraphs: [
                    [.plain("With shortcuts everywhere, the limit fell away. The 2015 paper trained a network "),
                     .term("152 layers deep"),
                     .plain(", almost twenty times AlexNet, and it kept getting better the whole way down.")],
                    [.plain("It won the big 2015 image contest with an error rate "),
                     .highlight("below what a careful human usually scores"),
                     .plain(".")],
                    [.plain("Then variants ran past a thousand layers. Depth stopped being scary.")],
                ],
                caption: "Each year deeper. ResNet broke the climb wide open.",
                illustration: DepthLeapArt()
            ),

            // Where you've met it.
            .prose(
                id: "resnet-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s inside almost everything",
                paragraphs: [
                    [.plain("Shortcut wires turned out to be one of those ideas that quietly goes everywhere.")],
                    [.plain("They\u{2019}re inside the Transformer (the next big idea you\u{2019}ll meet), which means they\u{2019}re inside "),
                     .bold("ChatGPT, Claude, Gemini"),
                     .plain(", every big AI you\u{2019}ve heard of.")],
                    [.plain("They\u{2019}re in your phone\u{2019}s "),
                     .bold("camera AI"),
                     .plain(", in "),
                     .bold("self-driving cars"),
                     .plain(", in "),
                     .bold("medical scanners"),
                     .plain(". After this paper, depth was just a dial you turned up.")],
                ]
            ),

            // Consolidating glossary: every term has now appeared in the flow.
            .glossary(
                id: "resnet-glossary",
                intro: "The four words, all in one place.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Depth",
                        definition: "How many layers a network has. More layers = more stages of understanding."),
                    LessonGlossaryTerm(
                        term: "Skip connection",
                        definition: "A little wire that lets the input jump straight across a layer instead of going through it. The whole trick of this paper."),
                    LessonGlossaryTerm(
                        term: "Identity",
                        definition: "Doing nothing. The skip wire just hands the input through, unchanged. Sounds boring, turns out to be magic."),
                    LessonGlossaryTerm(
                        term: "Residual",
                        definition: "The leftover. Instead of redoing everything from scratch, each layer only learns the small change to add."),
                ]
            ),

            // Recap.
            .recap(
                id: "resnet-recap",
                title: "ResNet, in three lines",
                points: [
                    "Networks should get smarter with more layers. But past a point, deeper actually got worse, even on photos they had already studied.",
                    "The cause was the fix-it message fading away as it travelled back through too many layers. The early layers never heard what to learn.",
                    "Adding shortcut wires around every small group of layers gave the message a clear road. Networks could finally go hundreds of layers deep.",
                ]
            ),

            // Closing.
            .paperLink(
                id: "resnet-paper",
                quote: "Skip a layer. The signal arrives.",
                attribution: "He, Zhang, Ren, Sun \u{00B7} CVPR \u{00B7} 2015",
                linkTitle: "Deep Residual Learning for Image Recognition \u{00B7} 2015",
                url: URL(string: "https://arxiv.org/abs/1512.03385")
            ),
        ]
    )
}
