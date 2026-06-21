import SwiftUI

// MARK: - Tree-of-Thoughts bespoke interactives
//
// 2023, Yao et al. (Princeton / Google DeepMind). "Tree of Thoughts." A chain
// commits to one line of reasoning and cannot recover from a wrong turn. ToT
// generalises the chain into a tree: at each step generate several candidate
// thoughts, have the model self-evaluate each (sure / maybe / impossible),
// then search, pruning dead branches and backtracking. On Game of 24, GPT-4
// went from about 4% with chain of thought to 74% with ToT.
//
// Diagrams built around the search:
//   EvaluateStudio    - the new power: the model judges a partial thought.
//   Game24TreeStudio  - the signature: expand, evaluate, prune, backtrack, win.
//   ChainVsTreeStudio - why a tree beats a single chain: it can back up.

private let toRose = Color(hex: "d46a6a")

private enum ToTVerdict {
    case sure, maybe, impossible
    var color: Color {
        switch self {
        case .sure: return tealAccent
        case .maybe: return amberAccent
        case .impossible: return toRose
        }
    }
    var label: String {
        switch self {
        case .sure: return "sure"
        case .maybe: return "maybe"
        case .impossible: return "impossible"
        }
    }
    var icon: String {
        switch self {
        case .sure: return "checkmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        case .impossible: return "xmark.circle.fill"
        }
    }
}

// MARK: - TreeOfThoughtsGlyph (cover hero)
//
// A small tree: a root, branches that fan out, two pruned (faded) and one live
// path that reaches a goal star.

struct TreeOfThoughtsGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let rootX = w * 0.5, rootY = h * 0.22
            let mids: [CGPoint] = [CGPoint(x: w * 0.28, y: h * 0.52),
                                   CGPoint(x: w * 0.5, y: h * 0.52),
                                   CGPoint(x: w * 0.72, y: h * 0.52)]
            let goal = CGPoint(x: w * 0.72, y: h * 0.8)
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Path { p in
                        p.move(to: CGPoint(x: rootX, y: rootY))
                        p.addLine(to: mids[i])
                    }
                    .trim(from: 0, to: t)
                    .stroke((i == 2 ? tealAccent : Color(hex: "f4f1ea")).opacity(i == 2 ? 0.9 : 0.25),
                            style: StrokeStyle(lineWidth: i == 2 ? 2 : 1.2, lineCap: .round))
                }
                Path { p in p.move(to: mids[2]); p.addLine(to: goal) }
                    .trim(from: 0, to: max(0, t * 2 - 1))
                    .stroke(tealAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                dot(rootX, rootY, tealAccent.opacity(0.4), "?")
                ForEach(0..<3, id: \.self) { i in
                    dot(mids[i].x, mids[i].y,
                        i == 2 ? tealAccent.opacity(0.5) : toRose.opacity(0.35),
                        i == 2 ? "" : "\u{2717}")
                }
                Image(systemName: "star.fill")
                    .scaledFont(size: 16).foregroundStyle(amberAccent)
                    .position(goal).opacity(t > 0.7 ? 1 : 0.2)

                Text("EXPLORE, EVALUATE, BACKTRACK")
                    .scaledFont(size: 9, weight: .bold).tracking(1.4)
                    .foregroundStyle(tealAccent)
                    .position(x: w / 2, y: h * 0.96)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { t = 1 }
        }
    }
    private func dot(_ x: CGFloat, _ y: CGFloat, _ fill: Color, _ s: String) -> some View {
        Text(s).scaledFont(size: 11, weight: .bold).foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(fill))
            .position(x: x, y: y)
    }
}

// MARK: - ChainVsTreeArt (big-idea illustration)
//
// A chain runs into a wall with nowhere to go. A tree branches, prunes a dead
// end, and finds a way through.

struct ChainVsTreeArt: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("A CHAIN").scaledFont(size: 9, weight: .bold).tracking(1.3).foregroundStyle(toRose)
                HStack(spacing: 6) {
                    node("start", tealAccent)
                    seg; node("step", tealAccent); seg; node("step", mutedText)
                    Image(systemName: "nosign").scaledFont(size: 14).foregroundStyle(toRose)
                }
                Text("one wrong turn, no way back").scaledFont(size: 10, design: .serif).italic()
                    .foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(toRose.opacity(0.05)))

            VStack(alignment: .leading, spacing: 8) {
                Text("A TREE").scaledFont(size: 9, weight: .bold).tracking(1.3).foregroundStyle(tealAccent)
                HStack(spacing: 6) {
                    node("start", tealAccent)
                    seg
                    VStack(spacing: 5) {
                        HStack(spacing: 4) {
                            node("a", mutedText)
                            Image(systemName: "xmark").scaledFont(size: 9, weight: .black).foregroundStyle(toRose)
                        }
                        HStack(spacing: 4) {
                            node("b", tealAccent)
                            Image(systemName: "arrow.right").scaledFont(size: 8, weight: .bold).foregroundStyle(mutedText)
                            Image(systemName: "star.fill").scaledFont(size: 11).foregroundStyle(amberAccent)
                        }
                    }
                }
                Text("dead end pruned, another branch wins").scaledFont(size: 10, design: .serif).italic()
                    .foregroundStyle(mutedText)
            }
            .padding(11).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05)))
        }
        .padding(.vertical, 4)
    }
    private var seg: some View {
        Image(systemName: "arrow.right").scaledFont(size: 8, weight: .bold).foregroundStyle(mutedText)
    }
    private func node(_ s: String, _ tint: Color) -> some View {
        Text(s).scaledFont(size: 10, weight: .semibold, design: .serif).foregroundStyle(inkColor.opacity(0.8))
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.5), lineWidth: 1)))
    }
}

