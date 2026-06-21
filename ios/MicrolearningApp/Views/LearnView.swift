import SwiftUI

// MARK: - LearnView
//
// The Learn tab. A vertical bottom-up climb through AI research.
//
// On open, the view briefly scrolls from the highest peak down to the
// start so the reader sees the full journey before landing on
// "Perceptron · Start here."
//
// Every node is a tappable capsule sitting ON the rail (not beside it).
// Free readers progress one paper at a time. Plus members can jump
// directly to any node.
//
// Tap behaviour matches the rest of the app: foundation papers route to
// their bespoke LearningLessonView; everything else routes through the
// shared DeckDestination so the moment backend ingests a branch paper,
// the node lights up automatically.

struct LearnView: View {

    @EnvironmentObject private var store: StoreService
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    @State private var navigationPaperId: String? = nil
    @State private var showPaywall: Bool = false
    @State private var paywallContext: String = "Skip ahead with Aprecis Plus"
    @State private var showRequestSheet: Bool = false

    private static let topAnchor    = "roadmap-top"
    private static let startAnchor  = "roadmap-start"

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        pageHeader
                            .padding(.bottom, 18)
                            .id(Self.topAnchor)

                        RoadmapMap(
                            isPlus: store.isPlus,
                            onTap: handleNodeTap
                        )

                        startMarker
                            .id(Self.startAnchor)
                            .padding(.top, 8)
                            .padding(.bottom, 28)

