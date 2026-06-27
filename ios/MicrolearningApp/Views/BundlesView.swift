import SwiftUI

// MARK: - BundlesView
//
// Bundle index. List of bundles (cream/serif editorial cards). Tapping a
// bundle pushes BundlePathView, which renders the Duolingo-style zigzag
// learning path for that bundle.

struct BundlesView: View {
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    pageHeader
                    VStack(spacing: 16) {
                        ForEach(LearningBundle.samples) { bundle in
                            if bundle.isLocked {
                                // Render locked variant inline: no nav target,
                                // no tap navigation, but the card still shows
                                // up in the list so users see the upcoming
                                // tracks and their lock state.
                                BundleCard(bundle: bundle)
                                    .accessibilityHint("Coming soon")
                            } else {
                                NavigationLink(destination: BundlePathView(bundle: bundle)) {
                                    BundleCard(bundle: bundle)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bundles")
                .scaledFont(size: 32, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)
            Text("Pick a path. Each one runs ten papers deep.")
                .scaledFont(size: 13, design: .serif)
                .italic()
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 28)
    }
}

// MARK: - BundleCard

private struct BundleCard: View {
    let bundle: LearningBundle
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var accent: Color { Color(hex: bundle.accentHex) }

    private var doneCount: Int {
        var c = 0
        for slug in bundle.paperSlugs {
            guard let pid = bundlePaperId(slug: slug),
                  progressStore.progress(for: pid) >= 0.98
            else { break }
            c += 1
        }
        return c
    }

    private var progress: Double {
        bundle.count > 0 ? Double(doneCount) / Double(bundle.count) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(bundle.level.rawValue.uppercased())
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(1.2)
                    .foregroundStyle(bundle.isLocked ? mutedText : accent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background((bundle.isLocked ? mutedText : accent).opacity(0.12))
                    .clipShape(Capsule())
                Text("\(bundle.count) papers")
                    .scaledFont(size: 10, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                Spacer()
                if bundle.isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .scaledFont(size: 9, weight: .bold)
                        Text("COMING SOON")
                            .scaledFont(size: 9, weight: .bold)
                            .tracking(1.2)
                    }
                    .foregroundStyle(mutedText)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().stroke(mutedText.opacity(0.35), lineWidth: 1))
                } else {
                    Image(systemName: "chevron.right")
                        .scaledFont(size: 11, weight: .medium)
                        .foregroundStyle(mutedText.opacity(0.5))
                }
            }

            Text(bundle.title)
                .scaledFont(size: 20, weight: .semibold, design: .serif)
                .foregroundStyle(bundle.isLocked ? inkColor.opacity(0.55) : inkColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(bundle.subtitle)
                .scaledFont(size: 12.5, design: .serif)
                .italic()
                .foregroundStyle(mutedText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(borderColor).frame(height: 4)
                        Capsule()
                            .fill(bundle.isLocked ? mutedText.opacity(0.5) : accent)
                            .frame(width: geo.size.width * CGFloat(progress), height: 4)
                    }
                }
                .frame(height: 4)
                Text(bundle.isLocked ? "Locked" : "\(doneCount)/\(bundle.count)")
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(0.8)
                    .foregroundStyle(bundle.isLocked ? mutedText : accent)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bundle.isLocked ? cardBg.opacity(0.6) : cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    bundle.isLocked ? borderColor.opacity(0.5) : borderColor,
                    style: StrokeStyle(lineWidth: 1, dash: bundle.isLocked ? [4, 3] : [])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(bundle.isLocked ? 0.78 : 1.0)
    }
}

// MARK: - BundlePathView
//
// Single-bundle Duolingo-style learning path. Wraps StagePathView for one
// bundle and adds nav-bar back button.

