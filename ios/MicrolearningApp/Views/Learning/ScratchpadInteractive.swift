import SwiftUI

// MARK: - Scratchpad bespoke interactives
//
// 2021, Nye et al. (Google). "Show Your Work: Scratchpads for Intermediate
// Computation with Language Models." A model asked for the answer in one shot
// fails algorithmic tasks (long addition, executing code) because there is no
// room to compute. Give it a scratchpad to emit intermediate state, step by
// step, and it succeeds, and crucially keeps working as the input gets longer.
//
// Diagrams are built around the paper's own examples:
//   ColumnCarryStudio   - long addition done column by column, carries written
//                         on the pad, exactly the paper's headline task.
//   ProgramTraceStudio  - execute a tiny program by writing each variable's
//                         state to the pad, line by line.
//   LengthLadderStudio  - drag the input length; direct answers fall off the
//                         ladder while the scratchpad keeps climbing.

private let spRose = Color(hex: "d46a6a")

// MARK: - ScratchpadGlyph (cover hero)
//
// A notepad with a pencil. Faint ruled lines fill in with intermediate marks,
// then a boxed answer settles at the foot.

struct ScratchpadGlyph: View {
    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let padW = w * 0.5, padH = h * 0.62
            let x0 = (w - padW) / 2, y0 = (h - padH) / 2
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "f4f1ea").opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "f4f1ea").opacity(0.35), lineWidth: 1.5))
                    .frame(width: padW, height: padH)

                // Ruled lines filling in as work is shown.
                ForEach(0..<3, id: \.self) { i in
                    let ly = y0 + padH * (0.26 + Double(i) * 0.18)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(tealAccent.opacity(0.8))
                        .frame(width: padW * 0.6 * min(1, max(0, t * 3 - Double(i))), height: 2)
                        .position(x: x0 + padW * 0.18 + (padW * 0.3), y: ly)
                }

                // Boxed answer at the foot.
                Text("= 1134")
                    .scaledFont(size: 13, weight: .bold, design: .monospaced)
                    .foregroundStyle(tealAccent)
                    .opacity(t > 0.8 ? 1 : 0.15)
                    .position(x: w / 2, y: y0 + padH * 0.82)

                // Pencil.
                Image(systemName: "pencil")
                    .scaledFont(size: 22, weight: .semibold)
                    .foregroundStyle(amberAccent)
                    .rotationEffect(.degrees(45))
                    .position(x: x0 + padW * 0.82, y: y0 + padH * (0.26 + t * 0.4))

                Text("ROOM TO COMPUTE")
                    .scaledFont(size: 9, weight: .bold).tracking(1.8)
                    .foregroundStyle(tealAccent)
                    .position(x: w / 2, y: y0 + padH + 22)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { t = 1 }
        }
    }
}

// MARK: - DirectVsScratchpadArt (big-idea illustration)
//
// One shot: a hard sum collapses into a single blank, then a wrong number.
// With a scratchpad: the same sum unfolds into worked lines, then the right
// number. Built around the no-room-to-compute idea.

