import SwiftUI

// MARK: - Seq2Seq bespoke interactives
//
// The vision papers ended with ResNet. Seq2Seq (2014) is the turn toward
// language: a network that reads a whole sentence and writes a new one,
// of a different length, in a different tongue. These visuals follow the
// signal: words pressed into one vector, that vector unrolled back into
// words, and the strain of forcing any sentence through one fixed size.

private let s2sVecLen = 6

// Each source word carries a fixed nudge to the context vector.
private let s2sWords: [(word: String, delta: [Double])] = [
    ("the",  [ 0.5, -0.3,  0.2,  0.4, -0.1,  0.3]),
    ("cat",  [-0.4,  0.6,  0.5, -0.2,  0.4, -0.3]),
    ("sat",  [ 0.3,  0.2, -0.5,  0.5,  0.3,  0.4]),
    ("down", [-0.2,  0.4,  0.3, -0.4, -0.5,  0.2]),
]
private let s2sOutput = ["le", "chat", "s'est", "assis"]

// MARK: - Seq2SeqGlyph (cover hero)
//
// Word chips flow left into a box, condense to one glowing vector, and flow
// right out as different word chips. Read one language, write another.

struct Seq2SeqGlyph: View {
    @State private var t: Double = 0

    private let ink = Color(hex: "f4f1ea")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // glowing context vector at the centre
                RoundedRectangle(cornerRadius: 6)
                    .fill(tealAccent.opacity(0.85))
                    .frame(width: 26, height: 64)
                    .shadow(color: tealAccent.opacity(0.7), radius: 12)
                    .position(x: w * 0.5, y: h * 0.5)

                // incoming words (left), outgoing words (right)
                ForEach(0..<3, id: \.self) { i in
                    let prog = (t + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                    Capsule()
                        .fill(ink.opacity(0.5))
                        .frame(width: 30, height: 14)
                        .position(x: w * (0.06 + 0.38 * prog), y: h * (0.3 + 0.2 * Double(i)))
                        .opacity(1 - prog)
                    Capsule()
                        .fill(amberAccent.opacity(0.8))
                        .frame(width: 30, height: 14)
                        .position(x: w * (0.56 + 0.38 * prog), y: h * (0.3 + 0.2 * Double(i)))
                        .opacity(prog)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                t = 1
            }
        }
    }
}

// MARK: - SentenceSwapArt (big-idea illustration)
//
// One sentence becomes another of a different length. Three English chips
// on the left, one held meaning in the middle, four French chips on the
// right. The mismatched counts are the whole point of the card.

struct SentenceSwapArt: View {
    @State private var shown = false

    private let source = ["the", "cat", "sat"]
    private let target = ["le", "chat", "s'est", "assis"]

    var body: some View {
        HStack(spacing: 12) {
            column(source, fill: inkColor.opacity(0.55), tag: "3 WORDS")
            arrow
            RoundedRectangle(cornerRadius: 6)
                .fill(tealAccent.opacity(0.9))
                .frame(width: 20, height: 46)
                .shadow(color: tealAccent.opacity(0.55), radius: 7)
            arrow
            column(target, fill: amberAccent.opacity(0.85), tag: "4 WORDS")
                .opacity(shown ? 1 : 0)
                .offset(x: shown ? 0 : 12)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) { shown = true }
        }
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .scaledFont(size: 14, weight: .semibold)
            .foregroundStyle(inkColor.opacity(0.35))
    }

    private func column(_ words: [String], fill: Color, tag: String) -> some View {
        VStack(spacing: 5) {
            ForEach(words, id: \.self) { w in
                Text(w)
                    .scaledFont(size: 12, weight: .semibold, design: .serif)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(fill))
            }
            Text(tag)
                .scaledFont(size: 9, weight: .bold).tracking(0.8)
                .foregroundStyle(mutedText)
                .padding(.top, 2)
        }
    }
}

