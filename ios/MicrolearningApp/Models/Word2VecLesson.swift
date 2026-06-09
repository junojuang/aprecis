import SwiftUI

// MARK: - Word2Vec lesson (beginner-first redesign)
//
// Meaning as geometry. Beginner arc: you already group words by company
// ("milk goes with cereal, queens go with kings"). Word2Vec turns that into
// a map. Formula and code cards gone. Word-map, analogy, skip-gram
// interactives kept.

extension LearningLesson {

    static let word2vec = LearningLesson(
        paperId: "loop:foundational:word2vec",
        cards: [

            // Editorial cover.
            .cover(
                id: "word2vec-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "Words become places.",
                highlight: "places",
                standfirst: "2013. The model where king minus man plus woman lands on queen.",
                hero: WordVectorGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "word2vec-hook",
                kicker: "Start here",
                title: "Your brain already does this",
                paragraphs: [
                    [.plain("Quick: which two words go together better, "),
                     .bold("dog"),
                     .plain(" and "),
                     .bold("cat"),
                     .plain(", or "),
                     .bold("dog"),
                     .plain(" and "),
                     .bold("Tuesday"),
                     .plain("?")],
                    [.plain("Obviously dog and cat. They\u{2019}re both pets, they both bark or meow, they live in homes. Your brain "),
                     .highlight("groups words by meaning"),
                     .plain(" without you noticing.")],
                    [.plain("This paper figured out how to make a computer do the exact same thing.")],
                ]
            ),

            // The big idea: words as points.
            .illustrated(
                id: "word2vec-idea",
                kicker: "The big idea",
                title: "Every word gets a spot on a map",
                paragraphs: [
                    [.plain("Word2Vec puts every word on a map. Not a real map, an imaginary one. Just a "),
                     .term("location"),
                     .plain(" made of a few hundred numbers.")],
                    [.plain("Once words are spots on a map, "),
                     .highlight("similar words land near each other"),
                     .plain(". Cat sits next to dog. Both sit nearer to wolf than to Tuesday.")],
                ],
                caption: "Nine words. Three neighbourhoods: royals, animals, drinks.",
                illustration: WordSpaceArt()
            ),

            // The old way.
            .prose(
                id: "word2vec-oldway",
                kicker: "The old way",
                title: "A word was just a name tag",
                paragraphs: [
                    [.plain("Before this paper, computers saw a word as a plain name tag. "),
                     .bold("Cat"),
                     .plain(" was just \u{201C}word number 4,812.\u{201D} No meaning inside.")],
                    [.plain("In that scheme, "),
                     .bold("cat"),
                     .plain(" was as unrelated to "),
                     .bold("dog"),
                     .plain(" as it was to "),
                     .bold("Tuesday"),
                     .plain(". "),
                     .highlight("Nothing knew what anything meant."),
                     .plain("")],
                ],
                hero: AnyView(OneHotArt().frame(height: 150))
            ),

            // Where meaning comes from.
            .illustrated(
                id: "word2vec-context",
                kicker: "Where meaning hides",
                title: "A word is the company it keeps",
                paragraphs: [
                    [.plain("Here\u{2019}s the quiet trick. You can tell what a word means from "),
                     .highlight("the words that show up around it"),
                     .plain(".")],
                    [.plain("\u{201C}Pour the ___ into a cup.\u{201D} The blank is filled by tea, coffee, water, juice. They keep the same company, so they share meaning.")],
                    [.plain("Word2Vec never reads a dictionary. It just watches which words hang out together.")],
                ],
                caption: "Same neighbours in real sentences, so Word2Vec places them together.",
                illustration: ContextBlankArt()
            ),

            // Drive the map yourself.
            .interactive(id: "word2vec-map") { progress in
                WordMapPlayground(cardId: "word2vec-map", progress: progress)
            },

            // Trimmed glossary.
            .glossary(
                id: "word2vec-glossary",
                intro: "Four words to know.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Word vector",
                        definition: "A word written as a list of numbers. The list pins the word to a spot on the imaginary map. Also called an embedding."),
                    LessonGlossaryTerm(
                        term: "Context",
                        definition: "The handful of words sitting next to a word in real text. The only clue Word2Vec gets about meaning."),
                    LessonGlossaryTerm(
                        term: "Embedding",
                        definition: "Just another name for word vector. The word that researchers use most often."),
                    LessonGlossaryTerm(
                        term: "Similarity",
                        definition: "How close two words are on the map. Close = similar meaning. Far = unrelated."),
                ]
            ),