struct DirectVsScratchpadArt: View {
    var body: some View {
        VStack(spacing: 12) {
            row(tag: "ONE SHOT", tint: spRose, correct: false) {
                HStack(spacing: 6) {
                    chip("456 + 678")
                    Image(systemName: "arrow.right").scaledFont(size: 9, weight: .bold)
                        .foregroundStyle(mutedText)
                    Text("?").scaledFont(size: 14, weight: .bold, design: .monospaced)
                        .foregroundStyle(mutedText)
                        .frame(width: 30, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).fill(mutedText.opacity(0.1)))
                    Image(systemName: "arrow.right").scaledFont(size: 9, weight: .bold)
                        .foregroundStyle(mutedText)
                    answer("1024", correct: false)
                }
            }
            row(tag: "WITH A SCRATCHPAD", tint: tealAccent, correct: true) {
                VStack(alignment: .leading, spacing: 3) {
                    padLine("6 + 8 = 14, write 4 carry 1")
                    padLine("5 + 7 + 1 = 13, write 3 carry 1")
                    padLine("4 + 6 + 1 = 11, write 11")
                    HStack(spacing: 5) {
                        answer("1134", correct: true)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func row<Content: View>(tag: String, tint: Color, correct: Bool,
                                    @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tag).scaledFont(size: 9, weight: .bold).tracking(1.3).foregroundStyle(tint)
            content()
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.25), lineWidth: 1)))
    }
    private func chip(_ t: String) -> some View {
        Text(t).scaledFont(size: 12, weight: .semibold, design: .monospaced)
            .foregroundStyle(inkColor.opacity(0.8))
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderColor, lineWidth: 1)))
    }
    private func padLine(_ t: String) -> some View {
        Text(t).scaledFont(size: 10.5, design: .monospaced).foregroundStyle(tealAccent)
    }
    private func answer(_ t: String, correct: Bool) -> some View {
        HStack(spacing: 3) {
            Text(t).scaledFont(size: 12, weight: .bold, design: .monospaced).foregroundStyle(.white)
            Image(systemName: correct ? "checkmark" : "xmark")
                .scaledFont(size: 8, weight: .black).foregroundStyle(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(correct ? tealAccent : spRose))
    }
}

// MARK: - ProgramTraceArt (illustration)
//
// A tiny program beside the running state the scratchpad keeps. Built around
// the paper's "execute the code, line by line" task.

struct ProgramTraceArt: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("PROGRAM").scaledFont(size: 9, weight: .bold).tracking(1.2)
                    .foregroundStyle(mutedText)
                code("a = 2")
                code("b = a + 3")
                code("a = b * a")
                code("print(a)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text("SCRATCHPAD").scaledFont(size: 9, weight: .bold).tracking(1.2)
                    .foregroundStyle(tealAccent)
                trace("a = 2")
                trace("b = 5")
                trace("a = 10")
                trace("out: 10")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }
    private func code(_ t: String) -> some View {
        Text(t).scaledFont(size: 12, design: .monospaced).foregroundStyle(inkColor.opacity(0.85))
    }
    private func trace(_ t: String) -> some View {
        Text(t).scaledFont(size: 12, design: .monospaced).foregroundStyle(tealAccent)
    }
}

// MARK: - ColumnCarryStudio (interactive 1)
//
// Long addition, column by column. Tap to compute the next column right to
// left; the digit drops into the answer and the carry lands on the pad. The
// signature scratchpad task. Finishing the columns completes the card.

private struct SPColumn {
    let top: Int
    let bottom: Int
    // carry-in is computed as we go
}