// MARK: - EncodeStudio (interactive 1)
//
// Feed the source sentence word by word. One running context vector takes
// each word in. When the last word lands, that vector IS the sentence,
// a fixed-size summary the decoder will work from.

struct EncodeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var fed = 0
    @State private var context = Array(repeating: 0.0, count: s2sVecLen)

    private var done: Bool { fed >= s2sWords.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("READ THE SENTENCE IN")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Feed the source words one at a time. The context vector underneath absorbs each one. There is no growing list, just this fixed row of numbers, updated again and again.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            wordRow
            Image(systemName: "arrow.down").scaledFont(size: 13, weight: .bold)
                .foregroundStyle(mutedText).frame(maxWidth: .infinity)
            vectorView
            statusRow
            button
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wordRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<s2sWords.count, id: \.self) { i in
                Text(s2sWords[i].word)
                    .scaledFont(size: 14, weight: .semibold, design: .serif)
                    .foregroundStyle(i < fed ? .white : inkColor.opacity(0.5))
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 9)
                        .fill(i < fed ? tealAccent : inkColor.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .stroke(i == fed ? amberAccent : .clear, lineWidth: 2)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var vectorView: some View {
        VStack(spacing: 6) {
            Text("CONTEXT VECTOR")
                .scaledFont(size: 10, weight: .bold).tracking(1.6)
                .foregroundStyle(mutedText)
            HStack(spacing: 6) {
                ForEach(0..<s2sVecLen, id: \.self) { k in
                    let v = (context[k] + 1) / 2
                    GeometryReader { g in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 5).fill(inkColor.opacity(0.06))
                            RoundedRectangle(cornerRadius: 5)
                                .fill(done ? tealAccent : amberAccent)
                                .frame(height: max(4, g.size.height * CGFloat(v)))
                        }
                    }
                    .frame(height: 70)
                }
            }
            .motionAware(.snappy(duration: 0.35), value: context)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Every word is in. This one vector is now the whole sentence, ready to decode."
                 : "Fed \(fed) of \(s2sWords.count) words")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var button: some View {
        Button { feed() } label: {
            Text(done ? "Sentence encoded \u{2713}" : "Feed next word")
                .scaledFont(size: 14, weight: .semibold)
                .foregroundStyle(done ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(done ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(done)
    }

    private func feed() {
        guard !done else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        let d = s2sWords[fed].delta
        withAnimation(.snappy(duration: 0.35)) {
            for k in 0..<s2sVecLen {
                context[k] = tanh(context[k] * 0.6 + d[k])
            }
            fed += 1
        }
        if done {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - DecodeStudio (interactive 2)
//
// From the finished context vector, emit the translation one word at a
// time. Each word the decoder produces is fed back in to help choose the
// next, until it decides to stop.

struct DecodeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var emitted = 0

    private var done: Bool { emitted > s2sOutput.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("WRITE THE SENTENCE OUT")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The decoder starts from the context vector and emits one word, then reads its own word back to choose the next. It keeps going until it emits a stop token.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            contextChip
            Image(systemName: "arrow.down").scaledFont(size: 13, weight: .bold)
                .foregroundStyle(mutedText).frame(maxWidth: .infinity)
            outRow
            statusRow
            button
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contextChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "shippingbox.fill")
                .scaledFont(size: 13).foregroundStyle(tealAccent)
            Text("CONTEXT VECTOR  \u{00B7}  the encoded source sentence")
                .scaledFont(size: 11, weight: .bold).tracking(0.6)
                .foregroundStyle(inkColor.opacity(0.7))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.1)))
    }

    private var outRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<s2sOutput.count, id: \.self) { i in
                Text(s2sOutput[i])
                    .scaledFont(size: 14, weight: .semibold, design: .serif)
                    .foregroundStyle(i < emitted ? .white : inkColor.opacity(0.3))
                    .padding(.horizontal, 11).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 9)
                        .fill(i < emitted ? tealAccent : inkColor.opacity(0.05)))
            }
            Text("\u{25A0}")
                .scaledFont(size: 12, weight: .bold)
                .foregroundStyle(emitted > s2sOutput.count ? amberAccent : inkColor.opacity(0.2))
                .padding(.horizontal, 9).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9)
                    .fill(emitted > s2sOutput.count ? amberAccent.opacity(0.2)
                                                     : inkColor.opacity(0.05)))
        }
        .frame(maxWidth: .infinity)
        .motionAware(.snappy(duration: 0.3), value: emitted)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "Stop token emitted. The translation is complete, and it is shorter in words yet means the same."
                 : emitted == 0 ? "Emit the first word from the context vector."
                   : "Emitted \(emitted) word(s), each one feeding the next step")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var button: some View {
        Button { emit() } label: {
            Text(done ? "Translation done \u{2713}"
                      : emitted == s2sOutput.count ? "Emit the stop token" : "Emit next word")
                .scaledFont(size: 14, weight: .semibold)
                .foregroundStyle(done ? tealAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(done ? tealAccent.opacity(0.12) : inkColor))
        }
        .buttonStyle(.plain)
        .disabled(done)
    }

    private func emit() {
        guard !done else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.snappy(duration: 0.3)) { emitted += 1 }
        if done {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - BottleneckStudio (interactive 3)
//
// The catch. Whatever the sentence length, it must fit the same fixed
// vector. Drag the length up and watch the strain: a long sentence has
// far less room per word. This is the weak point the next paper attacks.

struct BottleneckStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var length: Double = 4
    @State private var sawLong = false

    // capacity is fixed; room per word falls as the sentence grows
    private var roomPerWord: Double { 1.0 / length }
    private var strain: Double { min(1, max(0, (length - 5) / 25)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("THE FIXED-SIZE CATCH")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The context vector is one size, always. A four-word sentence and a thirty-word sentence get the exact same room. Drag the length and watch the pressure build.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            vectorWithWords
            strainBar
            lengthSlider
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var vectorWithWords: some View {
        VStack(spacing: 8) {
            Text("ONE VECTOR, \(Int(length)) WORDS SHARING IT")
                .scaledFont(size: 10, weight: .bold).tracking(1.4)
                .foregroundStyle(mutedText)
            GeometryReader { g in
                let n = Int(length)
                let slot = g.size.width / CGFloat(n)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tealAccent.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(tealAccent, lineWidth: 1.5))
                    ForEach(0..<n, id: \.self) { i in
                        Rectangle()
                            .fill(inkColor.opacity(0.18))
                            .frame(width: 1)
                            .offset(x: slot * CGFloat(i))
                    }
                }
            }
            .frame(height: 44)
            .motionAware(.snappy(duration: 0.3), value: length)
        }
    }

    private var strainBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("COMPRESSION STRAIN")
                    .scaledFont(size: 10, weight: .bold).tracking(1.6)
                    .foregroundStyle(mutedText)
                Spacer()
                Text(strain > 0.66 ? "high" : strain > 0.33 ? "rising" : "low")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(strain > 0.5 ? Color(hex: "c2557a") : inkColor.opacity(0.7))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7).fill(inkColor.opacity(0.06))
                    RoundedRectangle(cornerRadius: 7)
                        .fill(strain > 0.5 ? Color(hex: "c2557a") : amberAccent)
                        .frame(width: max(6, g.size.width * CGFloat(strain)))
                }
            }
            .frame(height: 20)
            .motionAware(.snappy(duration: 0.3), value: strain)
        }
    }

    private var lengthSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SENTENCE LENGTH  \(Int(length)) words")
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .foregroundStyle(mutedText)
            Slider(value: $length, in: 3...30) { editing in
                if !editing && length >= 22 {
                    sawLong = true
                    progress.markExplored(cardId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .tint(tealAccent)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(sawLong ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(sawLong
                 ? "A long sentence is squeezed hard. The fix, letting the decoder look back at every word, is the next paper: attention."
                 : "Room per word: \(String(format: "%.0f%%", roomPerWord * 100)) of the vector")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
