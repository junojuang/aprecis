import SwiftUI

// MARK: - BundleDetailView

struct BundleDetailView: View {
    let bundle: LearningBundle
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    @State private var scrollProgress: Double = 0
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var showGlossary = false

    /// Slugs whose canonical content lives in Supabase. Tapping a row whose slug
    /// is in this map fetches the deck (with blueprint) at runtime instead of
    /// rendering the static preview baked into Models.swift.
    static let paperBackendId: [String: String] = [
        "perceptron": "perceptron",
        "backprop":   "backprop",
    ]

    private static let paperMeta: [String: (title: String, tag: String, mins: Int)] = [
        "attention":  ("Attention Is All You Need", "Transformers", 6),
        "lora":       ("LoRA: Low Rank Adaptation of Large LLMs", "Fine Tuning", 5),
        "rlhf":       ("Learning to Summarize from Human Feedback", "RLHF", 7),
        "adam":       ("Adam: A Method for Stochastic Optimization", "Optimization", 4),
        "batchnorm":  ("Batch Normalization: Accelerating Deep Network Training", "Training", 5),
        "resnet":     ("Deep Residual Learning for Image Recognition", "Architecture", 6),
        "bert":       ("BERT: Pre training Deep Bidirectional Transformers", "NLP", 7),
        "gpt2":       ("GPT-2: Language Models Are Multitask Learners", "LLMs", 6),
        "clip":       ("CLIP: Learning Transferable Visual Models from Text", "Multimodal", 5),
        "ddpm":       ("Denoising Diffusion Probabilistic Models", "Diffusion", 8),
        "perceptron": ("The Perceptron (Rosenblatt, 1958)", "Foundations", 5),
        "backprop":   ("Learning Representations by Back Propagating Errors", "Foundations", 7),
        "lenet":      ("Gradient Based Learning Applied to Document Recognition", "CNN", 8),
        "alexnet":    ("ImageNet Classification with Deep CNNs (AlexNet)", "Vision", 7),
        "word2vec":   ("Efficient Estimation of Word Representations (Word2Vec)", "Embeddings", 5),
        "seq2seq":    ("Sequence to Sequence Learning with Neural Networks", "NLP", 6),
        "gans":       ("Generative Adversarial Nets", "Generative", 8),
        "gpt3":       ("Language Models are Few Shot Learners (GPT-3)", "LLMs", 9),
    ]

    private var papers: [(slug: String, title: String, tag: String, mins: Int)] {
        bundle.paperSlugs.compactMap { slug in
            guard let m = Self.paperMeta[slug] else { return nil }
            return (slug, m.title, m.tag, m.mins)
        }
    }

    private var continueSlug: String {
        let nextIdx = min(bundle.doneCount, max(papers.count - 1, 0))
        return papers.indices.contains(nextIdx) ? papers[nextIdx].slug : (papers.first?.slug ?? "")
    }

