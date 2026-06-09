import SwiftUI

// MARK: - GlossaryView
//
// Editorial reference sheet that lists every key term across the papers
// in a bundle. Used as a quick refresher before or during a loop so the
// jargon a paper assumes does not block the reader. Each paper becomes
// a section with a teal rule, paper title in tiny caps, and bold serif
// term plus muted definition rows.

struct GlossaryView: View {
    let bundleTitle: String
    let sections: [Section]

    @Environment(\.dismiss) private var dismiss

    struct Section: Identifiable {
        let slug: String
        let paperTitle: String
        let terms: [GlossaryTerm]
        var id: String { slug }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    ForEach(sections) { section in
                        paperSection(section)
                    }
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 22)
            }
            .background(paperBg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(tealAccent)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(tealAccent).frame(width: 4, height: 4)
                Text("REFERENCE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(tealAccent)
            }
            Text("Glossary")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(inkColor)
            Text(bundleTitle)
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(mutedText)
        }
    }

    private func paperSection(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Rectangle().fill(tealAccent).frame(width: 18, height: 1)
                Text(section.paperTitle.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 14) {
                ForEach(section.terms) { t in
                    termRow(t)
                }
            }
        }
    }

    private func termRow(_ t: GlossaryTerm) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t.term)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
            Text(t.definition)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(mutedText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("end of glossary")
                .font(.system(size: 11, design: .serif))
                .italic()
                .foregroundStyle(mutedText.opacity(0.7))
            Spacer()
        }
        .padding(.top, 8)
    }
}
