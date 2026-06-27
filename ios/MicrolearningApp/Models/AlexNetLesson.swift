import SwiftUI

// MARK: - AlexNet lesson (beginner-first redesign)
//
// The 2012 win that ended the argument. Beginner arc: you already recognise a
// dog without being told the rules, that's all AlexNet does. Two practical
// walls (saturating activations, memorising) framed as "two old problems"
// rather than gradient-vanishing jargon. Interactives kept: ReLU studio,
// Dropout studio, Scale studio.

extension LearningLesson {

    static let alexnet = LearningLesson(
        paperId: "alexnet",
        cards: [

            .cover(
                id: "alexnet-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Deep, at last.",
                highlight: "Deep",
                standfirst: "2012. The network that won by a mile, ended the argument, and started today\u{2019}s AI boom.",
                hero: AlexNetGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "alexnet-hook",
                kicker: "Start here",
                title: "You\u{2019}re a better dog-spotter than you think",
                paragraphs: [
                    [.plain("Look at a photo of a dog. You know it\u{2019}s a dog. Instantly. You didn\u{2019}t run a checklist of \u{201C}has fur, has tail, has ears.\u{201D}")],
                    [.plain("You just "),
                     .highlight("recognised"),
                     .plain(" it, because you\u{2019}ve seen thousands of dogs in your life. Nobody handed you the rules.")],
                    [.plain("AlexNet is a computer that learned to see the same way. Show it a million labelled photos and it works out, on its own, what each thing looks like.")],
                ]
            ),

            // Big idea, illustrated.
            .illustrated(
                id: "alexnet-bigidea",
                kicker: "The big idea",
                title: "Learn from examples, not rules",
                paragraphs: [
                    [.plain("Old computer vision had humans writing rules: \u{201C}a dog has four legs, fur, and these shapes around the eyes.\u{201D} Brittle, slow, never quite worked.")],
                    [.plain("AlexNet skipped the rules. You feed it a million photos with labels (\u{201C}dog,\u{201D} \u{201C}cat,\u{201D} \u{201C}plane\u{201D}) and let it "),
                     .highlight("figure out the rules itself"),
                     .plain(".")],
                ],
                caption: "Pixels go in. A name comes out. The rules in between are learned.",
                illustration: PhotoToLabelArt()
            ),

            // How it looks, plain.
            .illustrated(
                id: "alexnet-conv",
                kicker: "How it works",
                title: "Tiny detectors, stacked",
                paragraphs: [
                    [.plain("AlexNet uses the trick from the last paper (LeNet): a "),
                     .term("tiny detector"),
                     .plain(" slid across the image.")],
                    [.plain("Then it stacks them. The first layer finds edges. The next finds shapes. The next finds whole objects. "),
                     .highlight("Simple parts, built up."),
                     .plain(" The deeper the stack, the more the network can see.")],
                ],
                caption: "Detectors slide. Layers stack. Edges become shapes become objects.",
                illustration: ConvWindowArt()
            ),

            // The setup before this paper.
            .prose(
                id: "alexnet-before",
                kicker: "The setup",
                title: "Everyone knew the idea. Nobody believed in it.",
                paragraphs: [
                    [.plain("By 2012, this idea (stack tiny detectors deep) was over a decade old. In theory it could learn to see anything.")],
                    [.plain("In practice almost "),
                     .bold("nobody trusted it"),
                     .plain(". The best image systems were still built by hand. Deep networks had a reputation for being slow, fiddly, and prone to cheating by memorising the photos.")],
                    [.plain("Then AlexNet entered the big 2012 image-recognition contest and "),
                     .highlight("beat everyone else by a mile"),
                     .plain(". The argument was over the same day.")],
                ]
            ),

            // The two problems, plain.
            .prose(
                id: "alexnet-walls",
                kicker: "The two old problems",
                title: "Why deep networks kept stalling",
                paragraphs: [
                    [.plain("Two things were blocking deep networks.")],
                    [.plain("First, the old way of \u{201C}firing\u{201D} neurons used a slow, S-shaped curve called the "),
                     .term("sigmoid"),
                     .plain(". When the curve flattens out, "),
                     .highlight("learning grinds to a halt"),
                     .plain(" in the lower layers.")],
                    [.plain("Second, a huge network with millions of knobs will just "),
                     .bold("memorise"),
                     .plain(" the photos it was shown. It aces those, then fails on new photos. A student who memorised the answer key but can\u{2019}t take a real test.")],
                ]
            ),

            // The fix for the slow firing curve, before its interactive.
            .prose(
                id: "alexnet-relu-fix",
                kicker: "The fix for slow firing",
                title: "Fire the simplest way possible",
                paragraphs: [
                    [.plain("AlexNet threw out the slow S-shaped curve and fired neurons the bluntest way imaginable, a rule called "),
                     .term("ReLU"),
                     .plain(".")],
                    [.plain("The rule is one line: if the signal is positive, "),
                     .highlight("pass it straight through"),
                     .plain("; if it\u{2019}s negative, output zero. No flattening, no slowdown.")],
                    [.plain("That tiny change let learning flow all the way down to the bottom layers, and a deep network finally trained fast. See it next to the old curve.")],
                ]
            ),

            // Interactive 1: ReLU.
            .interactive(id: "alexnet-relu") { progress in
                ReLUStudio(cardId: "alexnet-relu", progress: progress)
            },

            // The memorising problem, fix.
            .prose(
                id: "alexnet-overfit",
                kicker: "The fix for memorising",
                title: "Make the network forget, on purpose",
                paragraphs: [
                    [.plain("AlexNet\u{2019}s clever fix for memorising is called "),
                     .term("dropout"),
                     .plain(", and it sounds backwards.")],
                    [.plain("On every training step, "),
                     .highlight("switch off half the neurons at random"),
                     .plain(". The network has to keep working with whoever\u{2019}s left.")],
                    [.plain("It can\u{2019}t lean on any single neuron for the answer, so it learns a sturdier pattern. It\u{2019}s like training a team where any player might be benched at any moment. Everyone learns to play their best.")],
                ]
            ),

            // Interactive 2: Dropout.
            .interactive(id: "alexnet-dropout") { progress in
                DropoutStudio(cardId: "alexnet-dropout", progress: progress)
            },

            // What actually won: the conjunction.
            .prose(
                id: "alexnet-scale",
                kicker: "What actually won",
                title: "Three things, all at once",
                paragraphs: [
                    [.plain("Strip away the details and AlexNet won because three things arrived together. None of them on their own would have been enough.")],
                    [.plain("A "),
                     .bold("million labelled images"),
                     .plain(" to train on. A "),
                     .bold("deep network"),
                     .plain(" big enough to use them all. And "),
                     .bold("graphics chips"),
                     .plain(" fast enough to train it in a week instead of a year.")],
                    [.plain("Deep without data overfits. Data without compute never finishes. The lesson is "),
                     .highlight("the combination"),
                     .plain(", not any single piece.")],
                ]
            ),

            // Interactive 3: Scale studio.
            .interactive(id: "alexnet-scale-i") { progress in
                ScaleStudio(cardId: "alexnet-scale-i", progress: progress)
            },

            // Where you've met it.
            .prose(
                id: "alexnet-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It started the boom",
                paragraphs: [
                    [.plain("After AlexNet won in 2012, every serious computer-vision team threw out their old code and started over with deep networks. Within a year there was no other game in town.")],
                    [.plain("The "),
                     .bold("photo search"),
                     .plain(" on your phone? AlexNet\u{2019}s grandchild. "),
                     .bold("Filters that auto-blur a face"),
                     .plain("? Same family. "),
                     .bold("Self-driving cars"),
                     .plain(" that can spot a stop sign? Yep.")],
                    [.plain("The habit it taught the field, "),
                     .highlight("more data, bigger model, more compute"),
                     .plain(", still drives every AI breakthrough today.")],
                ]
            ),

            // Consolidating glossary: every term has now appeared in the flow.
            .glossary(
                id: "alexnet-glossary",
                intro: "The four words AlexNet made famous, all in one place.",
                terms: [
                    LessonGlossaryTerm(
                        term: "ReLU",
                        definition: "A super-simple way to fire a neuron: if the signal is positive, pass it on; if negative, output zero. Replaced the old slow curve and made deep learning fast."),
                    LessonGlossaryTerm(
                        term: "Overfitting",
                        definition: "What a network does when it memorises the training photos instead of learning the real pattern. Aces practice, fails real exams."),
                    LessonGlossaryTerm(
                        term: "Dropout",
                        definition: "A funny trick: randomly switch off half the neurons during each training step. Forces the network to build a sturdier answer."),
                    LessonGlossaryTerm(
                        term: "GPU",
                        definition: "The graphics chip in a gaming computer. AlexNet used two of them to train the network in a week, when CPUs would have taken months."),
                ]
            ),

            .recap(
                id: "alexnet-recap",
                title: "AlexNet, in three lines",
                points: [
                    "Stacking tiny detectors deep was a known idea, but deep networks kept stalling on two old problems: slow firing curves and memorising the training photos.",
                    "ReLU fixed the firing (pass positives, zero out negatives). Dropout fixed the memorising (switch off random neurons during training).",
                    "Combine those fixes with a million photos and two graphics chips, and you get the network that beat every hand-built system. The modern AI era started here.",
                ]
            ),

            .paperLink(
                id: "alexnet-paper",
                quote: "A large, deep neural network is capable of achieving record-breaking results using purely supervised learning.",
                attribution: "Krizhevsky, Sutskever, Hinton \u{00B7} 2012",
                linkTitle: "ImageNet Classification with Deep Convolutional Neural Networks",
                url: URL(string: "https://papers.nips.cc/paper/2012/file/c399862d3b9d6b76c8436e924a68c45b-Paper.pdf")
            ),
        ]
    )
}
