import SwiftUI

// MARK: - Self-Consistency bespoke interactives
//
// 2022, Wang et al. (Google). "Self-Consistency Improves Chain of Thought
// Reasoning." A single greedy chain of thought can take one wrong turn and
// blow the answer. Instead, sample many diverse chains and let their final
// answers vote: the right answer tends to be reachable by many routes, so the
// majority is far more reliable. "Sample and marginalize."
//
// Diagrams built around the voting mechanism:
//   SamplePathsStudio  - tap to sample reasoning paths; a live tally builds and
//                        the majority answer rises to the top.
//   GreedyVsVoteStudio - the single most-likely chain is wrong; the vote over
//                        samples is right.
//   DiversityStudio    - a temperature dial: too low and every sample agrees on
//                        the same wrong answer; too high and they scatter; the
//                        sweet spot lets varied-but-sound paths converge.

private let scRose = Color(hex: "d46a6a")

// MARK: - SelfConsistencyGlyph (cover hero)
//
// One question fans out into several paths that converge on a single,
// tallied answer.

struct SelfConsistencyGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let startX = w * 0.18, endX = w * 0.82, midY = h * 0.5
            let ys = [0.26, 0.42, 0.58, 0.74].map { $0 * h }
            ZStack {
                ForEach(Array(ys.enumerated()), id: \.offset) { _, y in
                    Path { p in
                        p.move(to: CGPoint(x: startX, y: midY))
                        p.addQuadCurve(to: CGPoint(x: endX, y: midY),
                                       control: CGPoint(x: w * 0.5, y: y))
                    }
                    .trim(from: 0, to: t)
                    .stroke(tealAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                }
                node("Q", fill: Color(hex: "f4f1ea").opacity(0.10),
                     stroke: Color(hex: "f4f1ea").opacity(0.35), fg: Color(hex: "f4f1ea"))
                    .position(x: startX, y: midY)
                node("3", fill: tealAccent, stroke: tealAccent, fg: .white)
                    .position(x: endX, y: midY)
                    .opacity(t > 0.8 ? 1 : 0.3)
                Text("LET THE ANSWERS VOTE")
                    .font(.system(size: 9, weight: .bold)).tracking(1.8)
                    .foregroundStyle(tealAccent)
                    .position(x: w / 2, y: h * 0.9)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) { t = 1 }
        }
    }
    private func node(_ s: String, fill: Color, stroke: Color, fg: Color) -> some View {
        Text(s).font(.system(size: 15, weight: .bold, design: .serif)).foregroundStyle(fg)
            .frame(width: 38, height: 38)
            .background(RoundedRectangle(cornerRadius: 9).fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(stroke, lineWidth: 1.5)))
    }
}

// MARK: - OneChainVsManyArt (big-idea illustration)
//
// Top: one chain takes a wrong turn, one wrong answer. Bottom: many chains,
// most landing on the same right answer, which wins the vote.

struct OneChainVsManyArt: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ONE CHAIN").font(.system(size: 9, weight: .bold)).tracking(1.3)
                    .foregroundStyle(scRose)
                HStack(spacing: 6) {
                    dot("Q", mutedText)
                    seg; dot("\u{00B7}", mutedText); seg; ans("4", correct: false)
                }
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(scRose.opacity(0.05)))

            VStack(alignment: .leading, spacing: 6) {
                Text("MANY CHAINS, THEN VOTE").font(.system(size: 9, weight: .bold)).tracking(1.3)
                    .foregroundStyle(tealAccent)
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 6) {
                        dot("Q", tealAccent)
                        seg; dot("\u{00B7}", tealAccent); seg
                        ans(i == 2 ? "4" : "3", correct: i != 2)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(tealAccent)
                    Text("majority: 3").font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundStyle(inkColor)
                }
                .padding(.top, 2)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
    private var seg: some View {
        Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(mutedText)
    }
    private func dot(_ s: String, _ tint: Color) -> some View {
        Text(s).font(.system(size: 11, weight: .bold, design: .serif)).foregroundStyle(inkColor.opacity(0.8))
            .frame(width: 26, height: 26)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.5), lineWidth: 1)))
    }
    private func ans(_ s: String, correct: Bool) -> some View {
        HStack(spacing: 3) {
            Text(s).font(.system(size: 11, weight: .bold, design: .serif)).foregroundStyle(.white)
            Image(systemName: correct ? "checkmark" : "xmark").font(.system(size: 7, weight: .black))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(correct ? tealAccent : scRose))
    }
}

// MARK: - BallotArt (illustration)
//
// A small tally board: each distinct final answer with its count, the leader
// crowned.

