import SwiftUI

// MARK: - Lesson card views
//
// The reusable card kinds a lesson is assembled from: an editorial cover,
// prose, an in-context glossary stop, and a recap. Bespoke interactive cards
// live in their own files and are dropped in via `LessonCard.interactive`.

// MARK: Editorial cover
//
// The opening card. Built to stop a beginner from bouncing: a hero visual
// carries the weight, the headline is three or four big words, and there is
// one short standfirst line. No paragraph, no scroll.

struct LessonCoverCard: View {
    let eyebrow: String
    let headline: String
    let highlight: String?
    let standfirst: String
    let hero: AnyView

    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.4)
                .foregroundStyle(tealMid)
                .opacity(appear ? 1 : 0)
                .padding(.top, 18)

            Spacer(minLength: 28)

            hero
                .frame(height: 220)
                .scaleEffect(appear ? 1 : 0.86)
                .opacity(appear ? 1 : 0)

            Spacer(minLength: 28)

            headlineText
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 14)

            Text(standfirst)
                .font(.system(size: 15, design: .serif))
                .italic()
                .foregroundStyle(Color(hex: "f4f1ea").opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 14)
                .padding(.horizontal, 6)
                .opacity(appear ? 1 : 0)

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appear = true }
        }
    }

    /// Headline with one optional word lifted into the accent colour.
    private var headlineText: Text {
        let ink = Color(hex: "f4f1ea")
        guard let highlight, let r = headline.range(of: highlight) else {
            return Text(headline).foregroundColor(ink)
        }
        return Text(headline[headline.startIndex..<r.lowerBound]).foregroundColor(ink)
            + Text(highlight).foregroundColor(amberAccent)
            + Text(headline[r.upperBound...]).foregroundColor(ink)
    }
}

// MARK: Inline prose segments
//
// One stylable run of inline text used in lesson prose paragraphs. Built
// to break up flat-grey serif paragraphs with three distinct levels of
// visual hierarchy:
//   .term      — semibold serif in teal accent, for vocabulary the
//                reader should remember (e.g. "linearly separable").
//   .highlight — soft amber wash behind the words, like a real
//                highlighter pen on a printed page, for the one
//                pivotal phrase per paragraph.
//   .bold      — semibold ink, for plain emphasis that needs no colour.
// Anything else stays plain serif body type.

struct LessonProseSegment {
    enum Style { case plain, bold, term, highlight }
    let style: Style
    let text: String

    static func plain(_ s: String) -> LessonProseSegment { .init(style: .plain, text: s) }
    static func bold(_ s: String) -> LessonProseSegment { .init(style: .bold, text: s) }
    static func term(_ s: String) -> LessonProseSegment { .init(style: .term, text: s) }
    static func highlight(_ s: String) -> LessonProseSegment { .init(style: .highlight, text: s) }
}

typealias LessonProseLine = [LessonProseSegment]

/// Renders one prose paragraph from its inline segments via `AttributedString`,
/// so highlights, terms and bold runs flow naturally with word-wrapping.
///
/// Glossary-aware: any technical term from the lesson glossary (injected via
/// the environment) becomes a tappable link inside `.plain` and `.term` runs.
/// Tapping it surfaces an in-context definition sheet. `.bold` and `.highlight`
/// runs are left alone so the amber wash and plain emphasis never clash with
/// the teal term styling.
private struct LessonProseLineView: View {
    let line: LessonProseLine
    let bodyOpacity: Double

    @Environment(\.lessonGlossary) private var glossary
    @State private var hit: DLGlossaryHit?

    var body: some View {
        Text(attributed)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .glossaryTappable(glossary, hit: $hit)
    }

