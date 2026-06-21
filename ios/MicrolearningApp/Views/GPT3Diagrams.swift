import SwiftUI

// MARK: - Premium interactive diagrams for the GPT-3 daily loop
//
// Two bespoke cards that replace the generic flow-diagram + bar-chart slots
// for "Language Models are Few Shot Learners" (Brown et al., 2020).
//
//   Card 04, GPT3PromptShotsView
//      "Show, don't train." A stylised monospaced prompt panel reveals how the
//      same model produces different outputs as the user toggles between
//      0 / 1 / few-shot prompts. The model's output animates in token by token,
//      and an accuracy strip below shows the resulting score. Drives home the
//      core in-context-learning claim: weights never change, only the prompt.
//
//   Card 05, GPT3ScaleEmergenceView
//      "When does it click?" A drag-to-scrub dial moves the reader through
//      four model sizes (125M, 1.3B, 13B, 175B). Each stop swaps the prompt
//      output and the capability strip, surfacing the emergent jump that
//      defines the paper.
//
// Both views reuse the editorial token set already established for the daily
// loop (paperBg, dlAmberLight, tealAccent, inkColor, mutedText, dlPaper2,
// gptPromptEdge, etc.) so they sit inside the existing card chrome cleanly.

// MARK: - Local tokens

private let gptInk        = inkColor
private let gptInkSubtle  = inkColor.opacity(0.65)
private let gptCorrect    = Color(hex: "1f7a4d")
private let gptWrong      = Color(hex: "b6502a")
private let gptPromptBg   = Color(hex: "f4ece0")
private let gptPromptEdge = Color(hex: "e2d8c6")

// =============================================================================
// MARK: - Card 04, Prompt Shots
// =============================================================================

enum GPT3Shot: Int, CaseIterable, Identifiable {
    case zero, one, few
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .zero: return "0 shot"
        case .one:  return "1 shot"
        case .few:  return "Few shot"
        }
    }
    var caption: String {
        switch self {
        case .zero: return "Just the instruction. No demos."
        case .one:  return "One worked demo before the test."
        case .few:  return "A handful of demos. The pattern locks in."
        }
    }
}

private struct GPT3PromptLine: Identifiable, Hashable {
    let id = UUID()
    let prefix: String        // e.g. "sea →"
    let value: String         // e.g. "mer"
    let isQuery: Bool         // true if this is the test, not a worked example
}

private struct GPT3ShotScene {
    let instruction: String
    let lines: [GPT3PromptLine]
    let answer: String
    let accuracy: Double      // 0...1
    let verdict: String
    let verdictColor: Color
}

struct GPT3PromptShotsView: View {
    @ObservedObject var state: DailyLoopState
    @State private var shot: GPT3Shot = .zero
    @State private var typedAnswer: String = ""
    @State private var accuracyAnim: Double = 0
    @State private var visitedShots: Set<Int> = [GPT3Shot.zero.rawValue]

    private func scene(_ shot: GPT3Shot) -> GPT3ShotScene {
        switch shot {
        case .zero:
            return GPT3ShotScene(
                instruction: "Translate English to French.",
                lines: [GPT3PromptLine(prefix: "cat →", value: "?", isQuery: true)],
                answer: "le chat",
                accuracy: 0.50,
                verdict: "Half right. Got the language. Added an article it shouldn't have.",
                verdictColor: gptWrong
            )
        case .one:
            return GPT3ShotScene(
                instruction: "Translate English to French.",
                lines: [
                    GPT3PromptLine(prefix: "sea →", value: "mer", isQuery: false),
                    GPT3PromptLine(prefix: "cat →", value: "?", isQuery: true),
                ],
                answer: "chat",
                accuracy: 0.62,
                verdict: "One demo locked the format. Single-word answer this time.",
                verdictColor: gptCorrect
            )
        case .few:
            return GPT3ShotScene(
                instruction: "Translate English to French.",
                lines: [
                    GPT3PromptLine(prefix: "sea →",   value: "mer",     isQuery: false),
                    GPT3PromptLine(prefix: "house →", value: "maison",  isQuery: false),
                    GPT3PromptLine(prefix: "song →",  value: "chanson", isQuery: false),
                    GPT3PromptLine(prefix: "cat →",   value: "?",       isQuery: true),
                ],
                answer: "chat",
                accuracy: 0.78,
                verdict: "Pattern locked. The model uses the demos like a tiny program.",
                verdictColor: gptCorrect
            )
        }
    }

    var body: some View {
        let s = scene(shot)
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Eyebrow + title
                Text("CARD 04 · IN CONTEXT LEARNING")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Same model. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(gptInk)
                + Text("Different prompts.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("GPT-3's weights never change here. Toggle the demos and watch the answer get sharper.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                // Prompt panel
                promptPanel(scene: s)
                    .padding(.bottom, 14)

                // Shot toggle
                shotSegment
                    .padding(.bottom, 10)

                Text(shot.caption)
                    .font(scaledSystemFont(11, design: .serif))
                    .italic()
                    .foregroundStyle(mutedText)
                    .padding(.bottom, 18)

                // Accuracy strip
                accuracyStrip(target: s.accuracy)
                    .padding(.bottom, 10)

                Text(s.verdict)
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(s.verdictColor)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            animateAnswer(scene(shot))
            visitedShots.insert(shot.rawValue)
            updateGate()
        }
        .onChange(of: shot) { _, newShot in
            animateAnswer(scene(newShot))
            visitedShots.insert(newShot.rawValue)
            updateGate()
        }
    }

