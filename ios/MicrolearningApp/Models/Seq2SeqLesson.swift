import SwiftUI

// MARK: - Seq2Seq lesson (beginner-first redesign)
//
// Reading a whole sentence in, writing a different sentence out. Beginner
// arc: you already do this when you translate or paraphrase. Encoder/
// decoder/bottleneck taught as listen / speak / sticky-note. No formula or
// code cards. Encode/Decode/Bottleneck studios kept.

extension LearningLesson {

    static let seq2seq = LearningLesson(
        paperId: "loop:foundational:seq2seq",
        cards: [

            // Cover.
            .cover(
                id: "seq2seq-cover",
                eyebrow: "Aprecis \u{00B7} Foundations",
                headline: "One sentence into another.",
                highlight: "another",
                standfirst: "2014. The shape that finally let a network translate, summarise, and reply.",
                hero: Seq2SeqGlyph()
            ),

            // Relatable hook.
            .prose(
                id: "seq2seq-hook",
                kicker: "Start here",
                title: "Have you ever used Google Translate?",
                paragraphs: [
                    [.plain("You type "),
                     .bold("\"How are you?\""),
                     .plain(" and out comes "),
                     .bold("\"\u{00BF}C\u{00F3}mo est\u{00E1}s?\""),
                     .plain(" Three words become two.")],
                    [.plain("How does a computer do that? It has to read the whole English sentence first, "),
                     .highlight("understand what you meant"),
                     .plain(", and only then start writing the Spanish.")],
                    [.plain("This paper was the first to teach a network to work that way.")],
                ]
            ),

            // The big idea.
            .illustrated(
                id: "seq2seq-bigidea",
                kicker: "The big idea",
                title: "Listen all the way, then speak",
                paragraphs: [
                    [.plain("Picture a human interpreter. Someone says a full sentence in English. The interpreter doesn\u{2019}t translate word by word as it lands.")],
                    [.plain("They "),
                     .highlight("wait, take in the whole sentence"),
                     .plain(", hold the meaning for a second, and only then say it again in Spanish.")],
                    [.plain("Two separate jobs: listen, then speak. And the Spanish might be longer or shorter than the English. This paper teaches a network the same trick.")],
                ],
                caption: "Three words in, two words out. The meaning survives.",
                illustration: SentenceSwapArt()
            ),

            // The problem.
            .prose(
                id: "seq2seq-problem",
                kicker: "Why it was hard",
                title: "Language won\u{2019}t sit still",
                paragraphs: [
                    [.plain("Old networks expected a fixed shape. An image is always the same grid of pixels. Easy.")],
                    [.plain("A sentence is "),
                     .highlight("not"),
                     .plain(". It could be three words or thirty. And translation changes the length: a five-word English sentence might become an eight-word French one.")],
                    [.plain("A network with a fixed number of inputs and outputs simply can\u{2019}t handle this. The job needed a new shape.")],
                ]
            ),

            // The split.
            .prose(
                id: "seq2seq-idea",
                kicker: "The fix",
                title: "One reader. One writer.",
                paragraphs: [
                    [.plain("Split the job in two.")],
                    [.plain("The "),
                     .term("reader"),
                     .plain(" (researchers call it the encoder) takes the English sentence word by word and squeezes it down to "),
                     .highlight("one summary"),
                     .plain(", a fixed-size list of numbers.")],
                    [.plain("The "),
                     .term("writer"),
                     .plain(" (decoder) starts from that summary and writes the Spanish sentence one word at a time, for as many words as it takes.")],
                ]
            ),

            // Encode it yourself.
            .interactive(id: "seq2seq-encode") { progress in
                EncodeStudio(cardId: "seq2seq-encode", progress: progress)
            },

            // Trimmed glossary.
            .glossary(
                id: "seq2seq-glossary",
                intro: "Three words for the split you just saw. Worth knowing, easy to remember.",
                terms: [
                    LessonGlossaryTerm(
                        term: "Encoder",
                        definition: "The reader. Reads the input sentence and squeezes it down to one summary."),
                    LessonGlossaryTerm(
                        term: "Decoder",
                        definition: "The writer. Starts from the summary and writes the output sentence, one word at a time."),
                    LessonGlossaryTerm(
                        term: "Context vector",
                        definition: "The summary itself. The list of numbers that holds everything the reader took in. Also called the \u{201C}thought vector.\u{201D}"),
                ]
            ),

            // Writing it out, plain.
            .prose(
                id: "seq2seq-decode",
                kicker: "Writing it out",
                title: "Each word feeds the next",
                paragraphs: [
                    [.plain("The writer doesn\u{2019}t produce the whole sentence at once. It writes "),
                     .term("one word"),
                     .plain(", then reads its own word back to help pick the next.")],
                    [.plain("That\u{2019}s what makes the output length free. The writer keeps going as long as the sentence needs, then emits a special end-of-sentence signal, a "),
                     .term("stop token"),
                     .plain(", to say it\u{2019}s done.")],
                ]
            ),

            // Decode it yourself.
            .interactive(id: "seq2seq-decode-i") { progress in
                DecodeStudio(cardId: "seq2seq-decode-i", progress: progress)
            },

            // The weak spot.
            .prose(
                id: "seq2seq-bottleneck",
                kicker: "The weak spot",
                title: "Everything through one sticky note",
                paragraphs: [
                    [.plain("There\u{2019}s a catch built into this. No matter how long the English sentence, it has to fit through the "),
                     .term("same fixed-size summary"),
                     .plain(".")],
                    [.plain("Short sentences fit comfortably. Long ones get "),
                     .highlight("squeezed"),
                     .plain(", and the writer, working only from the summary, starts dropping details.")],
                    [.plain("This is the flaw the next paper (Attention) was built to fix.")],
                ]
            ),

            // Bottleneck demo.
            .interactive(id: "seq2seq-bottleneck-i") { progress in
                BottleneckStudio(cardId: "seq2seq-bottleneck-i", progress: progress)
            },

            // Where you've met it.
            .prose(
                id: "seq2seq-everyday",
                kicker: "Where you\u{2019}ve met it",
                title: "It\u{2019}s the shape of every chat",
                paragraphs: [
                    [.plain("Reader + writer became the default shape for any task that turns one sequence into another.")],
                    [.plain("Every "),
                     .bold("translation app"),
                     .plain(". Every "),
                     .bold("auto-summary"),
                     .plain(" that shrinks a long article. Every "),
                     .bold("voice assistant"),
                     .plain(" that listens to your question and writes a reply.")],
                    [.plain("ChatGPT itself is just a giant version of this idea, with the bottleneck removed by the next two papers.")],
                ]
            ),

            // Recap.
            .recap(
                id: "seq2seq-recap",
                title: "Seq2Seq, in three lines",
                points: [
                    "Sentences come in all lengths, and translation changes the length, so a fixed-shape network can\u{2019}t do the job.",
                    "The fix splits the work: one network reads the input into a summary, another writes the output from it, one word at a time.",
                    "Forcing everything through one fixed-size summary is the weak spot. Attention (the next paper) was invented to fix it.",
                ]
            ),

            // Closing.
            .paperLink(
                id: "seq2seq-paper",
                quote: "A large deep network can translate from one language to another, end to end.",
                attribution: "Sutskever, Vinyals, Le \u{00B7} 2014",
                linkTitle: "Sequence to Sequence Learning with Neural Networks",
                url: URL(string: "https://arxiv.org/abs/1409.3215")
            ),
        ]
    )
}