// MARK: - EvaluatePruneArt (illustration)
//
// Three candidate next-thoughts from one state, each carrying the model's own
// verdict: sure, maybe, impossible.

struct EvaluatePruneArt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FROM 6, 9, 13 \u{2014} THREE MOVES").scaledFont(size: 9, weight: .bold).tracking(1.2)
                .foregroundStyle(mutedText)
            candidate("13 - 9 = 4", verdict: .sure, note: "leaves 6 and 4")
            candidate("6 + 9 = 15", verdict: .impossible, note: "15 and 13 fall short")
            candidate("13 + 6 = 19", verdict: .maybe, note: "close, but 9 left over")
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }
    private func candidate(_ expr: String, verdict: ToTVerdict, note: String) -> some View {
        HStack(spacing: 10) {
            Text(expr).scaledFont(size: 12, weight: .semibold, design: .monospaced)
                .foregroundStyle(inkColor.opacity(0.82)).frame(width: 100, alignment: .leading)
            Text(note).scaledFont(size: 11, design: .serif).italic().foregroundStyle(mutedText)
            Spacer(minLength: 0)
            HStack(spacing: 3) {
                Image(systemName: verdict.icon).scaledFont(size: 11).foregroundStyle(verdict.color)
                Text(verdict.label).scaledFont(size: 10, weight: .bold).foregroundStyle(verdict.color)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(verdict.color.opacity(0.06)))
    }
}

// MARK: - EvaluateStudio (interactive 1)
//
// The capability a tree needs: the model can look at a partial state and judge
// whether it can still reach the goal. Tap each candidate to reveal its
// verdict. Revealing all three completes the card.

private struct ToTCandidate {
    let expr: String
    let result: String
    let verdict: ToTVerdict
    let note: String
}