    private func updateGate() {
        if visitedShots.count >= GPT3Shot.allCases.count {
            state.customCardComplete.insert(3)
        }
    }

    // Prompt panel, monospaced, with the answer line typing in.
    private func promptPanel(scene s: GPT3ShotScene) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(gptWrong.opacity(0.65)).frame(width: 7, height: 7)
                Circle().fill(Color(hex: "d4b04c")).frame(width: 7, height: 7)
                Circle().fill(gptCorrect.opacity(0.65)).frame(width: 7, height: 7)
                Spacer()
                Text("PROMPT")
                    .font(scaledSystemFont(8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(gptInkSubtle)
            }
            .padding(.bottom, 4)

            Text(s.instruction)
                .font(scaledSystemFont(12, design: .monospaced))
                .foregroundStyle(gptInk)
                .padding(.bottom, 4)

            ForEach(s.lines) { line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(line.prefix)
                        .font(scaledSystemFont(12, design: .monospaced))
                        .foregroundStyle(line.isQuery ? gptInk : gptInkSubtle)
                    if line.isQuery {
                        Text(typedAnswer.isEmpty ? "▍" : typedAnswer)
                            .font(scaledSystemFont(12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(tealAccent)
                            .motionAware(.linear(duration: 0.05), value: typedAnswer)
                    } else {
                        Text(line.value)
                            .font(scaledSystemFont(12, design: .monospaced))
                            .foregroundStyle(gptInkSubtle)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(gptPromptBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(gptPromptEdge, lineWidth: 1)
                )
        )
    }

    private var shotSegment: some View {
        HStack(spacing: 6) {
            ForEach(GPT3Shot.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        shot = s
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Text(s.label)
                        .font(scaledSystemFont(12, weight: shot == s ? .semibold : .regular))
                        .foregroundStyle(shot == s ? .white : gptInk.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(shot == s ? tealAccent : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(gptPromptEdge, lineWidth: shot == s ? 0 : 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func accuracyStrip(target: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ACCURACY")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("\(Int(round(target * 100)))%")
                    .font(scaledSystemFont(14, weight: .regular, design: .serif))
                    .foregroundStyle(gptInk)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tealAccent.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.7), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * accuracyAnim)
                }
            }
            .frame(height: 6)
        }
        .onChange(of: target) { _, newTarget in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                accuracyAnim = newTarget
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.1)) {
                accuracyAnim = target
            }
        }
    }

    private func animateAnswer(_ s: GPT3ShotScene) {
        typedAnswer = ""
        let target = s.answer
        let chars = Array(target)
        for (i, c) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45 + Double(i) * 0.06) {
                guard shot == .zero || shot == .one || shot == .few else { return }
                if scene(shot).answer == target {
                    typedAnswer.append(c)
                }
            }
        }
    }
}

// =============================================================================
// MARK: - Card 05, Scale Emergence
// =============================================================================

enum GPT3Scale: Int, CaseIterable, Identifiable {
    case s125M, s1B, s13B, s175B
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .s125M: return "125M"
        case .s1B:   return "1.3B"
        case .s13B:  return "13B"
        case .s175B: return "175B"
        }
    }
    var sublabel: String {
        switch self {
        case .s125M: return "tiny"
        case .s1B:   return "small"
        case .s13B:  return "medium"
        case .s175B: return "GPT-3"
        }
    }
    var modelOutput: String {
        switch self {
        case .s125M: return "le le cat le"
        case .s1B:   return "perro"
        case .s13B:  return "chat"
        case .s175B: return "chat"
        }
    }
    var verdict: String {
        switch self {
        case .s125M: return "Garbled. Doesn't recognise the task."
        case .s1B:   return "Wrong language. Picked up 'translate', not which translate."
        case .s13B:  return "Correct. The trick clicks."
        case .s175B: return "Correct. And it nails harder cases too."
        }
    }
    var verdictColor: Color {
        switch self {
        case .s125M, .s1B: return gptWrong
        case .s13B, .s175B: return gptCorrect
        }
    }
    var capability: Double {
        switch self {
        case .s125M: return 0.09
        case .s1B:   return 0.23
        case .s13B:  return 0.41
        case .s175B: return 0.65
        }
    }
}