struct ColumnCarryStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    // 456 + 678 = 1134, columns ordered units -> hundreds.
    private let cols: [SPColumn] = [
        SPColumn(top: 6, bottom: 8),
        SPColumn(top: 5, bottom: 7),
        SPColumn(top: 4, bottom: 6),
    ]
    private let topNum = "456", bottomNum = "678", blurt = "1024"

    @State private var step = 0          // columns computed so far (0...3), 3 = final carry done
    @State private var carries = [0, 0, 0, 0]   // carry-in per column index (0 = units)
    @State private var digits: [Int?] = [nil, nil, nil, nil]  // result digits: units, tens, hundreds, thousands

    private var done: Bool { step >= cols.count + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("ADD IT ON THE PAD")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Asked for 456 + 678 in one shot, the model guesses \(blurt), and it is wrong. Give it a scratchpad and it adds one column at a time, carrying as it goes. Tap to work each column, right to left.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            sumGrid
            workNote
            actionButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.32), value: step)
    }

    // Columns are drawn right-aligned: thousands, hundreds, tens, units.
    private var sumGrid: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Carry row.
            HStack(spacing: 10) {
                carryCell(3); carryCell(2); carryCell(1); carryCell(0)
            }
            digitRow(["", String(topNum.prefix(1).suffix(1)), String(Array(topNum)[1]), String(Array(topNum)[2])], lead: " ")
            HStack(spacing: 10) {
                cell("+", muted: true)
                cell(String(Array(bottomNum)[0])); cell(String(Array(bottomNum)[1])); cell(String(Array(bottomNum)[2]))
            }
            Rectangle().fill(inkColor.opacity(0.4)).frame(height: 1.5).frame(width: 4 * 38 + 30)
            // Result row: thousands, hundreds, tens, units.
            HStack(spacing: 10) {
                resultCell(3); resultCell(2); resultCell(1); resultCell(0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(tealAccent.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tealAccent.opacity(0.2), lineWidth: 1)))
    }

    private func digitRow(_ vals: [String], lead: String) -> some View {
        HStack(spacing: 10) {
            cell(lead, muted: true)
            cell(vals[1]); cell(vals[2]); cell(vals[3])
        }
    }

    private func cell(_ s: String, muted: Bool = false) -> some View {
        Text(s)
            .scaledFont(size: 18, weight: .semibold, design: .monospaced)
            .foregroundStyle(muted ? mutedText : inkColor.opacity(0.85))
            .frame(width: 38, height: 30)
    }

    // colIdx: 0 units ... 3 thousands
    private func carryCell(_ colIdx: Int) -> some View {
        Group {
            if colIdx >= 1 && colIdx <= 3 && carries[colIdx] > 0 && step > (colIdx - 1) {
                Text("\(carries[colIdx])")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundStyle(amberAccent)
            } else {
                Text(" ").scaledFont(size: 11, design: .monospaced)
            }
        }
        .frame(width: 38, height: 16)
    }

    private func resultCell(_ colIdx: Int) -> some View {
        let active = colIdx == step && step < cols.count
        return Text(digits[colIdx].map(String.init) ?? "")
            .scaledFont(size: 18, weight: .bold, design: .monospaced)
            .foregroundStyle(tealAccent)
            .frame(width: 38, height: 32)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(active ? amberAccent.opacity(0.18) : Color.clear))
    }

    private var workNote: some View {
        Group {
            if step == 0 {
                noteText("Start at the units column on the right.")
            } else if step <= cols.count {
                let i = step - 1
                let cin = carries[i]
                let total = cols[i].top + cols[i].bottom + cin
                let carryStr = total >= 10 ? ", carry 1" : ""
                noteText("\(cols[i].top) + \(cols[i].bottom)\(cin > 0 ? " + \(cin) carried" : "") = \(total). Write \(total % 10)\(carryStr).")
            } else {
                noteText("The last carry drops down to make the thousands digit. 456 + 678 = 1134.")
            }
        }
    }
    private func noteText(_ t: String) -> some View {
        Text(t).scaledFont(size: 13, weight: .semibold, design: .monospaced)
            .foregroundStyle(inkColor.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 9).fill(amberAccent.opacity(0.08)))
    }

    @ViewBuilder
    private var actionButton: some View {
        if !done {
            Button {
                advance()
            } label: {
                Text(step == 0 ? "Work the units column"
                     : step < cols.count ? "Next column" : "Drop the final carry")
                    .scaledFont(size: 14, weight: .semibold).foregroundStyle(.white)
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
                 ? "No single step was hard. The scratchpad just gave the model somewhere to put each partial result and carry, so nothing had to be done all at once."
                 : "Compute each column and watch the carries land on the pad.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func advance() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if step < cols.count {
            let i = step
            let cin = carries[i]
            let total = cols[i].top + cols[i].bottom + cin
            digits[i] = total % 10
            if total >= 10 { carries[i + 1] = 1 }
            step += 1
            if step == cols.count, carries[cols.count] > 0 {
                // there is a final carry to drop next tap
            } else if step == cols.count {
                step += 1   // no final carry, finish
            }
        } else {
            digits[cols.count] = carries[cols.count]
            step += 1
        }
        if done {
            progress.markExplored(cardId)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - ProgramTraceStudio (interactive 2)
//
// Execute a tiny program by writing each variable's value to the pad, one line
// at a time. Without the pad the model guesses the output; with it, it tracks
// the state and prints the right number. Stepping to the end completes.

private struct SPProgLine {
    let code: String
    let a: Int?
    let b: Int?
    let out: String?
}

struct ProgramTraceStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    private let lines: [SPProgLine] = [
        SPProgLine(code: "a = 2",        a: 2,  b: nil, out: nil),
        SPProgLine(code: "b = a + 3",    a: 2,  b: 5,   out: nil),
        SPProgLine(code: "a = b * a",    a: 10, b: 5,   out: nil),
        SPProgLine(code: "print(a)",     a: 10, b: 5,   out: "10"),
    ]
    private let blurt = "7"

    @State private var executed = 0   // lines executed
    @State private var showedBlurt = false

    private var done: Bool { executed >= lines.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("RUN THE CODE ON THE PAD")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Scratchpads are not just for sums. Ask for this program's output in one shot and the model guesses. Step through it instead, writing each variable's value down, and it tracks the state exactly.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            blurtRow
            codeAndState
            stepButton
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: executed)
        .motionAware(.snappy(duration: 0.3), value: showedBlurt)
    }

    private var blurtRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(); showedBlurt = true
        } label: {
            HStack(spacing: 10) {
                Text("ONE-SHOT GUESS").scaledFont(size: 9, weight: .bold).tracking(1.3)
                    .foregroundStyle(mutedText)
                Spacer(minLength: 0)
                if showedBlurt {
                    HStack(spacing: 4) {
                        Text(blurt).scaledFont(size: 15, weight: .bold, design: .monospaced)
                            .foregroundStyle(inkColor)
                        Image(systemName: "xmark.circle.fill").foregroundStyle(spRose)
                    }
                } else {
                    Text("tap to guess").scaledFont(size: 12, design: .serif).italic()
                        .foregroundStyle(tealAccent)
                }
            }
            .padding(13).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 11)
                .fill(showedBlurt ? spRose.opacity(0.07) : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(borderColor, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private var codeAndState: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PROGRAM").scaledFont(size: 9, weight: .bold).tracking(1.2)
                    .foregroundStyle(mutedText)
                ForEach(Array(lines.enumerated()), id: \.offset) { i, l in
                    Text(l.code)
                        .scaledFont(size: 13, design: .monospaced)
                        .foregroundStyle(i < executed ? inkColor.opacity(0.85)
                                         : (i == executed ? inkColor : mutedText.opacity(0.4)))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6)
                            .fill(i == executed && !done ? amberAccent.opacity(0.15) : Color.clear))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("SCRATCHPAD").scaledFont(size: 9, weight: .bold).tracking(1.2)
                    .foregroundStyle(tealAccent)
                stateRow("a", value: executed == 0 ? nil : lines[executed - 1].a)
                stateRow("b", value: executed == 0 ? nil : lines[executed - 1].b)
                let out = executed > 0 ? lines[executed - 1].out : nil
                HStack(spacing: 6) {
                    Image(systemName: out != nil ? "checkmark.circle.fill" : "circle")
                        .scaledFont(size: 12).foregroundStyle(out != nil ? tealAccent : mutedText.opacity(0.4))
                    Text(out != nil ? "out: \(out!)" : "out: \u{2014}")
                        .scaledFont(size: 13, weight: .bold, design: .monospaced)
                        .foregroundStyle(out != nil ? inkColor : mutedText.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 10).fill(tealAccent.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(tealAccent.opacity(0.25), lineWidth: 1)))
        }
    }

    private func stateRow(_ name: String, value: Int?) -> some View {
        HStack(spacing: 6) {
            Text("\(name) =").scaledFont(size: 13, design: .monospaced).foregroundStyle(mutedText)
            Text(value.map(String.init) ?? "\u{2014}")
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .foregroundStyle(value == nil ? mutedText.opacity(0.5) : tealAccent)
                .contentTransition(.numericText())
        }
    }

    @ViewBuilder
    private var stepButton: some View {
        if !done {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                executed += 1
                if done { progress.markExplored(cardId); UINotificationFeedbackGenerator().notificationOccurred(.success) }
            } label: {
                Text(executed == 0 ? "Run first line" : "Run next line")
                    .scaledFont(size: 14, weight: .semibold).foregroundStyle(.white)
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
                 ? "By writing a and b after every line, the model never had to hold the whole computation in its head. The pad is its working memory."
                 : "Run each line and watch the scratchpad track the variables.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - LengthLadderStudio (interactive 3)
//
// The paper's real punchline: scratchpads keep working as inputs get longer.
// Drag the number length up a ladder of rungs; the one-shot climber falls off
// while the scratchpad climber keeps going. Reaching the top rung completes.

private struct SPRung {
    let label: String
    let digits: String
    let direct: Int     // accuracy
    let pad: Int
}

private let spRungs: [SPRung] = [
    SPRung(label: "1 digit",  digits: "3 + 4",                direct: 99, pad: 99),
    SPRung(label: "2 digits", digits: "29 + 57",             direct: 82, pad: 98),
    SPRung(label: "3 digits", digits: "456 + 678",           direct: 47, pad: 97),
    SPRung(label: "5 digits", digits: "48 916 + 27 385",     direct: 11, pad: 95),
    SPRung(label: "8 digits", digits: "long + long",         direct: 1,  pad: 92),
]

struct LengthLadderStudio: View {
    let cardId: String
    @ObservedObject var progress: FlowProgress

    @State private var level: Double = 0
    @State private var reachedTop = false

    private var idx: Int { min(spRungs.count - 1, max(0, Int(level.rounded()))) }
    private var rung: SPRung { spRungs[idx] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            Text("MAKE THE PROBLEM LONGER")
                .scaledFont(size: 11, weight: .bold).tracking(2.0)
                .foregroundStyle(tealAccent)
            Text("Here is the result that mattered. Drag the input length up the ladder. Answering in one shot falls apart as the numbers grow, but the scratchpad keeps climbing, because each step stays just as small.")
                .scaledFont(size: 16, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            ladder
            slider
            readout
            statusRow
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .motionAware(.snappy(duration: 0.3), value: idx)
    }

    private var ladder: some View {
        VStack(spacing: 6) {
            ForEach(Array(spRungs.enumerated().reversed()), id: \.offset) { i, r in
                HStack(spacing: 10) {
                    Text(r.label)
                        .scaledFont(size: 11, weight: i == idx ? .bold : .regular, design: .monospaced)
                        .foregroundStyle(i == idx ? inkColor : mutedText)
                        .frame(width: 64, alignment: .leading)
                    climber("one shot", at: r.direct, here: i == idx, tint: spRose)
                    climber("pad", at: r.pad, here: i == idx, tint: tealAccent)
                }
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(i == idx ? amberAccent.opacity(0.10) : Color.clear))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1)))
    }

    private func climber(_ name: String, at acc: Int, here: Bool, tint: Color) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.12)).frame(height: 10)
                Capsule().fill(tint.opacity(here ? 0.9 : 0.4))
                    .frame(width: max(8, g.size.width * CGFloat(acc) / 100), height: 10)
                if here {
                    Text("\(acc)%")
                        .scaledFont(size: 9, weight: .bold, design: .monospaced)
                        .foregroundStyle(tint)
                        .padding(.leading, max(8, g.size.width * CGFloat(acc) / 100) + 4)
                }
            }
        }
        .frame(height: 14)
    }

    private var slider: some View {
        Slider(value: $level, in: 0...Double(spRungs.count - 1), step: 1)
            .tint(tealAccent)
            .onChange(of: level) { _, _ in
                UISelectionFeedbackGenerator().selectionChanged()
                if idx == spRungs.count - 1, !reachedTop {
                    reachedTop = true
                    progress.markExplored(cardId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
    }

    private var readout: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(rung.digits)
                .scaledFont(size: 11, weight: .bold, design: .monospaced)
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(tealAccent.opacity(0.12)))
            Text("At \(rung.label.lowercased()), one shot scores \(rung.direct)% while the scratchpad holds \(rung.pad)%.")
                .scaledFont(size: 13, design: .serif)
                .foregroundStyle(inkColor.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1)))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle().fill(reachedTop ? tealAccent : amberAccent).frame(width: 9, height: 9)
            Text(reachedTop
                 ? "This is length generalisation: the scratchpad turns one giant problem into many tiny identical steps, so it barely cares how long the input gets."
                 : "Drag to the longest input to see the gap open.")
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
