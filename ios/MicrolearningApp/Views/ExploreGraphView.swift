import SwiftUI

// MARK: - GraphCanvas (subway map)
//
// Editorial transit map of curated AI papers. Each horizontal line is a
// single intellectual lineage (Foundations, Language, Generative,
// Critique); stations are papers in reading order; thin curved arcs
// between lines show where one tradition reaches into another.
//
// Calm by design: layout is static, never reflows, never overlaps.
// Tapping a station opens a compact focus sheet with the paper's hook,
// adjacent stops, and a button to open the deck.

struct GraphCanvas: View {
    let decks: [CardDeck]
    var query: String = ""
    @Binding var focusedId: String?
    var initialSeed: String? = nil
    var onDismiss: (() -> Void)? = nil

    @State private var pendingNavId: String? = nil

    // Layout constants. Tuned for a 14-paper map on an iPhone canvas.
    private let stationDiameter: CGFloat = 14
    private let lineThickness:   CGFloat = 5
    private let lineLabelWidth:  CGFloat = 96
    private let lineGap:         CGFloat = 90
    private let slotGap:         CGFloat = 92
    private let topPadding:      CGFloat = 36
    private let bottomReserve:   CGFloat = 220

    private var deckById: [String: CardDeck] {
        Dictionary(uniqueKeysWithValues: decks.map { ($0.paperId, $0) })
    }

    private var highlightedIds: Set<String> {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return Set(SubwayMap.allStations().filter { st in
            blob(for: st.id).lowercased().contains(q) ||
            st.label.lowercased().contains(q)
        }.map(\.id))
    }