                        suggestPathLink
                            .padding(.bottom, 56)
                    }
                    .padding(.top, 14)
                }
                .onAppear { performIntroScroll(proxy: proxy) }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $navigationPaperId) { paperId in
            if let deck = deckForPaperId(paperId) {
                DeckDestination(deck: deck)
            } else {
                ComingSoonPaperView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(contextLine: paywallContext)
                .environmentObject(store)
        }
        .sheet(isPresented: $showRequestSheet) {
            RequestPathSheet()
        }
    }

    // MARK: header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APRECIS · LEARN")
                .scaledFont(size: 10, weight: .bold)
                .tracking(2.2)
                .foregroundStyle(tealAccent)

            Text("Climb the map.")
                .scaledFont(size: 32, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)

            Text("Eleven papers, sixty-two years. Begin at Perceptron, climb to the Transformer, then branch into the field that pulls you.")
                .scaledFont(size: 13, design: .serif)
                .italic()
                .foregroundStyle(mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
    }

    // MARK: start marker

    private var startMarker: some View {
        VStack(spacing: 10) {
            // Three concentric rings, brand mark style.
            ZStack {
                Circle().stroke(tealAccent.opacity(0.12), lineWidth: 1).frame(width: 64, height: 64)
                Circle().stroke(tealAccent.opacity(0.22), lineWidth: 1).frame(width: 44, height: 44)
                Circle().fill(tealAccent).frame(width: 16, height: 16)
            }

            VStack(spacing: 3) {
                Text("START HERE")
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(2.4)
                    .foregroundStyle(tealAccent)
                Text("Perceptron, 1958")
                    .scaledFont(size: 12, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: suggest

    private var suggestPathLink: some View {
        Button {
            showRequestSheet = true
        } label: {
            HStack(spacing: 6) {
                Text("Suggest the next path")
                Image(systemName: "arrow.right")
                    .scaledFont(size: 11, weight: .bold)
            }
            .scaledFont(size: 12, weight: .semibold, design: .serif)
            .italic()
            .foregroundStyle(mutedText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: routing

    private func handleNodeTap(_ node: Roadmap.Node, state: RoadmapNodeState) {
        switch state {
        case .completed, .current, .unlocked:
            navigationPaperId = node.id
        case .lockedAhead:
            paywallContext = "Skip ahead with Aprecis Plus"
            showPaywall = true
        case .comingSoon:
            paywallContext = "This paper is being prepared"
            showPaywall = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deckForPaperId(_ paperId: String) -> CardDeck? {
        guard let node = Roadmap.node(withID: paperId),
              let pid = bundlePaperId(slug: node.slug),
              let content = DailyLoopContent.byPaperId(pid)
        else { return nil }
        return CardDeck.fromLoop(paperId: pid, content: content)
    }

    // MARK: scroll choreography

    /// On first appearance, briefly show the highest peak of the map,
    /// then animate down to the start marker. Gives the reader a one-shot
    /// preview of the journey before settling them where they begin.
    private func performIntroScroll(proxy: ScrollViewProxy) {
        // Jump to the very top with no animation (above-the-fold preview).
        DispatchQueue.main.async {
            proxy.scrollTo(Self.topAnchor, anchor: .top)
        }
        // Then unspool down to the start, slowly enough that the reader
        // can scan the whole climb on the way.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeInOut(duration: 1.6)) {
                proxy.scrollTo(Self.startAnchor, anchor: .bottom)
            }
        }
    }
}

// MARK: - RoadmapMap
//
// The map itself. Renders branches at the top (side by side), a junction
// fanning down into the trunk, then the trunk descending to the start.
// All nodes are centered on a single vertical rail per column.

private struct RoadmapMap: View {
    let isPlus: Bool
    var onTap: (Roadmap.Node, RoadmapNodeState) -> Void

    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var trunkComplete: Bool {
        RoadmapAccess.isTrunkComplete(store: progressStore)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top: three branches side-by-side, each its own short column.
            HStack(alignment: .top, spacing: 14) {
                ForEach(Roadmap.branches) { branch in
                    BranchColumn(
                        branch: branch,
                        isPlus: isPlus,
                        onTap: onTap
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            // Junction: fans the three branch tracks down into one trunk.
            JunctionFan(
                accent: Roadmap.trunkBranch.accent,
                unlocked: isPlus || trunkComplete
            )
            .frame(height: 56)
            .padding(.horizontal, 28)

            // Trunk: capsules stacked vertically, line passing through.
            // Reversed so reading-direction-start (Perceptron) is at the
            // visual bottom of the canvas.
            VStack(spacing: 0) {
                let reversed = Array(Roadmap.trunk.enumerated().reversed())
                ForEach(reversed, id: \.element.id) { idx, node in
                    let state = RoadmapAccess.state(
                        of: node,
                        in: Roadmap.trunkBranch,
                        isPlus: isPlus,
                        progressStore: progressStore
                    )
                    SpineNodeRow(
                        node: node,
                        state: state,
                        accent: Roadmap.trunkBranch.accent,
                        isFirstInColumn: idx == reversed.first?.0,
                        isLastInColumn: idx == 0,
                        onTap: { onTap(node, state) }
                    )
                }
            }
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - BranchColumn

private struct BranchColumn: View {
    let branch: Roadmap.Branch
    let isPlus: Bool
    var onTap: (Roadmap.Node, RoadmapNodeState) -> Void

    @ObservedObject private var progressStore = ReadingProgressStore.shared

    var body: some View {
        VStack(spacing: 8) {
            // Header
            VStack(spacing: 3) {
                Text(branch.title.uppercased())
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(1.8)
                    .foregroundStyle(branch.accent)
                Text(branch.blurb)
                    .scaledFont(size: 9, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            // Nodes top-to-bottom in canvas order (top of branch = top of
            // column). Last node visually sits at branch base, ready to
            // hand off to the junction below.
            VStack(spacing: 0) {
                let reversed = Array(branch.nodes.enumerated().reversed())
                ForEach(reversed, id: \.element.id) { idx, node in
                    let state = RoadmapAccess.state(
                        of: node,
                        in: branch,
                        isPlus: isPlus,
                        progressStore: progressStore
                    )
                    BranchNodeRow(
                        node: node,
                        state: state,
                        accent: branch.accent,
                        isFirstInColumn: idx == reversed.first?.0,
                        isLastInColumn: idx == 0,
                        onTap: { onTap(node, state) }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SpineNodeRow (trunk node)
//
// Wide capsule centered on the rail. Cream paper, accent border,
// year-on-left + title + state badge. Connector lines above and below
// touch the capsule edges so the rail visually passes through it.

private struct SpineNodeRow: View {
    let node: Roadmap.Node
    let state: RoadmapNodeState
    let accent: Color
    let isFirstInColumn: Bool
    let isLastInColumn: Bool
    var onTap: () -> Void

    @State private var pressed = false
    @State private var pulse   = false

    var body: some View {
        VStack(spacing: 0) {
            // Upper connector. Hidden on the very top of the column so
            // the rail caps cleanly at the highest paper.
            connector(visible: !isFirstInColumn)

            capsule
                .scaleEffect(pressed ? 0.97 : 1.0)
                .motionAware(.spring(response: 0.28, dampingFraction: 0.7), value: pressed)
                .onTapGesture {
                    pressed = true
                    onTap()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { pressed = false }
                }

            // Lower connector. Hidden at the bottom of the column.
            connector(visible: !isLastInColumn)
        }
        .onAppear { if state == .current { pulse = true } }
    }

    private func connector(visible: Bool) -> some View {
        Rectangle()
            .fill(railColor)
            .frame(width: 2, height: visible ? 22 : 0)
            .opacity(visible ? 1 : 0)
    }

    private var railColor: Color {
        switch state {
        case .completed, .current, .unlocked: return accent.opacity(0.55)
        default: return mutedText.opacity(0.28)
        }
    }

    @ViewBuilder
    private var capsule: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fillColor)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(strokeColor, lineWidth: strokeWidth)

            // Soft accent halo for the current node
            if state == .current {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 8)
                    .blur(radius: 4)
                    .scaleEffect(pulse ? 1.04 : 1.0)
                    .opacity(pulse ? 0.4 : 0.75)
                    .motionAware(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
            }

            HStack(spacing: 14) {
                stateIcon
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(node.title)
                            .scaledFont(size: 17, weight: .semibold, design: .serif)
                            .foregroundStyle(titleColor)
                            .lineLimit(1)
                        Text("\(verbatimYear)")
                            .scaledFont(size: 11, weight: .medium, design: .monospaced)
                            .foregroundStyle(mutedText)
                    }
                    Text(node.oneLiner)
                        .scaledFont(size: 11, design: .serif)
                        .italic()
                        .foregroundStyle(subtitleColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                stateBadge
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(minHeight: 76)
        .shadow(color: shadowColor, radius: 8, x: 0, y: 3)
    }

    private var verbatimYear: String { String(node.year) }

    private var fillColor: Color {
        switch state {
        case .completed:   return accent
        case .current:     return cardBg
        case .unlocked:    return cardBg
        case .lockedAhead: return cardBg
        case .comingSoon:  return cardBg
        }
    }

    private var strokeColor: Color {
        switch state {
        case .completed:   return accent
        case .current:     return accent
        case .unlocked:    return accent.opacity(0.55)
        case .lockedAhead: return mutedText.opacity(0.35)
        case .comingSoon:  return mutedText.opacity(0.3)
        }
    }

    private var strokeWidth: CGFloat {
        switch state {
        case .current: return 2
        default:       return 1
        }
    }

    private var titleColor: Color {
        switch state {
        case .completed: return paperBg
        case .lockedAhead, .comingSoon: return mutedText
        default: return inkColor
        }
    }

    private var subtitleColor: Color {
        switch state {
        case .completed: return paperBg.opacity(0.85)
        case .lockedAhead, .comingSoon: return mutedText.opacity(0.7)
        default: return mutedText
        }
    }

    private var shadowColor: Color {
        state == .current ? accent.opacity(0.12) : inkColor.opacity(0.05)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .completed:
            ZStack {
                Circle().fill(paperBg)
                Image(systemName: "checkmark")
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundStyle(accent)
            }
        case .current:
            ZStack {
                Circle().fill(accent.opacity(0.18))
                Circle().fill(accent).frame(width: 10, height: 10)
            }
        case .unlocked:
            ZStack {
                Circle().fill(accent.opacity(0.12))
                Image(systemName: "arrow.up.right")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(accent)
            }
        case .lockedAhead:
            ZStack {
                Circle().fill(mutedText.opacity(0.10))
                Image(systemName: "lock.fill")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(mutedText)
            }
        case .comingSoon:
            ZStack {
                Circle().fill(mutedText.opacity(0.10))
                Image(systemName: "hourglass")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(mutedText)
            }
        }
    }

    @ViewBuilder
    private var stateBadge: some View {
        let (label, color, bg) = badgeStyle
        Text(label)
            .scaledFont(size: 9, weight: .bold)
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(bg))
    }

    private var badgeStyle: (String, Color, Color) {
        switch state {
        case .completed:   return ("READ",         paperBg,    paperBg.opacity(0.15))
        case .current:     return ("READ NEXT",    accent,     accent.opacity(0.12))
        case .unlocked:    return ("OPEN",         accent,     accent.opacity(0.10))
        case .lockedAhead: return ("PLUS",         mutedText,  mutedText.opacity(0.10))
        case .comingSoon:  return ("SOON",         mutedText,  mutedText.opacity(0.10))
        }
    }
}

// MARK: - BranchNodeRow (compact variant for the three branch columns)

private struct BranchNodeRow: View {
    let node: Roadmap.Node
    let state: RoadmapNodeState
    let accent: Color
    let isFirstInColumn: Bool
    let isLastInColumn: Bool
    var onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        VStack(spacing: 0) {
            connector(visible: !isFirstInColumn)
            capsule
                .scaleEffect(pressed ? 0.97 : 1.0)
                .motionAware(.spring(response: 0.28, dampingFraction: 0.7), value: pressed)
                .onTapGesture {
                    pressed = true
                    onTap()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { pressed = false }
                }
            connector(visible: !isLastInColumn)
        }
    }

    private func connector(visible: Bool) -> some View {
        Rectangle()
            .fill(railColor)
            .frame(width: 1.6, height: visible ? 16 : 0)
            .opacity(visible ? 1 : 0)
    }

    private var railColor: Color {
        switch state {
        case .completed, .current, .unlocked: return accent.opacity(0.5)
        default: return mutedText.opacity(0.25)
        }
    }

    @ViewBuilder
    private var capsule: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fillColor)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    miniIcon
                    Text(node.title)
                        .scaledFont(size: 11, weight: .semibold, design: .serif)
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                }
                Text("\(node.year)")
                    .scaledFont(size: 8, weight: .medium, design: .monospaced)
                    .foregroundStyle(mutedText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(minHeight: 48)
        .frame(maxWidth: .infinity)
        .shadow(color: inkColor.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var fillColor: Color {
        state == .completed ? accent : cardBg
    }

    private var strokeColor: Color {
        switch state {
        case .completed:   return accent
        case .current:     return accent
        case .unlocked:    return accent.opacity(0.55)
        default:           return mutedText.opacity(0.3)
        }
    }

    private var titleColor: Color {
        switch state {
        case .completed: return paperBg
        case .lockedAhead, .comingSoon: return mutedText
        default: return inkColor
        }
    }

    @ViewBuilder
    private var miniIcon: some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark")
                .scaledFont(size: 8, weight: .bold)
                .foregroundStyle(paperBg)
        case .current:
            Circle().fill(accent).frame(width: 6, height: 6)
        case .unlocked:
            Image(systemName: "arrow.up.right")
                .scaledFont(size: 8, weight: .bold)
                .foregroundStyle(accent)
        case .lockedAhead:
            Image(systemName: "lock.fill")
                .scaledFont(size: 8, weight: .bold)
                .foregroundStyle(mutedText)
        case .comingSoon:
            Image(systemName: "hourglass")
                .scaledFont(size: 8, weight: .bold)
                .foregroundStyle(mutedText)
        }
    }
}

// MARK: - JunctionFan

private struct JunctionFan: View {
    let accent: Color
    let unlocked: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let center = w / 2
            let left   = w * 0.18
            let right  = w * 0.82

            Path { p in
                p.move(to: CGPoint(x: center, y: h))
                p.addCurve(to: CGPoint(x: left, y: 0),
                           control1: CGPoint(x: center, y: h * 0.42),
                           control2: CGPoint(x: left,   y: h * 0.55))

                p.move(to: CGPoint(x: center, y: h))
                p.addLine(to: CGPoint(x: center, y: 0))

                p.move(to: CGPoint(x: center, y: h))
                p.addCurve(to: CGPoint(x: right, y: 0),
                           control1: CGPoint(x: center, y: h * 0.42),
                           control2: CGPoint(x: right,  y: h * 0.55))
            }
            .stroke(
                unlocked ? accent.opacity(0.55) : mutedText.opacity(0.25),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
            )
        }
    }
}

// MARK: - ComingSoonPaperView

private struct ComingSoonPaperView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass")
                .scaledFont(size: 28, weight: .light)
                .foregroundStyle(mutedText)
            Text("This paper is being prepared.")
                .scaledFont(size: 18, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)
            Text("Check back soon, or tell us which path to build next from the Learn tab.")
                .scaledFont(size: 13, design: .serif)
                .italic()
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(paperBg.ignoresSafeArea())
    }
}

// MARK: - RequestPathSheet

private struct RequestPathSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @AppStorage("learn.requestSent.v1") private var sent: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                paperBg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    Text("APRECIS · LEARN")
                        .scaledFont(size: 10, weight: .bold)
                        .tracking(2.0)
                        .foregroundStyle(tealAccent)

                    Text("Suggest the next path.")
                        .scaledFont(size: 26, weight: .regular, design: .serif)
                        .foregroundStyle(inkColor)

                    Text("Tell us the topic you want to climb. We use this to decide which path to build next.")
                        .scaledFont(size: 13, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    if sent {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(tealAccent)
                            Text("Thanks. We've noted it.")
                                .scaledFont(size: 14, design: .serif)
                                .italic()
                                .foregroundStyle(mutedText)
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            TextField("e.g. agents, robotics, alignment…", text: $text)
                                .scaledFont(size: 14, design: .serif)
                                .foregroundStyle(inkColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(cardBg)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(borderColor, lineWidth: 1)
                                )

                            Button(action: submit) {
                                HStack(spacing: 6) {
                                    Text("Send")
                                    Image(systemName: "arrow.right")
                                }
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundStyle(paperBg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(canSubmit ? inkColor : mutedText.opacity(0.4))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!canSubmit)
                        }
                        .padding(.top, 8)
                    }

                    Spacer()
                }
                .padding(28)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(tealAccent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() {
        UserDefaults.standard.set(text.trimmingCharacters(in: .whitespaces), forKey: "learn.requestText.v1")
        sent = true
        text = ""
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

#Preview {
    NavigationStack {
        LearnView()
            .environmentObject(StoreService())
    }
}