struct BundlePathView: View {
    let bundle: LearningBundle

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    StagePathView(
                        bundle: bundle,
                        stageNumber: 1,
                        isLocked: false,
                        isLast: true
                    )
                }
                .padding(.top, 8)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle(bundle.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - StagePathView

enum NodeStatus { case completed, current, locked, comingSoon }

struct StagePathView: View {
    let bundle: LearningBundle
    let stageNumber: Int
    let isLocked: Bool
    let isLast: Bool

    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var accent: Color { Color(hex: bundle.accentHex) }

    private var dynamicDoneCount: Int {
        var c = 0
        for slug in bundle.paperSlugs {
            guard let pid = bundlePaperId(slug: slug),
                  progressStore.progress(for: pid) >= 0.98
            else { break }
            c += 1
        }
        return c
    }

    private var dynamicProgress: Double {
        bundle.count > 0 ? Double(dynamicDoneCount) / Double(bundle.count) : 0
    }

    private var dynamicComplete: Bool {
        dynamicDoneCount >= bundle.count && bundle.count > 0
    }

    private func nodeStatus(at index: Int) -> NodeStatus {
        if isLocked { return .locked }
        let slug = bundle.paperSlugs[index]
        guard let pid = bundlePaperId(slug: slug) else {
            return index <= dynamicDoneCount ? .comingSoon : .locked
        }
        if progressStore.progress(for: pid) >= 0.98 { return .completed }
        if index == dynamicDoneCount { return .current }
        return .locked
    }

    var body: some View {
        VStack(spacing: 0) {
            stageHeader
            path
            if !isLast { stageDivider }
        }
    }

    // MARK: header

    private var stageHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isLocked ? mutedText.opacity(0.12) : accent.opacity(0.18))
                    .frame(width: 48, height: 48)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundStyle(mutedText)
                } else {
                    Text("\(stageNumber)")
                        .scaledFont(size: 20, weight: .semibold, design: .serif)
                        .foregroundStyle(accent)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("STAGE \(stageNumber) · \(bundle.level.rawValue.uppercased())")
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(1.4)
                    .foregroundStyle(mutedText)
                Text(bundle.title)
                    .scaledFont(size: 18, weight: .semibold, design: .serif)
                    .foregroundStyle(isLocked ? mutedText : inkColor)
                    .lineLimit(2)
                Text(bundle.subtitle)
                    .scaledFont(size: 12, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                    .lineLimit(2)
                progressBar
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(borderColor).frame(height: 4)
                    Capsule()
                        .fill(isLocked ? mutedText.opacity(0.4) : accent)
                        .frame(width: geo.size.width * CGFloat(dynamicProgress), height: 4)
                }
            }
            .frame(height: 4)
            Text("\(dynamicDoneCount)/\(bundle.count)")
                .scaledFont(size: 9, weight: .bold)
                .tracking(0.8)
                .foregroundStyle(isLocked ? mutedText : accent)
        }
        .padding(.top, 4)
    }

    // MARK: path

    private var path: some View {
        VStack(spacing: 0) {
            ForEach(Array(bundle.paperSlugs.enumerated()), id: \.offset) { idx, slug in
                pathNode(index: idx, slug: slug)
                if idx < bundle.paperSlugs.count - 1 {
                    pathConnector(fromIndex: idx, completed: nodeStatus(at: idx) == .completed)
                }
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func pathNode(index: Int, slug: String) -> some View {
        let status  = nodeStatus(at: index)
        let xOffset = nodeOffset(index: index)
        let label   = paperLabel(slug: slug)
        let tagline = paperTagline(slug: slug)

        ZStack {
            Group {
                if status == .completed || status == .current,
                   let pid  = bundlePaperId(slug: slug),
                   let deck = bundlePaperDeck(slug: slug, paperId: pid) {
                    NavigationLink(destination: DeckDestination(deck: deck)) {
                        nodeContent(index: index, status: status, label: label)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Locked or coming-soon: render but don't navigate. Light
                    // haptic on tap so the user gets feedback that the step
                    // is gated, not just unresponsive.
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    } label: {
                        nodeContent(index: index, status: status, label: label)
                    }
                    .buttonStyle(.plain)
                }
            }
            .offset(x: xOffset)

            Text(tagline)
                .scaledFont(size: 10.5, design: .serif)
                .italic()
                .foregroundStyle(mutedText.opacity(status == .locked || status == .comingSoon ? 0.4 : 0.65))
                .lineLimit(2)
                .multilineTextAlignment(taglineTextAlignment(for: xOffset))
                .frame(width: 130, alignment: taglineFrameAlignment(for: xOffset))
                .offset(x: taglineOffset(index: index), y: -10)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
    }

    private func taglineOffset(index: Int) -> CGFloat {
        let n = nodeOffset(index: index)
        if n < 0 { return n + 130 }
        if n > 0 { return n - 130 }
        return 130
    }

    private func taglineTextAlignment(for x: CGFloat) -> TextAlignment {
        x > 0 ? .trailing : .leading
    }

    private func taglineFrameAlignment(for x: CGFloat) -> Alignment {
        x > 0 ? .trailing : .leading
    }

    private func paperTagline(slug: String) -> String {
        switch slug {
        // Foundations
        case "perceptron": return "First learning machine, 1958."
        case "backprop":   return "Networks learn from their mistakes."
        case "lenet":      return "First convnet that worked at scale."
        case "alexnet":    return "Deep learning's breakthrough moment."
        case "word2vec":   return "Meaning, mapped into vector space."
        case "seq2seq":    return "Translation by neural decoder."
        case "gans":       return "Two nets, one forges, one judges."
        case "resnet":     return "Skip connections rescue deep nets."
        case "attention":  return "Every word looks at every other."
        case "gpt3":       return "Scale beat clever design."
        // Vision
        case "vgg":        return "Depth as the only trick."
        case "batchnorm":  return "Stabilised training, everywhere."
        case "googlenet":  return "Inception modules, parallel views."
        case "yolo":       return "One pass, every object found."
        case "rcnn":       return "Regions first, then classify."
        case "unet":       return "Encoder-decoder for pixels."
        case "cyclegan":   return "Translate without paired data."
        case "vit":        return "Transformers, applied to images."
        case "ddpm":       return "Noise, then reverse the noise."
        case "clip":       return "Image and text, same space."
        // NLP
        case "glove":        return "Vectors from co-occurrence stats."
        case "elmo":         return "Context-aware word vectors."
        case "bert":         return "Pretrain, fill the blank, finetune."
        case "gpt2":         return "Language models do many tasks."
        case "t5":           return "Every NLP task, text in, text out."
        case "bart":         return "Denoise to learn generation."
        case "roberta":      return "BERT, but trained better."
        case "llama":        return "Open weights, dense and capable."
        case "chinchilla":   return "Compute laws, redrawn."
        case "instructgpt":  return "Tuned to follow human intent."
        // Reasoning
        case "chain-of-thought":   return "Show your working, get smarter."
        case "scratchpad":         return "Use a notepad, do hard math."
        case "self-consistency":   return "Sample many, pick the agreed."
        case "tot":                return "Search a tree of partial thoughts."
        case "least-to-most":      return "Decompose, then climb the rungs."
        case "react":              return "Reason and act in the same loop."
        case "toolformer":         return "Models call APIs themselves."
        case "grokking":           return "Generalisation arrives, eventually."
        case "emergent-abilities": return "Skills that appear at scale."
        case "rlhf":               return "Humans rank, models learn taste."
        default:                   return ""
        }
    }

    private func nodeContent(index: Int, status: NodeStatus, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if status == .current {
                    Circle()
                        .stroke(amberAccent, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .frame(width: 70, height: 70)
                }
                Circle()
                    .fill(nodeFill(status: status))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().stroke(nodeStroke(status: status), lineWidth: 1.5)
                    )
                    .shadow(color: inkColor.opacity(status == .current ? 0.18 : 0.06),
                            radius: status == .current ? 8 : 4, y: 2)
                nodeGlyph(index: index, status: status)
            }
            Text(label.uppercased())
                .scaledFont(size: 9, weight: .bold)
                .tracking(1.0)
                .foregroundStyle(labelColor(status: status))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 110)
        }
    }

    @ViewBuilder
    private func nodeGlyph(index: Int, status: NodeStatus) -> some View {
        switch status {
        case .completed:
            Image(systemName: "checkmark")
                .scaledFont(size: 18, weight: .bold)
                .foregroundStyle(.white)
        case .current:
            Image(systemName: "play.fill")
                .scaledFont(size: 14, weight: .bold)
                .foregroundStyle(.white)
        case .locked:
            Image(systemName: "lock.fill")
                .scaledFont(size: 14, weight: .bold)
                .foregroundStyle(mutedText)
        case .comingSoon:
            Image(systemName: "hourglass")
                .scaledFont(size: 13, weight: .semibold)
                .foregroundStyle(mutedText)
        }
    }

    private func nodeFill(status: NodeStatus) -> Color {
        switch status {
        case .completed:  return accent
        case .current:    return amberAccent
        case .locked:     return mutedText.opacity(0.10)
        case .comingSoon: return cardBg
        }
    }

    private func nodeStroke(status: NodeStatus) -> Color {
        switch status {
        case .completed:  return .clear
        case .current:    return amberAccent
        case .locked:     return mutedText.opacity(0.3)
        case .comingSoon: return mutedText.opacity(0.35)
        }
    }

    private func labelColor(status: NodeStatus) -> Color {
        switch status {
        case .current:    return amberAccent
        case .completed:  return mutedText
        case .locked:     return mutedText.opacity(0.6)
        case .comingSoon: return mutedText.opacity(0.55)
        }
    }

    private func nodeOffset(index: Int) -> CGFloat {
        // Three-step zigzag: left, center, right, center, left, ...
        let cycle = index % 4
        switch cycle {
        case 0: return -60
        case 1: return 0
        case 2: return 60
        default: return 0
        }
    }

    private func pathConnector(fromIndex: Int, completed: Bool) -> some View {
        let from = nodeOffset(index: fromIndex)
        let to   = nodeOffset(index: fromIndex + 1)
        let mid  = (from + to) / 2
        return VStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { _ in
                Circle()
                    .fill(completed ? accent.opacity(0.55)
                                    : (isLocked ? mutedText.opacity(0.18) : mutedText.opacity(0.28)))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 38)
        .offset(x: mid)
        .padding(.vertical, 4)
    }

    private func paperLabel(slug: String) -> String {
        switch slug {
        // Foundations
        case "perceptron": return "Perceptron"
        case "backprop":   return "Backprop"
        case "lenet":      return "LeNet"
        case "alexnet":    return "AlexNet"
        case "word2vec":   return "Word2Vec"
        case "seq2seq":    return "Seq2Seq"
        case "gans":       return "GANs"
        case "resnet":     return "ResNet"
        case "attention":  return "Attention"
        case "gpt3":       return "GPT-3"
        // Vision
        case "vgg":        return "VGG"
        case "batchnorm":  return "BatchNorm"
        case "googlenet":  return "GoogLeNet"
        case "yolo":       return "YOLO"
        case "rcnn":       return "R-CNN"
        case "unet":       return "U-Net"
        case "cyclegan":   return "CycleGAN"
        case "vit":        return "ViT"
        case "ddpm":       return "DDPM"
        case "clip":       return "CLIP"
        // NLP
        case "glove":        return "GloVe"
        case "elmo":         return "ELMo"
        case "bert":         return "BERT"
        case "gpt2":         return "GPT-2"
        case "t5":           return "T5"
        case "bart":         return "BART"
        case "roberta":      return "RoBERTa"
        case "llama":        return "LLaMA"
        case "chinchilla":   return "Chinchilla"
        case "instructgpt":  return "InstructGPT"
        // Reasoning
        case "chain-of-thought":   return "CoT"
        case "scratchpad":         return "Scratchpad"
        case "self-consistency":   return "Self-Consistency"
        case "tot":                return "Tree-of-Thoughts"
        case "least-to-most":      return "Least-to-Most"
        case "react":              return "ReAct"
        case "toolformer":         return "Toolformer"
        case "grokking":           return "Grokking"
        case "emergent-abilities": return "Emergent Abilities"
        case "rlhf":               return "RLHF"
        default:                   return slug.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    // MARK: stage divider

    private var stageDivider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(borderColor).frame(height: 1)
            Image(systemName: dynamicComplete ? "checkmark.seal.fill" : "arrow.down")
                .scaledFont(size: 11, weight: .semibold)
                .foregroundStyle(dynamicComplete ? accent : mutedText)
            Rectangle().fill(borderColor).frame(height: 1)
            Rectangle().fill(borderColor.opacity(0.5)).frame(width: 22, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 26)
    }
}

// MARK: - Slug → paper resolver
//
// Maps a bundle paper slug to the paperId / CardDeck for the matching daily
// loop. Returns nil for slugs without backing content yet (route placeholders
// like "vgg" or "bert"); those nodes render as locked / coming-soon.

func bundlePaperId(slug: String) -> String? {
    switch slug {
    case "perceptron", "backprop", "lenet", "alexnet",
         "word2vec", "seq2seq", "gans", "resnet",
         "attention", "gpt3", "bert", "instructgpt",
         "chain-of-thought", "scratchpad", "self-consistency",
         "least-to-most", "react", "toolformer", "grokking",
         "deepseek-r1":
        return slug
    case "tot":
        return "tree-of-thoughts"
    case "cot":
        return "chain-of-thought"
    case "selfconsist":
        return "self-consistency"
    case "vit", "ddpm", "clip", "controlnet", "sam":
        return slug
    case "sd":
        return "stable-diffusion"
    case "t5", "chinchilla", "palm", "llama", "mixtral":
        return slug
    case "reflexion":
        return slug
    default:
        return nil
    }
}

func bundlePaperDeck(slug: String, paperId: String) -> CardDeck? {
    guard let content = DailyLoopContent.byPaperId(paperId) else { return nil }
    return CardDeck.fromLoop(paperId: paperId, content: content)
}

// MARK: - LearningBundle helpers

extension LearningBundle {
    @MainActor
    func isPathComplete(progressStore: ReadingProgressStore) -> Bool {
        guard count > 0 else { return false }
        for slug in paperSlugs {
            guard let pid = bundlePaperId(slug: slug),
                  progressStore.progress(for: pid) >= 0.98
            else { return false }
        }
        return true
    }
}