    private var connectedIds: Set<String> {
        guard let id = focusedId else { return [] }
        return Set([id] + SubwayMap.neighbors(of: id))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                paperBg
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    mapBoard
                        .padding(.leading, 16)
                        .padding(.trailing, 24)
                        .padding(.top, topPadding)
                        .padding(.bottom, bottomReserve)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onAppear {
                    if focusedId == nil, let seed = initialSeed {
                        focusedId = seed
                    }
                }
            }
            .overlay(alignment: .topLeading) { topChrome.padding(14) }
            .overlay(alignment: .bottom) {
                if let id = focusedId {
                    focusSheet(id: id)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    legend
                        .padding(.horizontal, 14)
                        .padding(.bottom, 16)
                }
            }
            .motionAware(.snappy(duration: 0.20), value: focusedId)
            .navigationDestination(item: $pendingNavId) { id in
                if let deck = deckById[id] {
                    DeckDestination(deck: deck)
                } else if let loop = DailyLoopContent.byPaperId(id) {
                    DeckDestination(deck: CardDeck.fromLoop(paperId: id, content: loop))
                }
            }
        }
    }

    // MARK: layout math

    private func y(forLine index: Int) -> CGFloat {
        CGFloat(index) * lineGap + lineGap / 2
    }

    private func x(forSlot slot: Int) -> CGFloat {
        lineLabelWidth + CGFloat(slot) * slotGap + slotGap / 2
    }

    private var boardWidth: CGFloat {
        lineLabelWidth + CGFloat(SubwayMap.maxSlot + 1) * slotGap + 24
    }

    private var boardHeight: CGFloat {
        CGFloat(SubwayMap.lines.count) * lineGap
    }

    // MARK: board

    private var mapBoard: some View {
        ZStack(alignment: .topLeading) {
            transfersLayer
            linesLayer
            stationsLayer
        }
        .frame(width: boardWidth, height: boardHeight)
    }

    // Train-line rails: a single rounded rectangle per line stretching
    // across all its stations. The rail color is the line color; opacity
    // softens when something is focused / filtered.
    private var linesLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(SubwayMap.lines.enumerated()), id: \.element.id) { idx, line in
                lineRail(line: line, index: idx)
            }
        }
    }

    private func lineRail(line: SubwayMap.Line, index: Int) -> some View {
        let yPos = y(forLine: index)
        let stations = line.stations
        guard let firstSlot = stations.map(\.slot).min(),
              let lastSlot  = stations.map(\.slot).max(),
              firstSlot <= lastSlot else {
            return AnyView(EmptyView())
        }
        let x0 = x(forSlot: firstSlot)
        let x1 = x(forSlot: lastSlot)
        let dim = lineDimmed(line: line)
        return AnyView(
            ZStack(alignment: .leading) {
                // Line label, anchored to the very left of the board.
                HStack(spacing: 6) {
                    Circle().fill(line.color).frame(width: 6, height: 6)
                    Text(line.label)
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.4)
                        .foregroundStyle(line.color)
                        .lineLimit(1)
                }
                .position(x: lineLabelWidth / 2, y: yPos)
                .opacity(dim ? 0.30 : 1.0)

                // The rail itself.
                Capsule()
                    .fill(line.color.opacity(dim ? 0.25 : 0.55))
                    .frame(width: x1 - x0, height: lineThickness)
                    .position(x: (x0 + x1) / 2, y: yPos)
            }
        )
    }

    // Transfer arcs. Each is a quadratic curve from station A to
    // station B, drawn in the destination line's color so the eye can
    // follow influence into a subfield.
    private var transfersLayer: some View {
        Canvas { ctx, _ in
            for t in SubwayMap.transfers {
                guard let p0 = position(of: t.from),
                      let p1 = position(of: t.to) else { continue }
                let toColor = SubwayMap.line(of: t.to)?.color ?? tealAccent
                let active = transferActive(from: t.from, to: t.to)
                let alpha: Double = active ? 0.85 : 0.25
                let width: CGFloat = active ? 1.6 : 1.0
                let dy = p1.y - p0.y
                let mid = CGPoint(x: (p0.x + p1.x) / 2,
                                  y: (p0.y + p1.y) / 2 + (abs(dy) > 1 ? 0 : -22))
                var path = Path()
                path.move(to: p0)
                path.addQuadCurve(to: p1, control: mid)
                ctx.stroke(
                    path,
                    with: .color(toColor.opacity(alpha)),
                    style: StrokeStyle(lineWidth: width, lineCap: .round,
                                       dash: active ? [] : [3, 3])
                )
            }
        }
        .frame(width: boardWidth, height: boardHeight)
        .allowsHitTesting(false)
    }

    private func position(of stationId: String) -> CGPoint? {
        for (idx, line) in SubwayMap.lines.enumerated() {
            if let st = line.stations.first(where: { $0.id == stationId }) {
                return CGPoint(x: x(forSlot: st.slot), y: y(forLine: idx))
            }
        }
        return nil
    }

    private var stationsLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(SubwayMap.lines.enumerated()), id: \.element.id) { idx, line in
                ForEach(line.stations) { st in
                    stationView(station: st, line: line, lineIndex: idx)
                        .position(x: x(forSlot: st.slot), y: y(forLine: idx))
                }
            }
        }
    }

    @ViewBuilder
    private func stationView(station: SubwayMap.Station,
                             line: SubwayMap.Line,
                             lineIndex: Int) -> some View {
        let isFocused = (focusedId == station.id)
        let dim       = stationDimmed(id: station.id)
        let progress  = ReadingProgressStore.shared.progress(for: station.id)
        let isHit     = highlightedIds.contains(station.id) && !highlightedIds.isEmpty

        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.snappy(duration: 0.20)) {
                focusedId = (focusedId == station.id) ? nil : station.id
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Outer hit ring (large but transparent for easy taps)
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 38, height: 38)
                    // Glow when this station matches a filter.
                    if isHit || isFocused {
                        Circle()
                            .fill(line.color.opacity(0.30))
                            .frame(width: 24, height: 24)
                            .blur(radius: 6)
                    }
                    // The station dot itself.
                    Circle()
                        .fill(Color.white)
                        .frame(width: stationDiameter, height: stationDiameter)
                    Circle()
                        .stroke(line.color, lineWidth: isFocused ? 4 : 2.5)
                        .frame(width: stationDiameter, height: stationDiameter)
                    if progress >= 0.98 {
                        Image(systemName: "checkmark")
                            .scaledFont(size: 7, weight: .heavy)
                            .foregroundStyle(progressGreen)
                    } else if progress > 0.04 {
                        Circle()
                            .fill(amberAccent)
                            .frame(width: 5, height: 5)
                    }
                }
                Text(station.label)
                    .scaledFont(size: 10, weight: isFocused ? .semibold : .regular, design: .serif)
                    .foregroundStyle(isFocused ? inkColor : inkColor.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 86)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(dim ? 0.28 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func lineDimmed(line: SubwayMap.Line) -> Bool {
        if focusedId == nil && highlightedIds.isEmpty { return false }
        return !line.stations.contains { connectedIds.contains($0.id) || highlightedIds.contains($0.id) }
    }

    private func stationDimmed(id: String) -> Bool {
        if focusedId != nil { return !connectedIds.contains(id) }
        if !highlightedIds.isEmpty { return !highlightedIds.contains(id) }
        return false
    }

    private func transferActive(from: String, to: String) -> Bool {
        if focusedId != nil {
            return connectedIds.contains(from) && connectedIds.contains(to)
        }
        if !highlightedIds.isEmpty {
            return highlightedIds.contains(from) || highlightedIds.contains(to)
        }
        return false
    }

    // MARK: focus sheet

    private func focusSheet(id: String) -> some View {
        let line = SubwayMap.line(of: id)
        let station = SubwayMap.station(id)
        let title = nodeTitle(for: id)
        let deck = deckById[id]
        let loop = deck == nil ? DailyLoopContent.byPaperId(id) : nil
        let hook = deck?.hook ?? loop?.hookBody
        let neighbors = SubwayMap.neighbors(of: id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let line {
                    Circle().fill(line.color).frame(width: 5, height: 5)
                    Text(line.label)
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.4)
                        .foregroundStyle(line.color)
                }
                if station != nil {
                    Text("· STATION")
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.4)
                        .foregroundStyle(mutedText)
                }
                Spacer()
                Button {
                    withAnimation(.snappy(duration: 0.18)) { focusedId = nil }
                } label: {
                    Image(systemName: "xmark")
                        .scaledFont(size: 11, weight: .bold)
                        .foregroundStyle(mutedText)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            Text(title)
                .scaledFont(size: 16, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let hook, !hook.isEmpty {
                Text(hook)
                    .scaledFont(size: 12, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !neighbors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT STOPS")
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.4)
                        .foregroundStyle(mutedText)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(neighbors, id: \.self) { nid in
                                neighborChip(id: nid)
                            }
                        }
                    }
                }
            }

            Button {
                pendingNavId = id
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Text("Open paper")
                        .scaledFont(size: 13, weight: .semibold)
                    Image(systemName: "arrow.right")
                        .scaledFont(size: 11, weight: .bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tealAccent)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: inkColor.opacity(0.18), radius: 20, x: 0, y: 8)
    }

    private func neighborChip(id: String) -> some View {
        let line = SubwayMap.line(of: id)
        let title = SubwayMap.station(id)?.label ?? nodeTitle(for: id)
        return Button {
            withAnimation(.snappy(duration: 0.22)) { focusedId = id }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Circle().fill(line?.color ?? tealAccent).frame(width: 5, height: 5)
                Text(title)
                    .scaledFont(size: 11, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.white)
                    .overlay(Capsule().stroke((line?.color ?? borderColor).opacity(0.35), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: legend + top chrome

    private var legend: some View {
        HStack(spacing: 0) {
            ForEach(SubwayMap.lines) { line in
                HStack(spacing: 5) {
                    Circle().fill(line.color).frame(width: 6, height: 6)
                    Text(line.label)
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.0)
                        .foregroundStyle(mutedText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                if line.id != SubwayMap.lines.last?.id {
                    Rectangle().fill(borderColor).frame(width: 1, height: 12)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            Capsule().fill(Color.white.opacity(0.92))
                .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                .shadow(color: inkColor.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    private var topChrome: some View {
        HStack(spacing: 8) {
            if onDismiss != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onDismiss?()
                } label: {
                    Image(systemName: "chevron.left")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundStyle(inkColor)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle().fill(Color.white.opacity(0.95))
                                .overlay(Circle().stroke(borderColor, lineWidth: 1))
                                .shadow(color: inkColor.opacity(0.06), radius: 6, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("MAP")
                    .scaledFont(size: 8.5, weight: .bold)
                    .tracking(1.4)
                    .foregroundStyle(mutedText)
                Text("Lineages")
                    .scaledFont(size: 14, weight: .regular, design: .serif)
                    .foregroundStyle(inkColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: inkColor.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }

    // MARK: helpers

    private func nodeTitle(for id: String) -> String {
        if let deck = deckById[id], let t = deck.title, !t.isEmpty { return t }
        if let loop = DailyLoopContent.byPaperId(id) {
            return loop.sourceLine.isEmpty ? loopFallbackTitle(id: id) : loop.sourceLine
        }
        return loopFallbackTitle(id: id)
    }

    private func loopFallbackTitle(id: String) -> String {
        id.replacingOccurrences(of: "loop:foundational:", with: "")
          .replacingOccurrences(of: "loop:", with: "")
          .replacingOccurrences(of: "-", with: " ")
          .capitalized
    }

    private func blob(for id: String) -> String {
        if let deck = deckById[id] {
            return [deck.title, deck.hook, deck.summary].compactMap { $0 }.joined(separator: " ")
                + " " + deck.concepts.flatMap { [$0.title, $0.body] }.joined(separator: " ")
        }
        if let loop = DailyLoopContent.byPaperId(id) {
            return [loop.sourceLine, loop.heroBody, loop.hookBody]
                .compactMap { $0 }.joined(separator: " ")
        }
        return id
    }
}