struct BallotArt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE BALLOT").font(.system(size: 9, weight: .bold)).tracking(1.3)
                .foregroundStyle(mutedText)
            tally(answer: "3", count: 4, leader: true)
            tally(answer: "4", count: 1, leader: false)
            tally(answer: "5", count: 1, leader: false)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }
    private func tally(answer: String, count: Int, leader: Bool) -> some View {
        HStack(spacing: 10) {
            Text("ans \(answer)").font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(inkColor.opacity(0.8)).frame(width: 50, alignment: .leading)
            HStack(spacing: 3) {
                ForEach(0..<count, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(leader ? tealAccent : mutedText.opacity(0.5))
                        .frame(width: 16, height: 12)
                }
            }
            if leader {
                Image(systemName: "crown.fill").font(.system(size: 11)).foregroundStyle(amberAccent)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - SamplePathsStudio (interactive 1)
//
// Tap to sample reasoning paths one at a time. Each is a distinct chain that
// lands on an answer; a live tally builds and the current leader is crowned.
// Sampling the full set completes the card.

private struct SCPath {
    let chain: String
    let answer: String
    let correct: Bool
}

private let scPaths: [SCPath] = [
    SCPath(chain: "Blue = 2. White is half of 2 = 1. Total 2 + 1 = 3.", answer: "3", correct: true),
    SCPath(chain: "Half of 2 bolts is 1. So 2 and 1 makes 3.", answer: "3", correct: true),
    SCPath(chain: "2 blue, white same again = 2. 2 + 2 = 4.", answer: "4", correct: false),
    SCPath(chain: "White = 2 \u{00F7} 2 = 1. Add to blue: 3.", answer: "3", correct: true),
    SCPath(chain: "Blue 2, white 1, total 3 bolts.", answer: "3", correct: true),
]

struct SamplePathsStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var drawn = 0

    private var done: Bool { drawn >= scPaths.count }
    private var counts: [String: Int] {
        Dictionary(grouping: scPaths.prefix(drawn), by: \.answer).mapValues(\.count)
    }
    private var leader: String? {
        counts.max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("SAMPLE AND TALLY")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("One question: a robe needs 2 bolts of blue and half that of white. Instead of trusting one chain, sample several. Each takes its own route. Tap to draw paths and watch the answers vote.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            pathsList
            tallyBar
            drawButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: drawn)
    }

    private var pathsList: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<scPaths.count, id: \.self) { i in
                if i < drawn {
                    HStack(alignment: .top, spacing: 9) {
                        Text("#\(i + 1)").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(mutedText).padding(.top, 2)
                        Text(scPaths[i].chain)
                            .font(.system(size: 13, design: .serif)).foregroundStyle(inkColor.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        answerChip(scPaths[i].answer, correct: scPaths[i].correct)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(borderColor, lineWidth: 1)))
                }
            }
        }
    }

    private func answerChip(_ a: String, correct: Bool) -> some View {
        Text(a).font(.system(size: 13, weight: .bold, design: .serif)).foregroundStyle(.white)
            .frame(width: 30, height: 26)
            .background(RoundedRectangle(cornerRadius: 7).fill(correct ? tealAccent : scRose))
    }

    @ViewBuilder
    private var tallyBar: some View {
        if drawn > 0 {
            VStack(alignment: .leading, spacing: 6) {
                Text("VOTES SO FAR").font(.system(size: 9, weight: .bold)).tracking(1.2)
                    .foregroundStyle(tealAccent)
                ForEach(counts.sorted(by: { $0.value > $1.value }), id: \.key) { answer, count in
                    HStack(spacing: 8) {
                        Text("ans \(answer)").font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(inkColor.opacity(0.8)).frame(width: 50, alignment: .leading)
                        HStack(spacing: 3) {
                            ForEach(0..<count, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(answer == leader ? tealAccent : mutedText.opacity(0.5))
                                    .frame(width: 16, height: 12)
                            }
                        }
                        if answer == leader && done {
                            Image(systemName: "crown.fill").font(.system(size: 11)).foregroundStyle(amberAccent)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(tealAccent.opacity(0.25), lineWidth: 1)))
        }
    }

    @ViewBuilder
    private var drawButton: some View {
        if !done {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                drawn += 1
                if done { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
            } label: {
                Text(drawn == 0 ? "Sample a reasoning path" : "Sample another path")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 11).fill(tealAccent))
            }
            .buttonStyle(.plain)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "One path took a wrong turn and answered 4. But four of five routes reached 3, so the majority vote lands on the right answer. That is self-consistency."
                 : "Keep sampling. Different routes, but the right answer keeps coming up.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - GreedyVsVoteStudio (interactive 2)
//
// The single most-likely chain (greedy decoding) is wrong here. Reveal it,
// then reveal the vote over many samples, which is right. Shows why one
// confident chain is not enough.

struct GreedyVsVoteStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var showGreedy = false
    @State private var showVote = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("ONE CONFIDENT GUESS, OR A VOTE")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The usual way is to take the single most-likely chain, the one the model is most confident in. Reveal it, then reveal what happens when you sample many and let them vote.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            greedyCard
            voteCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: showGreedy)
        .animation(.snappy(duration: 0.3), value: showVote)
    }

    private var greedyCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(); showGreedy = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("GREEDY: THE SINGLE MOST-LIKELY CHAIN")
                    .font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(mutedText)
                if showGreedy {
                    Text("\"2 bolts of blue, and white is another 2, so 2 + 2 = 4.\"")
                        .font(.system(size: 13.5, design: .serif)).italic().foregroundStyle(inkColor.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(scRose)
                        Text("Answer: 4").font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(inkColor)
                    }
                } else {
                    Text("tap to reveal the greedy chain")
                        .font(.system(size: 12, design: .serif)).italic().foregroundStyle(tealAccent)
                }
            }
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 11)
                .fill(showGreedy ? scRose.opacity(0.06) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var voteCard: some View {
        if showGreedy {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                showVote = true
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SELF-CONSISTENCY: VOTE OVER 40 SAMPLES")
                        .font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(tealAccent)
                    if showVote {
                        HStack(spacing: 14) {
                            voteStat("3", "31 votes", true)
                            voteStat("4", "7 votes", false)
                            voteStat("5", "2 votes", false)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(tealAccent)
                            Text("Answer: 3").font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(inkColor)
                        }
                    } else {
                        Text("tap to sample many and count the votes")
                            .font(.system(size: 12, design: .serif)).italic().foregroundStyle(tealAccent)
                    }
                }
                .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 11)
                    .fill(showVote ? tealAccent.opacity(0.07) : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(tealAccent.opacity(0.4), lineWidth: 1)))
            }
            .buttonStyle(.plain)
        }
    }

    private func voteStat(_ ans: String, _ n: String, _ win: Bool) -> some View {
        VStack(spacing: 2) {
            Text(ans).font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(win ? tealAccent : mutedText)
            Text(n).font(.system(size: 10, design: .monospaced)).foregroundStyle(mutedText)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(showVote ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(showVote
                 ? "The model's single most-confident chain was wrong. But across many samples, the right answer was reachable by far more routes, so the vote recovered it."
                 : "Reveal the greedy chain, then the vote.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - DiversityStudio (interactive 3)
//
// A temperature dial. Too low: every sample is the same chain, so a wrong
// answer can never be outvoted. Too high: chains turn to noise and answers
// scatter. The sweet spot gives varied-but-sound paths that agree on the
// truth. Landing on the sweet spot completes.

private struct SCDiversity {
    let label: String
    let blurb: String
    let answers: [String]   // the sampled answers at this setting
    let accuracy: Int
    let good: Bool
}

private let scDiversities: [SCDiversity] = [
    SCDiversity(label: "Too low (t=0)", blurb: "Every sample is the identical chain. If it is wrong, voting cannot help: there is nothing to outvote it.",
                answers: ["4", "4", "4", "4", "4"], accuracy: 18, good: false),
    SCDiversity(label: "Just right (t=0.7)", blurb: "Varied but sound routes. Several disagree, but the right answer is reachable by the most of them, so the vote lands it.",
                answers: ["3", "3", "4", "3", "3"], accuracy: 57, good: true),
    SCDiversity(label: "Too high (t=1.4)", blurb: "The chains turn to noise. Answers scatter with no clear majority, so the vote is no better than a guess.",
                answers: ["3", "7", "4", "9", "2"], accuracy: 22, good: false),
]

struct DiversityStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var foundSweet = false

    private var idx: Int { min(scDiversities.count - 1, max(0, Int(level.rounded()))) }
    private var d: SCDiversity { scDiversities[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("DIAL THE DIVERSITY")
                .font(.system(size: 11, weight: .bold)).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Voting only works if the samples differ. Turn the sampling temperature up and down. Find the setting where the paths vary just enough to agree on the truth.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            dial
            samplesRow
            noteCard
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.32), value: idx)
    }

    private var dial: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(scDiversities.enumerated()), id: \.offset) { i, s in
                    Text(s.label.components(separatedBy: " (").first ?? s.label)
                        .font(.system(size: 10, weight: i == idx ? .bold : .regular))
                        .foregroundStyle(i == idx ? (s.good ? tealAccent : scRose) : mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            Slider(value: $level, in: 0...Double(scDiversities.count - 1), step: 1)
                .tint(d.good ? tealAccent : scRose)
                .onChange(of: level) { _, _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    if d.good, !foundSweet {
                        foundSweet = true
                        progress.markExplored(cardId)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
        }
    }

    private var samplesRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("FIVE SAMPLES").font(.system(size: 9, weight: .bold)).tracking(1.2)
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(d.accuracy)%").font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(d.good ? tealAccent : scRose)
                    .contentTransition(.numericText())
            }
            HStack(spacing: 8) {
                ForEach(Array(d.answers.enumerated()), id: \.offset) { _, a in
                    Text(a).font(.system(size: 15, weight: .bold, design: .serif)).foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(a == "3" ? tealAccent : mutedText.opacity(0.55)))
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: d.good ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14)).foregroundStyle(d.good ? tealAccent : amberAccent)
            Text(d.blurb)
                .font(.system(size: 13, design: .serif)).foregroundStyle(inkColor.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill((d.good ? tealAccent : amberAccent).opacity(0.07)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(foundSweet ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(foundSweet
                 ? "Diversity is the fuel. Identical samples cannot outvote a mistake, and pure noise has no majority. The middle ground is where self-consistency pays off."
                 : "Find the setting where the samples vary but still agree on the right answer.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