            // The surprise: relationships as arrows.
            .illustrated(
                id: "word2vec-direction",
                kicker: "The surprise",
                title: "Relationships become arrows",
                paragraphs: [
                    [.plain("Once words are points, the "),
                     .term("direction"),
                     .plain(" between two of them carries its own meaning.")],
                    [.plain("The arrow from "),
                     .bold("man"),
                     .plain(" to "),
                     .bold("king"),
                     .plain(" points one way: add royalty. The arrow from "),
                     .bold("woman"),
                     .plain(" to "),
                     .bold("queen"),
                     .plain(" points the "),
                     .highlight("exact same way"),
                     .plain(".")],
                    [.plain("Nobody set that up. The map organised itself so that relationships became repeatable steps.")],
                ],
                caption: "Two different pairs. One identical arrow.",
                illustration: AnalogyParallelArt()
            ),

            // Play with arrows.
            .interactive(id: "word2vec-analogy") { progress in
                AnalogyPlayground(cardId: "word2vec-analogy", progress: progress)
            },

            // How it learns, illustrated.
            .illustrated(
                id: "word2vec-window",
                kicker: "How it learns",
                title: "Slide a window, predict the neighbours",
                paragraphs: [
                    [.plain("Word2Vec earns those positions with one tiny game. Slide a small "),
                     .term("window"),
                     .plain(" along real text. Take the middle word, and try to predict the words around it.")],
                    [.plain("Wrong guess, nudge the vectors. Right guess, leave them. Words that keep predicting each other "),
                     .highlight("get pulled closer"),
                     .plain(". The rest drift apart.")],
                    [.plain("That single game, repeated over billions of words, is the whole of training.")],
                ],
                caption: "The middle word, and the neighbours it learns to predict.",
                illustration: SkipGramWindowArt()
            ),

            // Skip-gram studio.
            .interactive(id: "word2vec-skipgram") { progress in
                SkipGramPlayground(cardId: "word2vec-skipgram", progress: progress)
            },

            // Where you've met it.
            .prose(
                id: "word2vec-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s how computers understand words",
                paragraphs: [
                    [.plain("Word2Vec was the moment computers stopped treating words as random IDs and started treating them as "),
                     .bold("meanings on a map"),
                     .plain(".")],
                    [.plain("Every "),
                     .bold("search engine"),
                     .plain(" that knows \u{201C}car\u{201D} and \u{201C}automobile\u{201D} mean the same thing. Every "),
                     .bold("Spotify recommendation"),
                     .plain(" that puts your favourite band near similar bands. Every "),
                     .bold("translation app"),
                     .plain(" that links a word in one language to its meaning in another.")],
                    [.plain("They all start the same way: "),
                     .highlight("turn words into points on a map"),
                     .plain(", then do maths on the points. ChatGPT and Claude do this too. Just with much richer maps.")],
                ],
                hero: AnyView(Word2VecLineage())
            ),

            // Recap.
            .recap(
                id: "word2vec-recap",
                title: "Word2Vec, in three lines",
                points: [
                    "Every word gets a spot on an imaginary map. Spots are picked so that similar words land close together.",
                    "Word2Vec figures out where to put each word by watching which words hang out near it in real text. No dictionary, no human help.",
                    "Once words are points, relationships become arrows. King minus man plus woman lands on queen. Every modern AI that handles language starts from this idea.",
                ]
            ),

            // Closing.
            .paperLink(
                id: "word2vec-source",
                quote: "King minus Man plus Woman is closest to the vector for Queen.",
                attribution: "Mikolov, Chen, Corrado, Dean \u{00B7} 2013",
                linkTitle: "Efficient Estimation of Word Representations in Vector Space \u{00B7} 2013",
                url: URL(string: "https://arxiv.org/abs/1301.3781")
            ),
        ]
    )
}