struct GPT3ScaleEmergenceView: View {
    @ObservedObject var state: DailyLoopState
    @State private var scale: GPT3Scale = .s125M
    @State private var capabilityAnim: Double = 0.09
    @State private var dragOffset: CGFloat = 0
    @State private var visitedScales: Set<Int> = [GPT3Scale.s125M.rawValue]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("CARD 05 · EMERGENCE")
                    .font(scaledSystemFont(9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                    .padding(.bottom, 8)

                Text("Same trick. ").font(scaledSystemFont(24, weight: .regular, design: .serif)).foregroundStyle(gptInk)
                + Text("Different sizes.").font(scaledSystemFont(24, weight: .regular, design: .serif)).italic().foregroundStyle(tealAccent)

                Text("Drag the dial. Same prompt at every stop. The capability appears, it doesn't gradually grow.")
                    .font(scaledSystemFont(12, design: .serif))
                    .foregroundStyle(mutedText)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                // Scale dial
                scaleDial
                    .padding(.bottom, 22)

                // Output card
                outputCard
                    .padding(.bottom, 18)

                // Capability strip
                capabilityStrip
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear {
            capabilityAnim = scale.capability
            visitedScales.insert(scale.rawValue)
            updateGate()
        }
        .onChange(of: scale) { _, newScale in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                capabilityAnim = newScale.capability
            }
            visitedScales.insert(newScale.rawValue)
            updateGate()
        }
    }

    private func updateGate() {
        if visitedScales.count >= GPT3Scale.allCases.count {
            state.customCardComplete.insert(4)
        }
    }

    // Dial: a horizontal log-scale rail with 4 stops. Drag the puck to scrub.
    private var scaleDial: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let stops = GPT3Scale.allCases
                let usableWidth = geo.size.width - 28
                let stopX: (GPT3Scale) -> CGFloat = { s in
                    14 + usableWidth * CGFloat(s.rawValue) / CGFloat(stops.count - 1)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(gptPromptBg)
                        .frame(height: 6)
                        .overlay(Capsule().stroke(gptPromptEdge, lineWidth: 1))

                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.4), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: stopX(scale), height: 6)

                    ForEach(stops) { s in
                        Circle()
                            .fill(scale.rawValue >= s.rawValue ? tealAccent : Color.white)
                            .overlay(Circle().stroke(scale == s ? tealAccent : gptPromptEdge, lineWidth: scale == s ? 2 : 1))
                            .frame(width: scale == s ? 16 : 10, height: scale == s ? 16 : 10)
                            .offset(x: stopX(s) - (scale == s ? 8 : 5), y: 0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { scale = s }
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                    }
                }
                .frame(height: 22)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let frac = max(0, min(1, (v.location.x - 14) / max(1, usableWidth)))
                            let idx = Int(round(frac * CGFloat(stops.count - 1)))
                            let snapped = stops[min(stops.count - 1, max(0, idx))]
                            if snapped != scale {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                    scale = snapped
                                }
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                        }
                )
            }
            .frame(height: 22)

            HStack {
                ForEach(GPT3Scale.allCases) { s in
                    VStack(spacing: 2) {
                        Text(s.label)
                            .font(scaledSystemFont(11, weight: scale == s ? .semibold : .regular, design: .serif))
                            .foregroundStyle(scale == s ? gptInk : mutedText)
                        Text(s.sublabel)
                            .font(scaledSystemFont(8, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(scale == s ? tealAccent : mutedText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PROMPT")
                    .font(scaledSystemFont(8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(gptInkSubtle)
                Spacer()
                Text("MODEL · \(scale.label)")
                    .font(scaledSystemFont(8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
            }

            Text("Translate English to French.")
                .font(scaledSystemFont(12, design: .monospaced))
                .foregroundStyle(gptInkSubtle)
            Text("sea → mer")
                .font(scaledSystemFont(12, design: .monospaced))
                .foregroundStyle(gptInkSubtle)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("cat →")
                    .font(scaledSystemFont(12, design: .monospaced))
                    .foregroundStyle(gptInk)
                Text(scale.modelOutput)
                    .font(scaledSystemFont(12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(scale.verdictColor)
                    .id(scale)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                Spacer()
            }

            Divider().background(gptPromptEdge.opacity(0.6))

            Text(scale.verdict)
                .font(scaledSystemFont(12, design: .serif))
                .italic()
                .foregroundStyle(scale.verdictColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(gptPromptBg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(gptPromptEdge, lineWidth: 1))
        )
    }

    private var capabilityStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("FEW SHOT ACCURACY")
                    .font(scaledSystemFont(9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent.opacity(0.85))
                Spacer()
                Text("\(Int(round(capabilityAnim * 100)))%")
                    .font(scaledSystemFont(14, weight: .regular, design: .serif))
                    .foregroundStyle(gptInk)
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tealAccent.opacity(0.12))
                    // Threshold tick at the emergence bend
                    Rectangle()
                        .fill(gptInk.opacity(0.18))
                        .frame(width: 1)
                        .offset(x: geo.size.width * 0.55)
                    Capsule()
                        .fill(LinearGradient(colors: [tealAccent.opacity(0.55), tealAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * capabilityAnim)
                }
            }
            .frame(height: 6)

            Text("The faint tick marks where in-context learning starts paying off. Below it: a parlour trick. Above: a tool.")
                .font(scaledSystemFont(11, design: .serif))
                .italic()
                .foregroundStyle(mutedText)
                .padding(.top, 6)
        }
    }
}