struct EvaluateStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let candidates: [ToTCandidate] = [
        ToTCandidate(expr: "10 - 4 = 6", result: "6, 9, 13", verdict: .sure,
                     note: "Leaves 6, 9, 13. From here 6 \u{00D7} (13 - 9) = 24, so this branch is alive."),
        ToTCandidate(expr: "4 \u{00D7} 9 = 36", result: "36, 10, 13", verdict: .impossible,
                     note: "36 already overshoots 24 and the moves left only grow it. Dead branch."),
        ToTCandidate(expr: "13 + 10 = 23", result: "23, 4, 9", verdict: .maybe,
                     note: "23 is tantalisingly close, but 4 and 9 cannot nudge it to exactly 24."),
    ]

    @State private var revealed: Set<Int> = []

    private var done: Bool { revealed.count >= candidates.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("CAN THIS STILL REACH 24?")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("The game is 24: combine 4, 9, 10, 13 with + - \u{00D7} \u{00F7} to make 24. Before searching, a tree needs one new power: the model can judge a half-finished attempt. Tap each first move to see its verdict.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(candidates.enumerated()), id: \.offset) { i, c in
                candidateRow(i: i, c: c)
            }
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: revealed)
    }

    private func candidateRow(i: Int, c: ToTCandidate) -> some View {
        let shown = revealed.contains(i)
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            revealed.insert(i)
            if done { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(c.expr).scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundStyle(inkColor.opacity(0.85))
                    Image(systemName: "arrow.right").scaledFont(size: 9, weight: .bold).foregroundStyle(mutedText)
                    Text(c.result).scaledFont(size: 13, design: .monospaced).foregroundStyle(mutedText)
                    Spacer(minLength: 0)
                    if shown {
                        HStack(spacing: 3) {
                            Image(systemName: c.verdict.icon).scaledFont(size: 13).foregroundStyle(c.verdict.color)
                            Text(c.verdict.label).scaledFont(size: 11, weight: .bold).foregroundStyle(c.verdict.color)
                        }
                    } else {
                        Text("evaluate").scaledFont(size: 11, weight: .semibold).foregroundStyle(tealAccent)
                    }
                }
                if shown {
                    Text(c.note).scaledFont(size: 12.5, design: .serif).foregroundStyle(inkColor.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 11)
                .fill(shown ? c.verdict.color.opacity(0.06) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .stroke(shown ? c.verdict.color.opacity(0.4) : borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(done ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(done
                 ? "This is the new ingredient. A chain just charges ahead, but a tree can ask 'is this branch still worth it?' and label each one before committing."
                 : "Evaluate all three first moves to see how the model scores partial progress.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Game24TreeStudio (interactive 2)
//
// The signature interactive. Search the tree for 24: expand a node, the model
// evaluates each child, pick a live branch (or hit a dead end and back up).
// Reaching 6 x 4 = 24 completes the card.

private struct ToTMove {
    let expr: String
    let result: String
    let verdict: ToTVerdict
    let onPath: Bool
    let note: String
}

struct Game24TreeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    // Level 0 from {4,9,10,13}; level 1 from {6,9,13}; reaching {6,4} solves.
    private let levels: [[ToTMove]] = [
        [
            ToTMove(expr: "10 - 4 = 6", result: "6, 9, 13", verdict: .sure, onPath: true,
                    note: "Alive: leaves 6, 9, 13."),
            ToTMove(expr: "4 \u{00D7} 9 = 36", result: "36, 10, 13", verdict: .impossible, onPath: false,
                    note: "Pruned: 36 overshoots 24."),
            ToTMove(expr: "13 + 10 = 23", result: "23, 4, 9", verdict: .maybe, onPath: false,
                    note: "Dead end: 23 can't reach 24 from 4 and 9."),
        ],
        [
            ToTMove(expr: "13 - 9 = 4", result: "6, 4", verdict: .sure, onPath: true,
                    note: "Alive: leaves 6 and 4."),
            ToTMove(expr: "6 + 9 = 15", result: "15, 13", verdict: .impossible, onPath: false,
                    note: "Pruned: 15 and 13 fall short."),
            ToTMove(expr: "9 - 6 = 3", result: "3, 13", verdict: .impossible, onPath: false,
                    note: "Pruned: 3 and 13 fall short."),
        ],
    ]

    @State private var level = 0
    @State private var chosen: [String] = ["4, 9, 10, 13"]   // states visited on the path
    @State private var pruned: Set<String> = []              // "level-index" keys tried and dead
    @State private var solved = false
    @State private var lastNote: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("SEARCH THE TREE FOR 24")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Now do the search yourself. Pick a move; the model evaluates where it leads. A live branch moves you forward, a dead branch gets pruned and you back up and try another.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            pathView
            if !solved { movesView } else { solvedView }
            if let n = lastNote, !solved { noteRow(n) }
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.32), value: level)
        .motionAware(.snappy(duration: 0.3), value: pruned)
        .motionAware(.snappy(duration: 0.3), value: solved)
    }

    private var pathView: some View {
        HStack(spacing: 6) {
            ForEach(Array(chosen.enumerated()), id: \.offset) { i, s in
                if i > 0 {
                    Image(systemName: "arrow.right").scaledFont(size: 9, weight: .bold).foregroundStyle(tealAccent)
                }
                Text("{ \(s) }")
                    .scaledFont(size: 12, weight: .bold, design: .monospaced)
                    .foregroundStyle(i == chosen.count - 1 ? tealAccent : inkColor.opacity(0.6))
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 7)
                        .fill(i == chosen.count - 1 ? tealAccent.opacity(0.1) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(borderColor, lineWidth: 1)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var movesView: some View {
        VStack(spacing: 8) {
            ForEach(Array(levels[level].enumerated()), id: \.offset) { i, m in
                let key = "\(level)-\(i)"
                let isPruned = pruned.contains(key)
                Button {
                    tap(move: m, key: key)
                } label: {
                    HStack(spacing: 10) {
                        Text(m.expr)
                            .scaledFont(size: 13, weight: .bold, design: .monospaced)
                            .foregroundStyle(isPruned ? mutedText : inkColor.opacity(0.85))
                            .strikethrough(isPruned)
                        Image(systemName: "arrow.right").scaledFont(size: 8, weight: .bold).foregroundStyle(mutedText)
                        Text(m.result).scaledFont(size: 12, design: .monospaced).foregroundStyle(mutedText)
                        Spacer(minLength: 0)
                        if isPruned {
                            HStack(spacing: 3) {
                                Image(systemName: m.verdict.icon).scaledFont(size: 12).foregroundStyle(m.verdict.color)
                                Text(m.verdict.label).scaledFont(size: 10, weight: .bold).foregroundStyle(m.verdict.color)
                            }
                        } else {
                            Image(systemName: "magnifyingglass").scaledFont(size: 12).foregroundStyle(tealAccent)
                        }
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(isPruned ? toRose.opacity(0.05) : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .disabled(isPruned)
            }
        }
    }

    private var solvedView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("6 \u{00D7} 4 = 24").scaledFont(size: 18, weight: .bold, design: .monospaced)
                    .foregroundStyle(tealAccent)
                Image(systemName: "star.fill").scaledFont(size: 16).foregroundStyle(amberAccent)
            }
            Text("Solved. (10 - 4) \u{00D7} (13 - 9) = 24")
                .scaledFont(size: 13, weight: .semibold, design: .monospaced).foregroundStyle(inkColor.opacity(0.8))
        }
        .padding(16).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(tealAccent.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tealAccent.opacity(0.4), lineWidth: 1)))
    }

    private func noteRow(_ n: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle.fill").scaledFont(size: 13).foregroundStyle(amberAccent)
            Text(n).scaledFont(size: 13, design: .serif).foregroundStyle(inkColor.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 9).fill(amberAccent.opacity(0.08)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(solved ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(solved
                 ? "That is tree of thoughts: branch, evaluate, prune the dead ends, and follow the live path. A chain could never have backed out of a wrong first move."
                 : "Pick a move. Dead branches get pruned, so back up and try another.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tap(move: ToTMove, key: String) {
        if move.onPath {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            chosen.append(move.result)
            lastNote = nil
            if level >= levels.count - 1 {
                solved = true
                progress.markExplored(cardId)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                level += 1
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            pruned.insert(key)
            lastNote = move.note + " Back up and try another branch."
        }
    }
}

// MARK: - ChainVsTreeStudio (interactive 3)
//
// Why a tree wins: flip between chain mode and tree mode on the same dead-end
// first move. The chain is stuck; the tree backtracks and finds the goal.
// Switching to tree mode completes.

struct ChainVsTreeStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var treeMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("STUCK, OR BACK UP?")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Suppose the very first move was a bad one: 4 \u{00D7} 9 = 36. Flip between how a chain and a tree handle that same wrong turn.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            modeToggle
            stage
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.32), value: treeMode)
    }

    private var modeToggle: some View {
        Picker("", selection: $treeMode) {
            Text("Chain").tag(false)
            Text("Tree").tag(true)
        }
        .pickerStyle(.segmented)
        .onChange(of: treeMode) { _, on in
            UISelectionFeedbackGenerator().selectionChanged()
            if on { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }

    private var stage: some View {
        VStack(alignment: .leading, spacing: 10) {
            row(state: "4, 9, 10, 13", label: "start", tint: tealAccent, struckOut: false)
            arrowDown
            row(state: "36, 10, 13", label: "4 \u{00D7} 9 = 36  \u{2014} bad move", tint: toRose, struckOut: true)
            if treeMode {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.left").scaledFont(size: 12, weight: .bold).foregroundStyle(amberAccent)
                    Text("backtrack").scaledFont(size: 11, weight: .bold).foregroundStyle(amberAccent)
                }
                .padding(.leading, 4)
                row(state: "6, 9, 13", label: "10 - 4 = 6  \u{2014} try another", tint: tealAccent, struckOut: false)
                arrowDown
                HStack(spacing: 8) {
                    Text("\u{2192} 6 \u{00D7} 4 = 24")
                        .scaledFont(size: 14, weight: .bold, design: .monospaced).foregroundStyle(tealAccent)
                    Image(systemName: "star.fill").scaledFont(size: 13).foregroundStyle(amberAccent)
                }
                .padding(.leading, 4)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "nosign").scaledFont(size: 14).foregroundStyle(toRose)
                    Text("stuck \u{2014} the chain already committed, with no way back")
                        .scaledFont(size: 12, design: .serif).italic().foregroundStyle(mutedText)
                }
                .padding(.leading, 4)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill((treeMode ? tealAccent : toRose).opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke((treeMode ? tealAccent : toRose).opacity(0.3), lineWidth: 1)))
    }

    private var arrowDown: some View {
        Image(systemName: "arrow.down").scaledFont(size: 11, weight: .bold).foregroundStyle(mutedText)
            .padding(.leading, 12)
    }
    private func row(state: String, label: String, tint: Color, struckOut: Bool) -> some View {
        HStack(spacing: 10) {
            Text("{ \(state) }")
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .foregroundStyle(struckOut ? mutedText : inkColor.opacity(0.85))
                .strikethrough(struckOut)
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7).fill(tint.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(tint.opacity(0.4), lineWidth: 1)))
            Text(label).scaledFont(size: 11, design: .serif).italic().foregroundStyle(mutedText)
            Spacer(minLength: 0)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(treeMode ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(treeMode
                 ? "A tree treats a wrong move as one branch among many. It backs up and explores another, which is exactly why it can solve puzzles a single chain cannot."
                 : "In chain mode the model is stuck. Flip to tree mode to see it recover.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
