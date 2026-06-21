import SwiftUI

// MARK: - Lesson inline glossary
//
// Makes technical terms inside lesson prose tappable. A matched term renders
// teal + semibold with a faint dotted underline; tapping it surfaces an
// editorial definition sheet, in context, without leaving the card.
//
// The term set is the lesson's own in-context glossary-card entries merged
// with the curated `FoundationalGlossaries` for that paper. It is injected
// once by `LearningFlowView` and read here via the environment, so prose and
// illustrated cards pick it up with no per-lesson wiring.

// MARK: Environment

private struct LessonGlossaryKey: EnvironmentKey {
    static let defaultValue: [String: String] = [:]
}

extension EnvironmentValues {
    var lessonGlossary: [String: String] {
        get { self[LessonGlossaryKey.self] }
        set { self[LessonGlossaryKey.self] = newValue }
    }
}

// MARK: Term linking

// Builds a styled `AttributedString` for one prose segment, turning any
// glossary term inside it into a tappable `aprecis://gloss/<term>` link.
// Non-matched text keeps the supplied base style. Matching mirrors
// `dlGlossarise`: word-boundary, case-insensitive, longest-first, no overlaps.
func lessonGlossarised(_ text: String,
                       baseFont: Font,
                       baseColor: Color,
                       glossary: [String: String]) -> AttributedString {
    var attr = AttributedString(text)
    attr.font = baseFont
    attr.foregroundColor = baseColor

    if glossary.isEmpty { return attr }

    struct Hit { let nsRange: NSRange; let term: String }
    var hits: [Hit] = []
    let ns = text as NSString
    let full = NSRange(location: 0, length: ns.length)

    for term in glossary.keys {
        let escaped = NSRegularExpression.escapedPattern(for: term)
        // Lookaround on letter/digit so terms with leading/trailing
        // punctuation ("C4.5", "XOR") still anchor cleanly.
        let pattern = "(?<![A-Za-z0-9])\(escaped)(?![A-Za-z0-9])"
        guard let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
        rx.enumerateMatches(in: text, options: [], range: full) { m, _, _ in
            guard let m else { return }
            hits.append(Hit(nsRange: m.range, term: term))
        }
    }
    if hits.isEmpty { return attr }

    // Longest hits win; skip any that overlap an already-claimed range.
    hits.sort { ($0.nsRange.length, -$0.nsRange.location) > ($1.nsRange.length, -$1.nsRange.location) }
    var claimed: [NSRange] = []

    let termFont = Font.system(size: 16, weight: .semibold, design: .serif)
    for hit in hits {
        if claimed.contains(where: { NSIntersectionRange($0, hit.nsRange).length > 0 }) { continue }
        guard let sr = Range(hit.nsRange, in: text),
              let ar = Range(sr, in: attr) else { continue }
        let canonical = glossary.keys.first { $0.caseInsensitiveCompare(hit.term) == .orderedSame } ?? hit.term
        let encoded = canonical.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? canonical
        attr[ar].link = URL(string: "aprecis://gloss/\(encoded)")
        attr[ar].font = termFont
        attr[ar].foregroundColor = tealAccent
        attr[ar].underlineStyle = Text.LineStyle(pattern: .dot, color: tealAccent.opacity(0.5))
        claimed.append(hit.nsRange)
    }
    return attr
}

// MARK: Definition sheet

/// In-context definition surfaced when a reader taps a glossary term in lesson
/// prose. A short Kindle-style bottom sheet, styled to match the editorial
/// paper background so it reads as part of the lesson, not a system alert.
struct LessonGlossarySheet: View {
    let hit: DLGlossaryHit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(tealAccent).frame(width: 4, height: 4)
                Text("DEFINITION")
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(1.8)
                    .foregroundStyle(tealAccent)
            }
            Text(hit.term)
                .scaledFont(size: 22, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor)
            Text(hit.definition)
                .scaledFont(size: 15, design: .serif)
                .foregroundStyle(inkColor.opacity(0.78))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paperBg.ignoresSafeArea())
        .presentationDetents([.fraction(0.3), .medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: Tappable modifier

extension View {
    /// Installs the `aprecis://gloss/` URL handler + definition sheet. Apply
    /// to any view that renders `lessonGlossarised` text.
    func glossaryTappable(_ glossary: [String: String],
                          hit: Binding<DLGlossaryHit?>) -> some View {
        self
            .tint(tealAccent)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "aprecis", url.host == "gloss" else { return .systemAction }
                let raw = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
                let key = glossary.keys.first { $0.caseInsensitiveCompare(raw) == .orderedSame } ?? raw
                guard let def = glossary[key] else { return .systemAction }
                hit.wrappedValue = DLGlossaryHit(term: key, definition: def)
                return .handled
            })
            .sheet(item: hit) { LessonGlossarySheet(hit: $0) }
    }
}