    private var attributed: AttributedString {
        var result = AttributedString("")
        for seg in line {
            switch seg.style {
            case .plain:
                result += lessonGlossarised(
                    seg.text,
                    baseFont: .system(size: 16, design: .serif),
                    baseColor: inkColor.opacity(bodyOpacity),
                    glossary: glossary)
            case .term:
                result += lessonGlossarised(
                    seg.text,
                    baseFont: .system(size: 16, weight: .semibold, design: .serif),
                    baseColor: tealAccent,
                    glossary: glossary)
            case .bold:
                var part = AttributedString(seg.text)
                part.font = .system(size: 16, weight: .semibold, design: .serif)
                part.foregroundColor = inkColor
                result += part
            case .highlight:
                // Amber background mimics a real highlighter; weight stays
                // regular so the wash carries the emphasis, not the type.
                var part = AttributedString(seg.text)
                part.font = .system(size: 16, design: .serif)
                part.foregroundColor = inkColor
                part.backgroundColor = amberAccent.opacity(0.28)
                result += part
            }
        }
        return result
    }
}

// MARK: Prose

/// A single teaching beat: a small kicker, a serif title, one or two short
/// paragraphs. Deliberately light, never a wall of text. Paragraphs are
/// rich segments so terms can lift in teal and key phrases can carry an
/// amber highlighter wash without breaking the line flow.
///
/// The optional `hero` slot is the lever for editorial novelty. Each
/// per-paper card can hand a bespoke illustration into this slot so the
/// cards don't all read as identical kicker/title/body templates. The
/// generic prose layout still works without a hero for less hero-worthy
/// beats.
struct LessonProseCard: View {
    let kicker: String
    let title: String
    let paragraphs: [LessonProseLine]
    let hero: AnyView?

    init(kicker: String,
         title: String,
         paragraphs: [LessonProseLine],
         hero: AnyView? = nil) {
        self.kicker = kicker
        self.title = title
        self.paragraphs = paragraphs
        self.hero = hero
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: hero == nil ? 24 : 14)
            if let hero {
                hero
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)
            }
            Text(kicker.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text(title)
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, line in
                LessonProseLineView(line: line, bodyOpacity: 0.82)
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Illustrated prose
//
// A teaching beat that leads with an editorial illustration, then the text.
// Used when a picture sets up the idea faster than a sentence can.

struct LessonIllustratedCard: View {
    let kicker: String
    let title: String
    let paragraphs: [LessonProseLine]
    let caption: String?
    let illustration: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 14)
            illustration
                .frame(height: 188)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)))
            if let caption {
                Text(caption)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(mutedText)
            }
            Text(kicker.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
                .padding(.top, 2)
            Text(title)
                .font(.system(size: 25, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, line in
                LessonProseLineView(line: line, bodyOpacity: 0.82)
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: In-context glossary

struct LessonGlossaryTerm: Identifiable {
    let term: String
    let definition: String
    var id: String { term }
}

/// A glossary stop placed right after the words were first used, so the
/// jargon is defined in context instead of in a far-off appendix.
struct LessonGlossaryCard: View {
    let intro: String
    let terms: [LessonGlossaryTerm]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 22)
            HStack(spacing: 8) {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(amberAccent)
                Text("THE WORDS, IN PLAIN ENGLISH")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(amberAccent)
            }
            Text(intro)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(inkColor.opacity(0.8))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                ForEach(terms) { t in glossaryRow(t) }
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func glossaryRow(_ t: LessonGlossaryTerm) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tealAccent.opacity(0.5))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 4) {
                Text(t.term)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(inkColor)
                Text(t.definition)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.74))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)))
    }
}

// MARK: Code

/// A short pseudocode listing — the algorithm reduced to the smallest
/// readable form. Rendered as a dark editorial code plate (not a real
/// code editor) so the page reads as illustration, not IDE.
struct LessonCodeLine {
    enum Kind { case comment, keyword, plain }
    let pieces: [(Kind, String)]

    /// Plain line — one piece in default ink.
    static func plain(_ s: String) -> LessonCodeLine {
        LessonCodeLine(pieces: [(.plain, s)])
    }
    /// Whole line is a comment.
    static func comment(_ s: String) -> LessonCodeLine {
        LessonCodeLine(pieces: [(.comment, s)])
    }
    /// Mixed line — `parts` is alternating (kind, text).
    static func mix(_ parts: [(Kind, String)]) -> LessonCodeLine {
        LessonCodeLine(pieces: parts)
    }
}

