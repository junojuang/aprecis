import SwiftUI

// MARK: - GANs lesson (beginner-first redesign)
//
// Two networks in a forger-versus-detective contest. Beginner arc: you've
// seen those "this person doesn't exist" faces, here's how they get made.
// Formula card removed. SpotFake, Converge, Latent studios kept.

extension LearningLesson {

    static let gans = LearningLesson(
        paperId: "loop:foundational:gans",
        cards: [

            .cover(
                id: "gans-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Two networks, one duel.",
                highlight: "duel",
                standfirst: "2014. A forger and a detective, locked in a contest that teaches both.",
                hero: GANGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "gans-hook",
                kicker: "Start here",
                title: "Ever seen a face that doesn\u{2019}t exist?",
                paragraphs: [
                    [.plain("There\u{2019}s a website called "),
                     .bold("thispersondoesnotexist.com"),
                     .plain(". Every time you reload it, you see a new, perfectly normal human face. None of those people are real. A computer made them.")],
                    [.plain("How? Two networks "),
                     .highlight("playing a game against each other"),
                     .plain(", non-stop. That game is called a GAN.")],
                ]
            ),

            // Big idea.
            .illustrated(
                id: "gans-bigidea",
                kicker: "The big idea",
                title: "A forger against a detective",
                paragraphs: [
                    [.plain("Imagine an art forger painting fakes and trying to slip them into a museum. An expert detective examines each new piece: real or forged?")],
                    [.plain("Every time the detective catches a fake, the forger learns "),
                     .highlight("exactly what gave it away"),
                     .plain(" and paints a better one. Every better fake forces the detective to look harder.")],
                    [.plain("Nobody teaches either of them. They sharpen each other. Run the contest long enough and the fakes become flawless. A GAN is two networks playing exactly this game.")],
                ],
                caption: "Round by round the fake improves, until the detective can\u{2019}t tell.",
                illustration: ForgeryLadderArt()
            ),

            // Why it was a new question.
            .prose(
                id: "gans-problem",
                kicker: "Why it was new",
                title: "Not judging. Making.",
                paragraphs: [
                    [.plain("Every neural network you\u{2019}ve met so far only "),
                     .term("judged"),
                     .plain(" things. Show it a photo, get a label. Show it a sentence, get a translation. The right answer always existed; the network found it.")],
                    [.plain("This paper asks a bigger question. Can a network "),
                     .highlight("create"),
                     .plain(" a brand new image, a face of nobody, that looks completely real?")],
                    [.plain("The trouble is grading. There\u{2019}s no single right answer to check against, so the normal way of training doesn\u{2019}t exist.")],
                ]
            ),

            // The trick.
            .prose(
                id: "gans-idea",
                kicker: "The trick",
                title: "Let a rival do the grading",
                paragraphs: [
                    [.plain("The fix: build the grader out of a second network.")],
                    [.plain("One network, the "),
                     .term("forger"),
                     .plain(", makes fakes. The other, the "),
                     .term("detective"),
                     .plain(", judges whether each picture is real or fake.")],
                    [.plain("They train against each other. The forger wins by "),
                     .highlight("fooling the detective"),
                     .plain(". The detective wins by catching the forger. Each one\u{2019}s improvement is the other\u{2019}s harder exam.")],
                ]
            ),

            // Play the detective.
            .interactive(id: "gans-spot") { progress in
                SpotFakeStudio(cardId: "gans-spot", progress: progress)
            },

            // Trimmed glossary.
            .glossary(
                id: "gans-glossary",
                intro: "Four words researchers use a lot. The first two are the players.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Generator",
                        definition: "The forger. Takes random noise and turns it into a fake image."),
                    LessonGlossaryTerm(
                        term: "Discriminator",
                        definition: "The detective. Looks at an image and decides whether it\u{2019}s real or fake."),
                    LessonGlossaryTerm(
                        term: "Latent noise",
                        definition: "The random numbers fed into the forger. Different noise in, different fake out."),
                    LessonGlossaryTerm(
                        term: "Equilibrium",
                        definition: "The end of the game. The fakes are so good the detective can only flip a coin."),
                ]
            ),

            // How the game moves.
            .prose(
                id: "gans-game",
                kicker: "How the contest moves",
                title: "Each round raises the bar",
                paragraphs: [
                    [.plain("Early on it\u{2019}s lopsided. The forger\u{2019}s fakes are crude. The detective spots them in a glance.")],
                    [.plain("But every caught fake tells the forger exactly what gave it away, so the next batch is "),
                     .highlight("just a tiny bit better"),
                     .plain(". A sharper forger forces the detective to look harder.")],
                    [.plain("Round after round the bar rises, until the fakes are good enough that the detective is just guessing.")],
                ]
            ),

            // Watch them converge.
            .interactive(id: "gans-converge") { progress in
                ConvergeStudio(cardId: "gans-converge", progress: progress)
            },

            // Drive the forger.
            .interactive(id: "gans-latent") { progress in
                LatentStudio(cardId: "gans-latent", progress: progress)
            },

            // Where you've met it.
            .prose(
                id: "gans-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It started generative AI",
                paragraphs: [
                    [.plain("GANs were the first AI to make photorealistic faces of people who don\u{2019}t exist. For years they ran the image-generation world.")],
                    [.plain("Newer methods (diffusion models, the ones behind Midjourney and DALL\u{00B7}E) have taken the lead. But GANs proved the point that started "),
                     .highlight("everything generative"),
                     .plain(": a network can learn to make, not just judge.")],
                    [.plain("You\u{2019}ve met GANs in "),
                     .bold("deepfakes"),
                     .plain(", in the "),
                     .bold("face-swap filters"),
                     .plain(" on social apps, in "),
                     .bold("AI portraits"),
                     .plain(". And the trick of \u{201C}train against a critic\u{201D} still shapes how today\u{2019}s biggest models are tuned.")],
                ]
            ),

            // Recap.
            .recap(
                id: "gans-recap",
                title: "GANs, in three lines",
                points: [
                    "Making new images is harder than judging old ones. There\u{2019}s no single right answer to train against.",
                    "GANs build the grader from a rival network: a forger makes fakes, a detective judges them, each trained against the other.",
                    "The contest is the training. When the fakes are good enough that the detective is just guessing, the forger can create new images on demand.",
                ]
            ),

            .paperLink(
                id: "gans-paper",
                quote: "Two networks, one game. The fake becomes real.",
                attribution: "Goodfellow and colleagues \u{00B7} 2014",
                linkTitle: "Generative Adversarial Nets",
                url: URL(string: "https://arxiv.org/abs/1406.2661")
            ),
        ]
    )
}