    @ViewBuilder
    private func destination(forSlug slug: String) -> some View {
        if let backendId = Self.paperBackendId[slug] {
            RemoteDeckDestination(paperId: backendId, fallbackSlug: slug)
        } else if let curated = DailyLoopContent.foundational(slug: slug) {
            DailyLoopView(content: curated.withPaperId(slug == "tot" ? "tree-of-thoughts" : slug))
        } else {
            DeckDestination(deck: CardDeck.bundlePaper(slug: slug))
        }
    }

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                    actionButtons
                    SectionLabel("Papers in this bundle")
                    papersList
                    Spacer(minLength: 40)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { contentHeight = geo.size.height }
                            .onChange(of: geo.size.height) { _, h in contentHeight = h }
                            .preference(key: BundleScrollOffsetKey.self,
                                        value: -geo.frame(in: .named("bundleScroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "bundleScroll")
            .onPreferenceChange(BundleScrollOffsetKey.self) { offset in
                let scrollable = contentHeight - viewportHeight
                guard scrollable > 0 else { scrollProgress = 0; return }
                scrollProgress = min(max(Double(offset / scrollable), 0), 1)
            }
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { viewportHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in viewportHeight = h }
            })
        }
        .overlay(alignment: .top) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(tealAccent.opacity(0.12))
                GeometryReader { geo in
                    Rectangle()
                        .fill(progressBarColor(scrollProgress))
                        .frame(width: geo.size.width * CGFloat(scrollProgress))
                        .motionAware(.linear(duration: 0.06), value: scrollProgress)
                        .motionAware(.easeInOut(duration: 0.3), value: progressBarColor(scrollProgress))
                }
            }
            .frame(height: 3)
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Badges
                HStack(spacing: 6) {
                    Text(bundle.level.rawValue)
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(.white.opacity(0.12))
                        .clipShape(Capsule())

                    Text("\(bundle.count) papers")
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundStyle(Color(hex: bundle.accentHex))
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Color(hex: bundle.accentHex).opacity(0.16))
                        .clipShape(Capsule())

                    Text(String(format: "%dh %dm", bundle.estimatedMins / 60, bundle.estimatedMins % 60))
                        .font(.system(size: 9).monospaced())
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())

                    Spacer()
                }
                .padding(.bottom, 12)

                Text(bundle.title)
                    .scaledFont(size: 22, weight: .bold, design: .serif)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .padding(.bottom, 6)

                Text(bundle.subtitle)
                    .scaledFont(size: 12)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 18)

                // Progress
                VStack(spacing: 6) {
                    HStack {
                        Text("Progress")
                            .scaledFont(size: 10)
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text("\(bundle.progressPercent)% · \(bundle.doneCount)/\(bundle.count) papers")
                            .scaledFont(size: 10, weight: .bold)
                            .foregroundStyle(Color(hex: bundle.accentHex))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.white.opacity(0.12))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: bundle.accentHex))
                                .frame(width: geo.size.width * bundle.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.bottom, 14)

                // Tags
                HStack(spacing: 6) {
                    ForEach(bundle.tags, id: \.self) { tag in
                        Text(tag)
                            .scaledFont(size: 9)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: bundle.bgHex))

            // Wave transition between dark header and cream content
            BundleWaveEdge()
                .fill(paperBg)
                .frame(height: 28)
                .background(Color(hex: bundle.bgHex))
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: destination(forSlug: continueSlug)) {
                Text(bundle.doneCount > 0 ? "Continue Learning" : "Start Bundle")
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: bundle.accentHex))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if !glossarySections.isEmpty {
                Button { showGlossary = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .scaledFont(size: 13, weight: .semibold)
                        Text("Glossary")
                            .scaledFont(size: 13, weight: .semibold, design: .serif)
                    }
                    .foregroundStyle(inkColor)
                    .frame(height: 46)
                    .padding(.horizontal, 14)
                    .background(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .sheet(isPresented: $showGlossary) {
            GlossaryView(bundleTitle: bundle.title, sections: glossarySections)
        }
    }

    // Builds glossary sections for this bundle by pulling each paper's
    // term list from FoundationalGlossaries. Papers with no glossary
    // entries are filtered out so the sheet stays tight.
    private var glossarySections: [GlossaryView.Section] {
        bundle.paperSlugs.compactMap { slug in
            let terms = FoundationalGlossaries.terms(for: slug)
            guard !terms.isEmpty else { return nil }
            let title = Self.paperMeta[slug]?.title ?? slug
            return GlossaryView.Section(slug: slug, paperTitle: title, terms: terms)
        }
    }

    // MARK: - Papers List

    private var papersList: some View {
        VStack(spacing: 0) {
            ForEach(Array(papers.enumerated()), id: \.offset) { idx, paper in
                let progressKey = Self.paperBackendId[paper.slug]
                    ?? CardDeck.bundlePaper(slug: paper.slug).paperId
                let paperProgress = progressStore.progress(for: progressKey)
                NavigationLink(destination: destination(forSlug: paper.slug)) {
                    HStack(spacing: 12) {
                        numberCircle(idx: idx, progress: paperProgress)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(paper.title)
                                .scaledFont(size: 12.5, weight: .semibold)
                                .foregroundStyle(inkColor)
                                .lineLimit(1)
                            Text("\(paper.tag) · \(paper.mins) min")
                                .scaledFont(size: 9.5)
                                .foregroundStyle(mutedText)
                            if paperProgress > 0.01 && paperProgress < 0.98 {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(tealAccent.opacity(0.12))
                                            .frame(height: 2)
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(tealAccent)
                                            .frame(width: geo.size.width * CGFloat(paperProgress), height: 2)
                                    }
                                }
                                .frame(height: 2)
                                .padding(.top, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .scaledFont(size: 10, weight: .medium)
                            .foregroundStyle(mutedText.opacity(0.5))
                    }
                    .padding(.horizontal, 20).padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(cardBg)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(borderColor).frame(height: 1)
                    }
                    .opacity(paperProgress > 0.01 || idx < bundle.doneCount ? 1.0 : 0.7)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func numberCircle(idx: Int, progress: Double) -> some View {
        let accent = Color(hex: bundle.accentHex)
        let isComplete = progress >= 0.98 || idx < bundle.doneCount
        let inProgress = !isComplete && progress > 0.01
        return ZStack {
            Circle()
                .stroke(isComplete || inProgress ? accent.opacity(0.2) : borderColor, lineWidth: 2)
                .background(
                    Circle().fill(isComplete ? accent.opacity(0.12) : .clear)
                )
                .frame(width: 32, height: 32)

            if inProgress {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)
            }

            if isComplete {
                Image(systemName: "checkmark")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(accent)
            } else {
                Text("\(idx + 1)")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundStyle(inProgress ? accent : mutedText)
            }
        }
    }
}

// MARK: - Scroll Preference

private struct BundleScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - BundleWaveEdge

private struct BundleWaveEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height),
            control: CGPoint(x: rect.width / 2, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - RemoteDeckDestination
//
// Loads a single deck from /serve-cards?paper_id=… and forwards it to
// DeckDestination for rendering. While the request is in flight we show a
// minimal cream-on-teal placeholder; on failure we fall back to the static
// preview deck baked into Models.swift so the bundle is never a dead end.

struct RemoteDeckDestination: View {
    let paperId: String
    let fallbackSlug: String

    @State private var deck: CardDeck?
    @State private var failed: Bool = false

    var body: some View {
        Group {
            if let deck {
                DeckDestination(deck: deck)
            } else if failed {
                DeckDestination(deck: CardDeck.bundlePaper(slug: fallbackSlug))
            } else {
                ZStack {
                    paperBg.ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(tealAccent)
                        Text("Loading paper…")
                            .scaledFont(size: 12, design: .serif)
                            .foregroundStyle(mutedText)
                    }
                }
                .task { await load() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func load() async {
        do {
            let fetched = try await APIService.shared.fetchDeck(paperId: paperId)
            await MainActor.run { self.deck = fetched }
        } catch {
            await MainActor.run { self.failed = true }
        }
    }
}