struct LessonCodeCard: View {
    let kicker: String
    let title: String
    let intro: String?
    let lines: [LessonCodeLine]
    let caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 22)
            Text(kicker.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text(title)
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            if let intro {
                Text(intro)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.78))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            codePlate

            if let caption {
                Text(caption)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(mutedText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var codePlate: some View {
        HStack(alignment: .top, spacing: 12) {
            // Line numbers gutter.
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, _ in
                    Text("\(i + 1)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "f4f1ea").opacity(0.28))
                        .frame(minWidth: 14, alignment: .trailing)
                }
            }
            // Code lines.
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    codeLine(line)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "10131a"))
                // A faint teal accent stripe on the left, like an editor gutter.
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tealAccent.opacity(0.45), lineWidth: 1)
                Rectangle()
                    .fill(tealAccent.opacity(0.7))
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
                    .padding(.leading, 1)
            }
        )
    }

    private func codeLine(_ line: LessonCodeLine) -> some View {
        // Empty plain lines render as a zero-glyph space so the row still
        // takes height and lines up with its gutter number.
        let pieces = line.pieces.map { ($0.0, $0.1.isEmpty ? "\u{00A0}" : $0.1) }
        return pieces.reduce(Text("")) { acc, piece in
            let (kind, text) = piece
            return acc + Text(text)
                .font(.system(size: 13, weight: kind == .keyword ? .semibold : .regular,
                              design: .monospaced))
                .foregroundColor(colorFor(kind))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func colorFor(_ kind: LessonCodeLine.Kind) -> Color {
        switch kind {
        case .comment: return Color(hex: "8aa0a8")
        case .keyword: return tealMid
        case .plain:   return Color(hex: "f4f1ea")
        }
    }
}

// MARK: Formula
//
// A single equation, given room to breathe, with every symbol annotated
// back to the plain words the reader already met. This is a lesson's
// technical layer: the maths sitting under the analogy, shown once on a
// dark plate and fully labelled, never a wall of it.

/// One styled run of a formula. Tints let key symbols lift off the plate
/// so the equation reads as parts, not a string.
struct LessonFormulaPart {
    enum Tint { case ink, teal, amber, dim, blue, violet }
    let text: String
    let tint: Tint

    static func ink(_ s: String) -> LessonFormulaPart { .init(text: s, tint: .ink) }
    static func teal(_ s: String) -> LessonFormulaPart { .init(text: s, tint: .teal) }
    static func amber(_ s: String) -> LessonFormulaPart { .init(text: s, tint: .amber) }
    static func dim(_ s: String) -> LessonFormulaPart { .init(text: s, tint: .dim) }
    static func blue(_ s: String) -> LessonFormulaPart { .init(text: s, tint: .blue) }
    static func violet(_ s: String) -> LessonFormulaPart { .init(text: s, tint: .violet) }
}

/// One symbol from the formula, paired with its plain-English meaning.
struct LessonFormulaAnnotation: Identifiable {
    let symbol: String
    let meaning: String
    var id: String { symbol }
}

struct LessonFormulaCard: View {
    let kicker: String
    let title: String
    let intro: String?
    let formula: [LessonFormulaPart]
    let annotations: [LessonFormulaAnnotation]
    let caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 22)
            Text(kicker.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text(title)
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
            if let intro {
                Text(intro)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.8))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            formulaPlate

            VStack(spacing: 9) {
                ForEach(annotations) { annotationRow($0) }
            }
            .padding(.top, 2)

            if let caption {
                Text(caption)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(mutedText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The equation on a dark editorial plate, mirroring the code card so
    // the technical cards of a lesson read as one family.
    private var formulaPlate: some View {
        formulaText
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "10131a"))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(tealAccent.opacity(0.45), lineWidth: 1)
                }
            )
    }

    private var formulaText: some View {
        formula.reduce(Text("")) { acc, part in
            acc + Text(part.text)
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(tintColor(part.tint))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tintColor(_ t: LessonFormulaPart.Tint) -> Color {
        switch t {
        case .ink:    return Color(hex: "f4f1ea")
        case .teal:   return tealMid
        case .amber:  return amberAccent
        case .dim:    return Color(hex: "f4f1ea").opacity(0.42)
        case .blue:   return Color(hex: "5a9fd8")
        case .violet: return Color(hex: "b08ad0")
        }
    }

    // A monospace symbol chip, then its meaning in plain serif.
    private func annotationRow(_ a: LessonFormulaAnnotation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(a.symbol)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(minWidth: 62)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(tealAccent.opacity(0.1)))
            Text(a.meaning)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(inkColor.opacity(0.78))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
        }
    }
}

// MARK: Paper link · closing

/// The lesson's final beat: a pull quote + a bridge back to the original
/// paper. Mirrors the closer used by `DailyLoopView.CompleteCard` so the
/// two reader formats end the same way.
struct LessonPaperLinkCard: View {
    let quote: String
    let attribution: String
    let linkTitle: String
    let url: URL?

    @State private var browser: BrowserLink?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 22)

            Text("\u{201C}")
                .font(.system(size: 86, weight: .regular, design: .serif))
                .foregroundStyle(tealAccent.opacity(0.55))
                .frame(height: 40, alignment: .top)
                .padding(.leading, -4)

            Text("\(quote)\u{201D}")
                .font(.system(size: 22, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(inkColor.opacity(0.92))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            HStack(spacing: 8) {
                Rectangle()
                    .fill(tealAccent.opacity(0.55))
                    .frame(width: 18, height: 1)
                Text(attribution)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 18)

            Spacer(minLength: 28)

            if let url {
                Button {
                    browser = BrowserLink(url: url)
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("READ THE ORIGINAL")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.6)
                                .foregroundStyle(tealAccent)
                            Text(linkTitle)
                                .font(.system(size: 14, weight: .semibold, design: .serif))
                                .foregroundStyle(inkColor)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(tealAccent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(tealAccent.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .sheet(item: $browser) { link in
                    SafariView(url: link.url).ignoresSafeArea()
                }
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Recap

/// The closing card: what the reader should walk away holding. Set apart
/// from the prose cards with a chapter-close flourish at the top and large
/// italic-serif Roman numerals for each point — borrowed from classical
/// book typography. Each point is its own small numbered moment, not just
/// another bullet.
struct LessonRecapCard: View {
    let title: String
    let points: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer(minLength: 22)

            // Small editorial flourish marking this as a closer.
            chapterCloseRule
                .padding(.bottom, 2)

            Text("WHAT YOU NOW KNOW")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(tealAccent)
            Text(title)
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(points.enumerated()), id: \.offset) { i, p in
                    HStack(alignment: .top, spacing: 18) {
                        numeral(i + 1)
                            .frame(width: 52, alignment: .leading)
                        Text(p)
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(inkColor.opacity(0.84))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }
                }
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Two thin teal rules with a small dot centred — a quiet flourish to
    /// mark the close of the lesson. Drawn with shapes, not a font glyph,
    /// so it always renders.
    private var chapterCloseRule: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(tealAccent.opacity(0.55))
                .frame(width: 40, height: 1)
            Circle()
                .fill(tealAccent.opacity(0.7))
                .frame(width: 4, height: 4)
            Rectangle()
                .fill(tealAccent.opacity(0.55))
                .frame(width: 18, height: 1)
        }
    }

    /// Large italic serif Roman numeral with a thin teal underline.
    private func numeral(_ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(romanNumeral(n))
                .font(.system(size: 34, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(tealAccent)
            Rectangle()
                .fill(tealAccent.opacity(0.55))
                .frame(width: 26, height: 1)
        }
    }

    private func romanNumeral(_ n: Int) -> String {
        switch n {
        case 1: return "I"
        case 2: return "II"
        case 3: return "III"
        case 4: return "IV"
        case 5: return "V"
        case 6: return "VI"
        case 7: return "VII"
        default: return "\(n)"
        }
    }
}

// MARK: - LessonCard factories
//
// Keep lesson files declarative: a lesson reads as a list of these calls.

extension LessonCard {
    static func cover(id: String, eyebrow: String, headline: String,
                      highlight: String? = nil, standfirst: String,
                      hero: @autoclosure @escaping () -> some View) -> LessonCard {
        LessonCard(id: id, theme: .cover, advanceLabel: "Start") { _ in
            LessonCoverCard(eyebrow: eyebrow, headline: headline,
                            highlight: highlight, standfirst: standfirst,
                            hero: AnyView(hero()))
        }
    }

    // Rich variant: paragraphs are arrays of inline segments, so terms can
    // sit in teal and key phrases can carry a highlighter wash without
    // breaking word-wrap. The optional `hero` accepts any view; per-paper
    // editorial illustrations slot in here.
    static func prose(id: String, kicker: String, title: String,
                      paragraphs: [LessonProseLine],
                      hero: AnyView? = nil) -> LessonCard {
        LessonCard(id: id, theme: .paper) { _ in
            LessonProseCard(kicker: kicker, title: title,
                            paragraphs: paragraphs, hero: hero)
        }
    }

    // Convenience overload: bare strings get wrapped into single .plain
    // segments. Kept so lessons that don't need inline emphasis stay
    // declarative.
    static func prose(id: String, kicker: String, title: String,
                      paragraphs: [String],
                      hero: AnyView? = nil) -> LessonCard {
        prose(id: id, kicker: kicker, title: title,
              paragraphs: paragraphs.map { [.plain($0)] },
              hero: hero)
    }

    static func illustrated(id: String, kicker: String, title: String,
                            paragraphs: [LessonProseLine], caption: String? = nil,
                            illustration: @autoclosure @escaping () -> some View) -> LessonCard {
        LessonCard(id: id, theme: .paper) { _ in
            LessonIllustratedCard(kicker: kicker, title: title,
                                  paragraphs: paragraphs, caption: caption,
                                  illustration: AnyView(illustration()))
        }
    }

    static func illustrated(id: String, kicker: String, title: String,
                            paragraphs: [String], caption: String? = nil,
                            illustration: @autoclosure @escaping () -> some View) -> LessonCard {
        illustrated(id: id, kicker: kicker, title: title,
                    paragraphs: paragraphs.map { [.plain($0)] },
                    caption: caption, illustration: illustration())
    }

    static func glossary(id: String, intro: String,
                         terms: [LessonGlossaryTerm]) -> LessonCard {
        LessonCard(id: id, theme: .paper, glossaryTerms: terms) { _ in
            LessonGlossaryCard(intro: intro, terms: terms)
        }
    }

    static func recap(id: String, title: String, points: [String]) -> LessonCard {
        LessonCard(id: id, theme: .focus) { _ in
            LessonRecapCard(title: title, points: points)
        }
    }

    static func code(id: String, kicker: String, title: String,
                     intro: String? = nil, lines: [LessonCodeLine],
                     caption: String? = nil) -> LessonCard {
        LessonCard(id: id, theme: .paper) { _ in
            LessonCodeCard(kicker: kicker, title: title, intro: intro,
                           lines: lines, caption: caption)
        }
    }

    static func formula(id: String, kicker: String, title: String,
                        intro: String? = nil,
                        formula: [LessonFormulaPart],
                        annotations: [LessonFormulaAnnotation],
                        caption: String? = nil) -> LessonCard {
        LessonCard(id: id, theme: .paper) { _ in
            LessonFormulaCard(kicker: kicker, title: title, intro: intro,
                              formula: formula, annotations: annotations,
                              caption: caption)
        }
    }

    static func paperLink(id: String, quote: String, attribution: String,
                          linkTitle: String, url: URL?) -> LessonCard {
        LessonCard(id: id, theme: .paper, advanceLabel: "Finish") { _ in
            LessonPaperLinkCard(quote: quote, attribution: attribution,
                                linkTitle: linkTitle, url: url)
        }
    }

    /// A bespoke interactive card. It must call `progress.markExplored(id)`
    /// once the reader has engaged, which unlocks Continue.
    static func interactive(id: String, advanceLabel: String = "Continue",
                            @ViewBuilder build: @escaping (FlowProgress) -> some View) -> LessonCard {
        LessonCard(id: id, theme: .focus, advanceLabel: advanceLabel,
                   requiresExploration: true, build: build)
    }
}
