import Foundation

// MARK: - Visual DSL

enum VisualType: String, Codable {
    case flow
    case diagram
    case comparison
}

struct VisualNode: Codable, Identifiable {
    let id: String
    let label: String
}

struct VisualEdge: Codable {
    let from: String
    let to: String
    let label: String?

    enum CodingKeys: String, CodingKey {
        case from, to, label
    }
}

struct VisualSchema: Codable {
    let type: VisualType
    let nodes: [VisualNode]
    let edges: [VisualEdge]
}

// MARK: - Diagram DSL (native SwiftUI diagrams)

enum DiagramType: String, Codable {
    case flow
    case barChart         = "bar_chart"
    case comparison
    case attentionHeatmap = "attention_heatmap"
    case multiHead        = "multi_head"
    case sineWaves        = "sine_waves"
    case cycle
    case numberBox        = "number_box"
    case equation
    case custom
}

struct HeadSpec: Codable {
    let name: String
    let color: String
    let weights: [Double]
    let desc: String
}

struct DiagramNode: Codable, Identifiable {
    let id: String
    let label: String
    let sublabel: String?
    let color: String?
}

struct DiagramEdge: Codable {
    let from: String
    let to: String
    let label: String?
}

struct BarSpec: Codable {
    let label: String
    let value: Double
    let color: String?
    let note: String?
}

struct ComparisonItem: Codable {
    let aspect: String
    let before: String
    let after: String
}

struct StepSpec: Codable {
    let label: String
    let sublabel: String?
}

struct EquationTerm: Codable {
    let symbol: String
    let meaning: String
}

struct DiagramSpec: Codable {
    let type: DiagramType
    let caption: String?
    let nodes: [DiagramNode]?
    let edges: [DiagramEdge]?
    let bars: [BarSpec]?
    let yLabel: String?
    let leftLabel: String?
    let rightLabel: String?
    let items: [ComparisonItem]?
    let tokens: [String]?
    let weights: [[Double]]?
    let heads: [HeadSpec]?
    let steps: [StepSpec]?
    let value: String?
    let valueLabel: String?
    let valueSublabel: String?
    let formula: String?
    let terms: [EquationTerm]?
}

extension DiagramSpec {
    static func attentionHeatmap(tokens: [String], weights: [[Double]], caption: String? = nil) -> DiagramSpec {
        DiagramSpec(type: .attentionHeatmap, caption: caption, nodes: nil, edges: nil, bars: nil, yLabel: nil, leftLabel: nil, rightLabel: nil, items: nil, tokens: tokens, weights: weights, heads: nil, steps: nil, value: nil, valueLabel: nil, valueSublabel: nil, formula: nil, terms: nil)
    }
    static func multiHead(tokens: [String], heads: [HeadSpec], caption: String? = nil) -> DiagramSpec {
        DiagramSpec(type: .multiHead, caption: caption, nodes: nil, edges: nil, bars: nil, yLabel: nil, leftLabel: nil, rightLabel: nil, items: nil, tokens: tokens, weights: nil, heads: heads, steps: nil, value: nil, valueLabel: nil, valueSublabel: nil, formula: nil, terms: nil)
    }
    static func sineWaves(caption: String? = nil) -> DiagramSpec {
        DiagramSpec(type: .sineWaves, caption: caption, nodes: nil, edges: nil, bars: nil, yLabel: nil, leftLabel: nil, rightLabel: nil, items: nil, tokens: nil, weights: nil, heads: nil, steps: nil, value: nil, valueLabel: nil, valueSublabel: nil, formula: nil, terms: nil)
    }
    static func flow(nodes: [DiagramNode], edges: [DiagramEdge] = [], caption: String? = nil) -> DiagramSpec {
        DiagramSpec(type: .flow, caption: caption, nodes: nodes, edges: edges, bars: nil, yLabel: nil, leftLabel: nil, rightLabel: nil, items: nil, tokens: nil, weights: nil, heads: nil, steps: nil, value: nil, valueLabel: nil, valueSublabel: nil, formula: nil, terms: nil)
    }
    static func barChart(bars: [BarSpec], yLabel: String? = nil, caption: String? = nil) -> DiagramSpec {
        DiagramSpec(type: .barChart, caption: caption, nodes: nil, edges: nil, bars: bars, yLabel: yLabel, leftLabel: nil, rightLabel: nil, items: nil, tokens: nil, weights: nil, heads: nil, steps: nil, value: nil, valueLabel: nil, valueSublabel: nil, formula: nil, terms: nil)
    }
    static func comparison(leftLabel: String, rightLabel: String, items: [ComparisonItem], caption: String? = nil) -> DiagramSpec {
        DiagramSpec(type: .comparison, caption: caption, nodes: nil, edges: nil, bars: nil, yLabel: nil, leftLabel: leftLabel, rightLabel: rightLabel, items: items, tokens: nil, weights: nil, heads: nil, steps: nil, value: nil, valueLabel: nil, valueSublabel: nil, formula: nil, terms: nil)
    }
}

// MARK: - Concept

struct Concept: Codable, Identifiable {
    var id: String { title }
    let title: String
    let body: String
    let diagramSpec: DiagramSpec?    // Native SwiftUI diagram (preferred)
    let vizHtml: String?             // Interactive HTML (fallback)
    let conceptImageUrl: String?
    let diagram: VisualSchema?       // Legacy (old cached papers)
}

// MARK: - CardDeck

struct CardDeck: Codable, Identifiable {
    var id: String { paperId }
    let paperId: String
    let title: String?
    /// Source URL for the publication (often arXiv abs). Used to merge
    /// duplicate braces when `paper_id` differs across ingestion paths.
    let url: String?
    let source: String?
    let hook: String?
    let summary: String?
    let concepts: [Concept]
    let score: Double?
    let publishedAt: Date?
    let blueprint: DailyLoopBlueprint?
    /// Primary arXiv category (e.g. "cs.CL"), when the backend has it. Drives
    /// the display cluster without text inference. Absent on loop/bundle decks.
    let arxivCategory: String?

    enum CodingKeys: String, CodingKey {
        case paperId     = "paper_id"
        case url
        case title
        case source
        case hook
        case summary
        case concepts
        case score
        case publishedAt    = "published_at"
        case blueprint
        case arxivCategory  = "arxiv_category"
    }

    init(
        paperId: String,
        title: String?,
        source: String?,
        hook: String?,
        summary: String?,
        concepts: [Concept],
        score: Double?,
        publishedAt: Date?,
        blueprint: DailyLoopBlueprint? = nil,
        url: String? = nil,
        arxivCategory: String? = nil
    ) {
        self.paperId = paperId
        self.title = title
        self.url = url
        self.source = source
        self.hook = hook
        self.summary = summary
        self.concepts = concepts
        self.score = score
        self.publishedAt = publishedAt
        self.blueprint = blueprint
        self.arxivCategory = arxivCategory
    }

    // MARK: - Signal Strength (1 to 5)

    var signalStrength: Int {
        guard let s = score else { return 3 }
        switch s {
        case ..<0.2: return 1
        case ..<0.4: return 2
        case ..<0.6: return 3
        case ..<0.8: return 4
        default:     return 5
        }
    }

    var isHighSignal: Bool {
        let highScore = (score ?? 0) >= 0.65
        let recentCutoff = Date().addingTimeInterval(-48 * 60 * 60)
        let recentlyPublished = publishedAt.map { $0 >= recentCutoff } ?? false
        return highScore || recentlyPublished
    }

    /// Builds a minimal CardDeck from a hardcoded DailyLoopContent so
    /// row-based views (Library list, Recently viewed) can render saved
    /// loops that don't have a real backend deck. The synthetic deck
    /// carries no concepts or score, only what the row needs to display.
    static func fromLoop(paperId: String, content: DailyLoopContent) -> CardDeck {
        let plainTitle: String = content.heroTitleSegments.map { seg in
            switch seg {
            case .plain(let s), .highlight(let s): return s
            }
        }.joined()
        return CardDeck(
            paperId: paperId,
            title: content.paperTitle ?? plainTitle,
            source: "loop",
            hook: content.heroBody,
            summary: nil,
            concepts: [],
            score: nil,
            publishedAt: nil,
            blueprint: nil,
            url: Self.arxivAbsURLIfPresent(inSourceLine: content.sourceLine)
        )
    }

    /// New-format arXiv ids in editorial `sourceLine` (e.g. `arXiv:2201.11903 · …`).
    /// When set on loop decks, `canonicalBraceKey` matches API rows with `paper_id == arxiv:<id>`.
    private static func arxivAbsURLIfPresent(inSourceLine line: String) -> String? {
        guard let re = try? NSRegularExpression(
            pattern: #"(?i)(?:arxiv\.org/abs/|arxiv\s*:\s*)(\d{4}\.\d{4,5})(?:v\d+)?"#,
            options: []
        ) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let m = re.firstMatch(in: line, range: range),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: line)
        else { return nil }
        let id = String(line[r]).lowercased()
        return "https://arxiv.org/abs/\(id)"
    }
}

// MARK: - LearningBundle

struct LearningBundle: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let paperSlugs: [String]
    var doneCount: Int
    let estimatedMins: Int
    let level: BundleLevel
    let bgHex: String
    let accentHex: String
    let tags: [String]
    // Marks the bundle as not yet shippable. BundlesView disables the nav
    // link and renders a "Coming soon" lock state. Default false so legacy
    // call sites stay shippable; switch on for routes whose paper decks are
    // still being authored.
    var isLocked: Bool = false

    var count: Int { paperSlugs.count }
    var progress: Double { count > 0 ? Double(doneCount) / Double(count) : 0 }
    var progressPercent: Int { Int(progress * 100) }

    enum BundleLevel: String {
        case beginner     = "Beginner"
        case intermediate = "Intermediate"
        case advanced     = "Advanced"
    }
}

extension LearningBundle {
    static let samples: [LearningBundle] = [
        LearningBundle(
            id: "foundations",
            title: "Foundations: 10 Papers",
            subtitle: "The foundational papers to begin your journey",
            paperSlugs: ["perceptron", "backprop", "lenet", "alexnet",
                         "word2vec", "seq2seq", "gans", "resnet",
                         "attention", "gpt3"],
            doneCount: 0, estimatedMins: 130,
            level: .beginner, bgHex: "1a3a3a", accentHex: "1a8a8a",
            tags: ["Foundations", "History", "Deep Learning"]),

        LearningBundle(
            id: "route-vision",
            title: "Vision",
            subtitle: "How machines learned to see the world.",
            paperSlugs: ["vgg", "batchnorm", "googlenet", "yolo", "rcnn",
                         "unet", "cyclegan", "vit", "ddpm", "clip"],
            doneCount: 0, estimatedMins: 130,
            level: .intermediate, bgHex: "2a1a3a", accentHex: "7b4ba4",
            tags: ["Vision", "Convnets", "Diffusion"],
            isLocked: true),

        LearningBundle(
            id: "route-nlp",
            title: "Language",
            subtitle: "From word vectors to large language models.",
            paperSlugs: ["glove", "elmo", "bert", "gpt2", "t5",
                         "bart", "roberta", "llama", "chinchilla", "instructgpt"],
            doneCount: 0, estimatedMins: 130,
            level: .intermediate, bgHex: "1a2a3a", accentHex: "2d7abf",
            tags: ["NLP", "LLMs", "Pretraining"],
            isLocked: true),

        LearningBundle(
            id: "route-reasoning",
            title: "Reasoning",
            subtitle: "Teaching models to think step by step.",
            paperSlugs: ["chain-of-thought", "scratchpad", "self-consistency",
                         "tot", "least-to-most", "react", "toolformer",
                         "grokking", "emergent-abilities", "rlhf"],
            doneCount: 0, estimatedMins: 130,
            level: .intermediate, bgHex: "3a2a1a", accentHex: "c07014",
            tags: ["Reasoning", "Tools", "Alignment"],
            isLocked: true),
    ]
}

// MARK: - Preview Data

extension CardDeck {
    static let preview = CardDeck(
        paperId: "preview-001",
        title: "Attention Is All You Need",
        source: "arxiv",
        hook: "Every AI you use today exists because of one idea from 2017.",
        summary: "Google researchers replaced the complicated memory based translation model with a single \"attention\" mechanism, letting every word look at every other word simultaneously. It was faster, cheaper, and beat every previous model. It became the foundation of GPT, Claude, and every modern AI.",
        concepts: [
            Concept(
                title: "Self Attention Mechanism",
                body: "Every word computes a relevance score against every other word simultaneously. \"It\" attends to \"the cat\", not by position, but by learned semantic similarity.",
                diagramSpec: .attentionHeatmap(
                    tokens: ["The", "cat", "sat", "on", "the", "mat"],
                    weights: [
                        [0.82, 0.07, 0.04, 0.03, 0.02, 0.02],
                        [0.09, 0.68, 0.09, 0.05, 0.05, 0.04],
                        [0.03, 0.28, 0.43, 0.11, 0.09, 0.06],
                        [0.03, 0.05, 0.14, 0.70, 0.04, 0.04],
                        [0.42, 0.06, 0.05, 0.06, 0.35, 0.06],
                        [0.03, 0.11, 0.28, 0.06, 0.10, 0.42],
                    ]
                ),
                vizHtml: nil, conceptImageUrl: nil, diagram: nil
            ),
            Concept(
                title: "Multi Head Attention",
                body: "Transformers run 8 parallel attention operations. Each head captures a different relationship type: syntax, coreference, semantics. Their outputs are concatenated and projected.",
                diagramSpec: .multiHead(
                    tokens: ["The", "cat", "sat", "on", "the", "mat"],
                    heads: [
                        HeadSpec(name: "Syntax",   color: "#1a8a8a", weights: [0.80, 0.05, 0.10, 0.03, 0.01, 0.01], desc: "subject verb agreement"),
                        HeadSpec(name: "Coref",    color: "#e8a020", weights: [0.02, 0.04, 0.01, 0.04, 0.82, 0.07], desc: "pronoun → noun links"),
                        HeadSpec(name: "Semantic", color: "#7b4ba4", weights: [0.04, 0.72, 0.10, 0.04, 0.05, 0.05], desc: "word meaning similarity"),
                        HeadSpec(name: "Position", color: "#c0573c", weights: [0.01, 0.16, 0.70, 0.09, 0.03, 0.01], desc: "adjacent word context"),
                        HeadSpec(name: "Entity",   color: "#2d7abf", weights: [0.08, 0.02, 0.01, 0.01, 0.02, 0.86], desc: "named entity focus"),
                        HeadSpec(name: "Topic",    color: "#2a8a4a", weights: [0.19, 0.15, 0.14, 0.16, 0.19, 0.17], desc: "global topic signal"),
                        HeadSpec(name: "Dep",      color: "#8a4a1a", weights: [0.01, 0.02, 0.04, 0.01, 0.88, 0.04], desc: "dependency structure"),
                        HeadSpec(name: "Long",     color: "#5a1a8a", weights: [0.09, 0.01, 0.01, 0.01, 0.04, 0.84], desc: "long range context"),
                    ]
                ),
                vizHtml: nil, conceptImageUrl: nil, diagram: nil
            ),
            Concept(
                title: "Positional Encoding",
                body: "With no recurrence, the model is position blind. Sinusoidal embeddings give each position a unique frequency fingerprint, letting the model infer relative distances.",
                diagramSpec: .sineWaves(caption: "Sinusoidal Position Embeddings"),
                vizHtml: nil, conceptImageUrl: nil, diagram: nil
            ),
            Concept(
                title: "Why No Recurrence?",
                body: "RNNs process tokens one at a time. Each step must wait for the last. Gradients vanish over long sequences. The Transformer processes every token in parallel, shrinking the path between any two positions from O(n) to O(1). That single change made large scale training viable.",
                diagramSpec: .comparison(
                    leftLabel: "RNN",
                    rightLabel: "Transformer",
                    items: [
                        ComparisonItem(aspect: "Parallelism",  before: "Sequential",         after: "Fully parallel"),
                        ComparisonItem(aspect: "Long range",   before: "Grad. vanishing",    after: "Direct attention"),
                        ComparisonItem(aspect: "Path length",  before: "O(n) steps",         after: "O(1) steps"),
                        ComparisonItem(aspect: "Training",     before: "GPU unfriendly",      after: "GPU native"),
                    ]
                ),
                vizHtml: nil, conceptImageUrl: nil, diagram: nil
            ),
        ],
        score: 0.87,
        publishedAt: Date().addingTimeInterval(-24 * 60 * 60)
    )
}

// MARK: - Bundle Paper Decks
//
// Static preview decks for the 10 papers listed in the "ML Interviews" bundle.
// Each deck is keyed by a stable slug so rows in BundleDetailView can navigate
// to unique content.

extension CardDeck {
    static let bundlePapers: [String: CardDeck] = [
        "attention": .preview,

        "lora": CardDeck(
            paperId: "lora-001",
            title: "LoRA: Low Rank Adaptation of Large Language Models",
            source: "arxiv",
            hook: "Fine tune a 65B parameter model by training just 0.2% of it.",
            summary: "Instead of updating every weight, LoRA freezes the base model and injects tiny rank r matrices (A × B) into each layer. The original weight stays intact; the adapter learns the task specific delta. Training is 3× faster, uses a fraction of the memory, and adapters can be swapped in and out per task.",
            concepts: [
                Concept(
                    title: "The Rank Decomposition Trick",
                    body: "A 4096×4096 weight update has 16M parameters. LoRA approximates it as A(4096×4) × B(4×4096). That's only 32K parameters, but it recovers most of the fine tuning gain because task specific updates tend to be low rank in practice.",
                    diagramSpec: .barChart(
                        bars: [
                            BarSpec(label: "Full fine tune", value: 16_000_000, color: "#c0573c", note: "16M params"),
                            BarSpec(label: "LoRA r=4", value: 32_000, color: "#1a8a8a", note: "32K params"),
                        ],
                        yLabel: "Trainable params per layer",
                        caption: "1024× fewer trainable parameters"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "Why It Works",
                    body: "Fine tuning updates live on a low dimensional manifold. Even though the base model is huge, the task specific adjustment needed is small. LoRA exploits this intrinsic low rank.",
                    diagramSpec: .comparison(
                        leftLabel: "Full fine tune",
                        rightLabel: "LoRA",
                        items: [
                            ComparisonItem(aspect: "Trainable params", before: "100%", after: "0.2%"),
                            ComparisonItem(aspect: "GPU memory", before: "High", after: "Low"),
                            ComparisonItem(aspect: "Task swapping", before: "Reload model", after: "Swap adapter"),
                            ComparisonItem(aspect: "Inference cost", before: "Same", after: "Same (merged)"),
                        ]
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.84,
            publishedAt: Date().addingTimeInterval(-48 * 60 * 60)
        ),

        "rlhf": CardDeck(
            paperId: "rlhf-001",
            title: "Learning to Summarize from Human Feedback",
            source: "arxiv",
            hook: "Train a model on what humans actually prefer, not what they typed.",
            summary: "Instead of optimizing for next token accuracy, train a reward model from pairwise human preferences, then fine tune the language model with RL to maximize that reward. Output quality beats 10× larger supervised models on summarization tasks.",
            concepts: [
                Concept(
                    title: "The Three Stage Loop",
                    body: "1) Collect human preferences between model outputs. 2) Train a reward model to predict the preferred one. 3) Fine tune the policy with PPO, maximizing reward while staying close to the base model via a KL penalty.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "sft", label: "SFT Model", sublabel: "Base policy", color: "#1a8a8a"),
                            DiagramNode(id: "rm", label: "Reward Model", sublabel: "Learns preferences", color: "#e8a020"),
                            DiagramNode(id: "ppo", label: "PPO Policy", sublabel: "Optimizes reward", color: "#7b4ba4"),
                        ],
                        edges: [
                            DiagramEdge(from: "sft", to: "rm", label: "human labels"),
                            DiagramEdge(from: "rm", to: "ppo", label: "reward signal"),
                        ],
                        caption: "RLHF pipeline"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "Why KL Divergence Matters",
                    body: "Without a KL penalty, the policy drifts far from the base model and produces reward hacked gibberish. The KL term acts as a leash: stay close to sensible language while maximizing reward.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.79,
            publishedAt: Date().addingTimeInterval(-96 * 60 * 60)
        ),

        "adam": CardDeck(
            paperId: "adam-001",
            title: "Adam: A Method for Stochastic Optimization",
            source: "arxiv",
            hook: "The default optimizer for almost every deep learning model, for good reason.",
            summary: "Adam combines momentum (running average of gradients) with RMSprop (running average of squared gradients) to give each parameter its own adaptive learning rate. Robust across problems, minimal tuning, fast convergence.",
            concepts: [
                Concept(
                    title: "Two Moving Averages",
                    body: "m_t tracks the mean gradient (direction). v_t tracks the squared gradient (scale). The update divides momentum by √variance. Parameters with consistent gradients step fast, noisy ones step slow.",
                    diagramSpec: .comparison(
                        leftLabel: "SGD",
                        rightLabel: "Adam",
                        items: [
                            ComparisonItem(aspect: "Learning rate", before: "Global", after: "Per parameter"),
                            ComparisonItem(aspect: "Momentum", before: "Optional", after: "Built in"),
                            ComparisonItem(aspect: "Tuning effort", before: "High", after: "Low"),
                            ComparisonItem(aspect: "Convergence", before: "Slow on sparse", after: "Fast, stable"),
                        ]
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.76,
            publishedAt: Date().addingTimeInterval(-120 * 60 * 60)
        ),

        "batchnorm": CardDeck(
            paperId: "batchnorm-001",
            title: "Batch Normalization: Accelerating Deep Network Training",
            source: "arxiv",
            hook: "One trick cut training time in half and let networks go 10× deeper.",
            summary: "Normalize each layer's pre activations to zero mean and unit variance across the batch, then scale and shift with learned parameters. This stabilizes training, allows much higher learning rates, and reduces dependence on careful initialization.",
            concepts: [
                Concept(
                    title: "Internal Covariate Shift",
                    body: "As earlier layers update, later layers see a constantly shifting input distribution. BatchNorm pins the distribution at each layer, so downstream layers train on a stable target.",
                    diagramSpec: .barChart(
                        bars: [
                            BarSpec(label: "No BN, lr=0.01", value: 72, color: "#c0573c", note: "val acc"),
                            BarSpec(label: "BN, lr=0.01", value: 76, color: "#1a8a8a", note: "val acc"),
                            BarSpec(label: "BN, lr=0.1", value: 79, color: "#1a8a8a", note: "val acc"),
                        ],
                        yLabel: "ImageNet top-5 accuracy (%)",
                        caption: "BN enables much higher learning rates"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.74,
            publishedAt: Date().addingTimeInterval(-144 * 60 * 60)
        ),

        "resnet": CardDeck(
            paperId: "resnet-001",
            title: "Deep Residual Learning for Image Recognition",
            source: "arxiv",
            hook: "Adding a tiny shortcut unlocked 1000-layer networks.",
            summary: "Instead of learning H(x), learn the residual F(x) = H(x) − x and add x back via a skip connection. Gradients flow directly through the shortcut, making very deep networks trainable. ResNet-152 won ImageNet 2015.",
            concepts: [
                Concept(
                    title: "The Skip Connection",
                    body: "A residual block computes output = F(x) + x. If the optimal mapping is identity, the network just drives F toward zero, which is easier than learning identity from scratch. Stack hundreds of these and depth stops hurting.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "x", label: "x", sublabel: "input", color: "#1a8a8a"),
                            DiagramNode(id: "f", label: "F(x)", sublabel: "2 conv layers", color: "#e8a020"),
                            DiagramNode(id: "y", label: "F(x) + x", sublabel: "output", color: "#1a8a8a"),
                        ],
                        edges: [
                            DiagramEdge(from: "x", to: "f", label: nil),
                            DiagramEdge(from: "f", to: "y", label: nil),
                            DiagramEdge(from: "x", to: "y", label: "skip"),
                        ],
                        caption: "Residual block"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.82,
            publishedAt: Date().addingTimeInterval(-168 * 60 * 60)
        ),

        "bert": CardDeck(
            paperId: "bert-001",
            title: "BERT: Pre training Deep Bidirectional Transformers",
            source: "arxiv",
            hook: "Read the whole sentence, both directions, before predicting anything.",
            summary: "BERT pre trains on two unsupervised tasks: masked language modeling (predict hidden tokens from both sides) and next sentence prediction. Fine tuned with one extra layer, it set SOTA on 11 NLP benchmarks simultaneously.",
            concepts: [
                Concept(
                    title: "Bidirectional vs Unidirectional",
                    body: "GPT reads left to right; ELMo concatenates two one directional models. BERT attends to both directions at every layer. Word meaning depends on full context, not just prior tokens.",
                    diagramSpec: .comparison(
                        leftLabel: "GPT (causal)",
                        rightLabel: "BERT (bidir)",
                        items: [
                            ComparisonItem(aspect: "Context", before: "Left only", after: "Both sides"),
                            ComparisonItem(aspect: "Training", before: "Next token", after: "Masked token"),
                            ComparisonItem(aspect: "Use case", before: "Generation", after: "Understanding"),
                        ]
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.81,
            publishedAt: Date().addingTimeInterval(-192 * 60 * 60)
        ),

        "gpt2": CardDeck(
            paperId: "gpt2-001",
            title: "Language Models Are Unsupervised Multitask Learners",
            source: "arxiv",
            hook: "Train on all the internet. Ask it anything. It kind of works.",
            summary: "GPT-2 showed that a large enough language model, trained only to predict the next token on diverse text, learns translation, summarization, and QA without any task specific training. Scale + data diversity = emergent capabilities.",
            concepts: [
                Concept(
                    title: "Zero Shot Task Transfer",
                    body: "Phrasing tasks as continuations (\"Translate English to French: cat →\") lets a pure language model solve them. No fine tuning, no task specific data, just prompting.",
                    diagramSpec: .barChart(
                        bars: [
                            BarSpec(label: "117M", value: 35, color: "#e8f5f5", note: "small"),
                            BarSpec(label: "345M", value: 48, color: "#9cd5d5", note: "medium"),
                            BarSpec(label: "762M", value: 58, color: "#4fb0b0", note: "large"),
                            BarSpec(label: "1.5B", value: 64, color: "#1a8a8a", note: "XL"),
                        ],
                        yLabel: "Zero shot accuracy (%)",
                        caption: "Capability scales with parameters"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.83,
            publishedAt: Date().addingTimeInterval(-216 * 60 * 60)
        ),

        "clip": CardDeck(
            paperId: "clip-001",
            title: "Learning Transferable Visual Models from Natural Language Supervision",
            source: "arxiv",
            hook: "Teach an image model using the web's captions, no labels required.",
            summary: "CLIP trains an image encoder and text encoder jointly: given a batch of (image, caption) pairs, push each image's embedding close to its caption and far from the others. The result: zero shot image classification by comparing to any text prompt.",
            concepts: [
                Concept(
                    title: "Contrastive Dual Encoder",
                    body: "For a batch of N pairs, compute an N×N similarity matrix. Correct pairs (diagonal) should be high; off diagonal low. Both encoders learn a shared embedding space.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "img", label: "Image", sublabel: "ViT encoder", color: "#1a8a8a"),
                            DiagramNode(id: "txt", label: "Caption", sublabel: "Text encoder", color: "#e8a020"),
                            DiagramNode(id: "emb", label: "Shared space", sublabel: "cosine similarity", color: "#7b4ba4"),
                        ],
                        edges: [
                            DiagramEdge(from: "img", to: "emb", label: nil),
                            DiagramEdge(from: "txt", to: "emb", label: nil),
                        ],
                        caption: "Dual encoder contrastive training"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.80,
            publishedAt: Date().addingTimeInterval(-240 * 60 * 60)
        ),

        "ddpm": CardDeck(
            paperId: "ddpm-001",
            title: "Denoising Diffusion Probabilistic Models",
            source: "arxiv",
            hook: "Generate images by learning to reverse noise, step by step.",
            summary: "Gradually add Gaussian noise to training images over T steps until they're pure noise. Train a neural network to reverse one step at a time. To generate, start from noise and iteratively denoise. This became the foundation for Stable Diffusion, DALL·E 2, and Imagen.",
            concepts: [
                Concept(
                    title: "Forward and Reverse Process",
                    body: "Forward: fixed chain that corrupts data with noise. Reverse: learned chain that denoises. The network predicts the noise added at each step, a simpler target than predicting the image itself.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "x0", label: "x₀", sublabel: "clean image", color: "#1a8a8a"),
                            DiagramNode(id: "xt", label: "x_t", sublabel: "noisy latent", color: "#e8a020"),
                            DiagramNode(id: "xT", label: "x_T", sublabel: "pure noise", color: "#7b4ba4"),
                        ],
                        edges: [
                            DiagramEdge(from: "x0", to: "xt", label: "add noise"),
                            DiagramEdge(from: "xt", to: "xT", label: "add noise"),
                            DiagramEdge(from: "xT", to: "x0", label: "learned reverse"),
                        ],
                        caption: "Diffusion process"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.78,
            publishedAt: Date().addingTimeInterval(-264 * 60 * 60)
        ),

        "perceptron": CardDeck(
            paperId: "perceptron-001",
            title: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
            source: "psychological review",
            hook: "The first machine that could learn from examples, and the seed of every neural net.",
            summary: "A single artificial neuron that takes a handful of inputs, weighs each one, and fires if the total crosses a threshold. A simple rule nudges the weights toward better answers each time it gets things wrong. It learned to recognise shapes and lit the fuse on 70 years of neural network research.",
            concepts: [
                Concept(
                    title: "Weighted Sum + Threshold",
                    body: "Each input is multiplied by a weight, summed, and passed through a step function. If wᵀx > θ, output 1; else 0. That single decision boundary is a hyperplane separating two classes.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "x", label: "Inputs xᵢ", sublabel: "features", color: "#1a8a8a"),
                            DiagramNode(id: "w", label: "Σ wᵢxᵢ", sublabel: "weighted sum", color: "#e8a020"),
                            DiagramNode(id: "y", label: "step", sublabel: "fire if > θ", color: "#7b4ba4"),
                        ],
                        edges: [
                            DiagramEdge(from: "x", to: "w", label: nil),
                            DiagramEdge(from: "w", to: "y", label: nil),
                        ],
                        caption: "Perceptron forward pass"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "The Learning Rule",
                    body: "On every misclassification, nudge weights toward the correct answer: w ← w + η(y − ŷ)x. Repeat over the dataset. If the data is linearly separable, the rule is guaranteed to converge.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.90,
            publishedAt: Date().addingTimeInterval(-288 * 60 * 60)
        ),

        "backprop": CardDeck(
            paperId: "backprop-001",
            title: "Learning Representations by Back Propagating Errors",
            source: "nature",
            hook: "One algorithm made deep neural networks trainable, and stayed unbeaten for 40 years.",
            summary: "A way to send the mistake at the output back through every inner layer of a network, telling each piece how much it contributed and how to nudge itself to do better. For the first time, the hidden layers in a deep model could learn what to look for on their own.",
            concepts: [
                Concept(
                    title: "Chain Rule, Layer by Layer",
                    body: "To know how a weight in layer 1 affects the loss, multiply the local derivatives along the path: ∂L/∂w₁ = ∂L/∂y · ∂y/∂h · ∂h/∂w₁. Backprop is just the chain rule applied systematically, once per minibatch.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "x", label: "Input", sublabel: "x", color: "#1a8a8a"),
                            DiagramNode(id: "h", label: "Hidden", sublabel: "h = σ(W₁x)", color: "#e8a020"),
                            DiagramNode(id: "y", label: "Output", sublabel: "ŷ = W₂h", color: "#7b4ba4"),
                            DiagramNode(id: "L", label: "Loss", sublabel: "L(ŷ, y)", color: "#c0573c"),
                        ],
                        edges: [
                            DiagramEdge(from: "x", to: "h", label: "forward"),
                            DiagramEdge(from: "h", to: "y", label: "forward"),
                            DiagramEdge(from: "y", to: "L", label: "forward"),
                            DiagramEdge(from: "L", to: "h", label: "∂L/∂h ←"),
                            DiagramEdge(from: "h", to: "x", label: "∂L/∂W₁ ←"),
                        ],
                        caption: "Forward pass + backward gradient flow"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "Why It Mattered",
                    body: "Before backprop, hidden layers were a mystery, no one knew how to assign credit to them. Backprop gave deep networks an end to end gradient signal. Every modern model, from CNNs to GPT, trains this way.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.92,
            publishedAt: Date().addingTimeInterval(-312 * 60 * 60)
        ),

        "lenet": CardDeck(
            paperId: "lenet-001",
            title: "Gradient Based Learning Applied to Document Recognition",
            source: "ieee",
            hook: "The first working convolutional network, and how computers learned to read handwriting.",
            summary: "A network that scans an image with small reusable detectors, then summarises what they find layer by layer. Trained end to end, it learned to read handwritten zip codes for the postal service. Its blueprint defined image models for the next 20 years.",
            concepts: [
                Concept(
                    title: "Convolution: Shared Weights",
                    body: "Instead of giving every pixel its own weight, slide a small filter across the image. The same filter detects the same feature anywhere, translation invariance for free, with orders of magnitude fewer parameters.",
                    diagramSpec: .comparison(
                        leftLabel: "Fully connected",
                        rightLabel: "Convolutional",
                        items: [
                            ComparisonItem(aspect: "Params/layer",   before: "~1M",       after: "~few K"),
                            ComparisonItem(aspect: "Translation",    before: "Sensitive", after: "Invariant"),
                            ComparisonItem(aspect: "Spatial structure", before: "Ignored", after: "Preserved"),
                            ComparisonItem(aspect: "Generalisation", before: "Weak",      after: "Strong"),
                        ]
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "The Conv → Pool Stack",
                    body: "Conv layers extract features; pooling layers downsample, growing the receptive field. Each block sees a wider patch of the image. Edges → textures → parts → objects, layer by layer.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "in",  label: "32×32",  sublabel: "input",       color: "#1a8a8a"),
                            DiagramNode(id: "c1",  label: "Conv",   sublabel: "6 filters",   color: "#e8a020"),
                            DiagramNode(id: "p1",  label: "Pool",   sublabel: "2×2",         color: "#7b4ba4"),
                            DiagramNode(id: "c2",  label: "Conv",   sublabel: "16 filters",  color: "#e8a020"),
                            DiagramNode(id: "fc",  label: "Dense",  sublabel: "10 classes",  color: "#c0573c"),
                        ],
                        edges: [
                            DiagramEdge(from: "in", to: "c1", label: nil),
                            DiagramEdge(from: "c1", to: "p1", label: nil),
                            DiagramEdge(from: "p1", to: "c2", label: nil),
                            DiagramEdge(from: "c2", to: "fc", label: nil),
                        ],
                        caption: "LeNet-5 architecture"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.86,
            publishedAt: Date().addingTimeInterval(-336 * 60 * 60)
        ),

        "alexnet": CardDeck(
            paperId: "alexnet-001",
            title: "ImageNet Classification with Deep Convolutional Neural Networks",
            source: "nips",
            hook: "The paper that kicked off the deep learning era, by halving the error rate overnight.",
            summary: "A deeper image network trained on a pair of graphics chips for a week. It cut the world's best image error from 26% to 16% in one go, leaving every hand crafted vision system behind. Bigger network, more data, and the right training tricks became the new recipe.",
            concepts: [
                Concept(
                    title: "Three Tricks That Mattered",
                    body: "ReLU (faster than tanh), dropout (kills overfitting), and GPUs (made it tractable). Each was a small idea individually; together they unlocked a regime no one had reached.",
                    diagramSpec: .barChart(
                        bars: [
                            BarSpec(label: "Hand crafted SIFT", value: 26, color: "#c0573c", note: "2010 SOTA"),
                            BarSpec(label: "AlexNet (2012)",    value: 16, color: "#1a8a8a", note: "top-5 err"),
                        ],
                        yLabel: "ImageNet top-5 error (%)",
                        caption: "The 10-point drop that ended the SIFT era"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "Why GPUs?",
                    body: "Convolutions are embarrassingly parallel, millions of independent multiply adds. GPUs were built for that exact pattern. AlexNet split the model across two GTX 580s; modern models live on hundreds of H100s. The hardware lesson stuck.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.91,
            publishedAt: Date().addingTimeInterval(-360 * 60 * 60)
        ),

        "word2vec": CardDeck(
            paperId: "word2vec-001",
            title: "Efficient Estimation of Word Representations in Vector Space",
            source: "arxiv",
            hook: "Words become vectors, and king − man + woman ≈ queen.",
            summary: "Train a tiny network to guess a word from the words around it, or the other way around. The numbers it learns end up turning each word into a point in space, where similar words sit near each other and relationships become directions you can add and subtract. Every modern language system starts from this idea.",
            concepts: [
                Concept(
                    title: "Geometry of Meaning",
                    body: "Train on enough text and similar words drift to similar vectors. Differences encode relations: vec(king) − vec(man) + vec(woman) lands near vec(queen). No grammar engineered, just co occurrence statistics in a 300-d space.",
                    diagramSpec: .comparison(
                        leftLabel: "Before (one hot)",
                        rightLabel: "After (embedding)",
                        items: [
                            ComparisonItem(aspect: "Dimensions",    before: "|V| ≈ 1M",  after: "300"),
                            ComparisonItem(aspect: "Similarity",    before: "Always 0",  after: "Cosine"),
                            ComparisonItem(aspect: "Analogies",     before: "Impossible", after: "Linear"),
                            ComparisonItem(aspect: "Generalises",   before: "No",        after: "Yes"),
                        ]
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "CBOW vs Skip gram",
                    body: "CBOW: predict the centre word from its window. Skip gram: predict the window from the centre word. Skip gram is slower but better on rare words; CBOW is faster on frequent ones.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.83,
            publishedAt: Date().addingTimeInterval(-384 * 60 * 60)
        ),

        "seq2seq": CardDeck(
            paperId: "seq2seq-001",
            title: "Sequence to Sequence Learning with Neural Networks",
            source: "nips",
            hook: "One network reads a sentence in English. Another writes it back in French.",
            summary: "Wire two networks together. The first reads a sentence and compresses it into a single summary. The second takes that summary and writes the sentence back out in another language. End to end neural translation suddenly became possible, no hand crafted rules required.",
            concepts: [
                Concept(
                    title: "Encoder + Decoder",
                    body: "The encoder reads tokens left to right, updating a hidden state. The final hidden state is a 'thought vector', a fixed size summary of the whole input. The decoder takes that vector and generates the output one token at a time.",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "enc", label: "Encoder LSTM", sublabel: "reads input", color: "#1a8a8a"),
                            DiagramNode(id: "ctx", label: "Context", sublabel: "thought vector", color: "#e8a020"),
                            DiagramNode(id: "dec", label: "Decoder LSTM", sublabel: "writes output", color: "#7b4ba4"),
                        ],
                        edges: [
                            DiagramEdge(from: "enc", to: "ctx", label: "compress"),
                            DiagramEdge(from: "ctx", to: "dec", label: "expand"),
                        ],
                        caption: "Seq2seq pipeline"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "Reverse the Source",
                    body: "A small trick: reverse the input sentence before feeding it. Now early target words are close to early source words in the unrolled graph, making gradients flow better. Translation BLEU jumped several points from this alone.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.85,
            publishedAt: Date().addingTimeInterval(-408 * 60 * 60)
        ),

        "gans": CardDeck(
            paperId: "gans-001",
            title: "Generative Adversarial Nets",
            source: "nips",
            hook: "Two networks fight. One learns to forge. The other learns to spot forgeries. Both get scary good.",
            summary: "Set up a game between two networks. One tries to forge realistic fakes. The other tries to catch them. They train at the same time, each one pushing the other to improve, until the fakes are indistinguishable from real data. The idea behind deepfakes, StyleGAN, and modern image synthesis.",
            concepts: [
                Concept(
                    title: "The Adversarial Game",
                    body: "G(z) maps random noise to a sample. D(x) outputs probability that x is real. G wants D fooled; D wants to spot G. Loss is a two player minimax: min_G max_D E[log D(x)] + E[log(1 − D(G(z)))].",
                    diagramSpec: .flow(
                        nodes: [
                            DiagramNode(id: "z",  label: "Noise z", sublabel: "latent",   color: "#1a8a8a"),
                            DiagramNode(id: "g",  label: "G",       sublabel: "forger",   color: "#e8a020"),
                            DiagramNode(id: "d",  label: "D",       sublabel: "detective", color: "#7b4ba4"),
                            DiagramNode(id: "r",  label: "Real x",  sublabel: "data",     color: "#1a8a8a"),
                        ],
                        edges: [
                            DiagramEdge(from: "z", to: "g", label: nil),
                            DiagramEdge(from: "g", to: "d", label: "fake"),
                            DiagramEdge(from: "r", to: "d", label: "real"),
                        ],
                        caption: "Generator vs discriminator"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "Why It's Tricky",
                    body: "Training is unstable. If D wins too fast, G has no useful gradient. If G wins, D collapses. Mode collapse is common, G produces a few realistic samples and ignores the rest. Solving these issues spawned a decade of follow up papers.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.84,
            publishedAt: Date().addingTimeInterval(-432 * 60 * 60)
        ),

        "gpt3": CardDeck(
            paperId: "gpt3-001",
            title: "Language Models are Few Shot Learners",
            source: "arxiv",
            hook: "Make the model 100× bigger and it learns new tasks from a single example.",
            summary: "Take the same model design and make it enormously bigger, then train it on a huge slice of the internet. With no extra retraining, GPT-3 could translate, answer questions, do arithmetic, and write code just by reading a few examples in the prompt. Scale didn't give more of the same, it gave brand new abilities.",
            concepts: [
                Concept(
                    title: "In Context Learning",
                    body: "Show the model 0, 1, or a few examples of a task in the prompt. The weights never change. The model picks up the pattern from context alone and continues it. This is qualitatively different from fine tuning, it's runtime adaptation.",
                    diagramSpec: .barChart(
                        bars: [
                            BarSpec(label: "125M",  value: 9,  color: "#e8f5f5", note: "GPT-3 small"),
                            BarSpec(label: "1.3B",  value: 23, color: "#9cd5d5", note: "medium"),
                            BarSpec(label: "13B",   value: 41, color: "#4fb0b0", note: "large"),
                            BarSpec(label: "175B",  value: 65, color: "#1a8a8a", note: "GPT-3"),
                        ],
                        yLabel: "Few shot accuracy (%)",
                        caption: "Capability scales sharply with parameters"
                    ),
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
                Concept(
                    title: "The Scaling Hypothesis",
                    body: "GPT-3 is the same architecture as GPT-2, just bigger. No new training tricks, no new losses. The result reframed AI research: maybe capability is mostly a function of parameters × data × compute, and most other choices barely matter at scale.",
                    diagramSpec: nil,
                    vizHtml: nil, conceptImageUrl: nil, diagram: nil
                ),
            ],
            score: 0.93,
            publishedAt: Date().addingTimeInterval(-456 * 60 * 60)
        ),
    ]

    static func bundlePaper(slug: String) -> CardDeck {
        bundlePapers[slug] ?? .preview
    }
}

// MARK: - Brace identity (canonical dedupe)
//
// Kept here (not in a standalone file) so older `.xcodeproj` checkouts that
// never picked up `BraceIdentity.swift` still compile — `Models.swift` has
// always been in the MicrolearningApp target.

/// **Brace** — one distilled research work surfaced in Aprecis (deck + prose + viz).
/// The same underlying arXiv preprint must map to **one** brace everywhere in the app,
/// regardless of ingestion path (`arxiv:`, `twitter:`, `hn:`, etc.).
///
/// `canonicalBraceKey` is the grouping key used for merging duplicates in lists and feeds.

enum BraceIdentity {

    /// Canonical key for dedupe. Matching arXiv abs IDs collapse to `arxiv:<id>`.
    /// Nature `/articles/{id}` URLs, DOI links, known seed/loop/bundle `paper_id`
    /// aliases, and a small set of normalized landmark titles merge overlapping rows.
    static func canonicalKey(paperId: String, url: String?, title: String?) -> String {
        if let id = normalizedArxivId(inPaperId: paperId) {
            return "arxiv:\(id)"
        }
        if let u = url, let id = normalizedArxivId(inURL: u) {
            return "arxiv:\(id)"
        }
        if let u = url, let nid = natureArticleId(from: u) {
            return "article:nature:\(nid)"
        }
        if let u = url, let doi = doiFromURL(u) {
            return "doi:\(doi)"
        }

        let pidNorm = paperId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let lit = literatureCanonKey(forPaperId: pidNorm) {
            return lit
        }
        if let land = canonicalLandmarkWork(title: title) {
            return land
        }

        guard !pidNorm.isEmpty else {
            let h = (title ?? "").hashValue
            return "unknown:\(h)"
        }
        return "id:\(pidNorm)"
    }

    /// When two rows share a `canonicalKey`, keep the better distill (more concepts, score).
    static func preferredDuplicate(_ a: CardDeck, _ b: CardDeck) -> CardDeck {
        let ca = a.concepts.count
        let cb = b.concepts.count
        if ca != cb { return ca >= cb ? a : b }
        let sa = a.score ?? 0
        let sb = b.score ?? 0
        if abs(sa - sb) > 0.000_1 { return sa >= sb ? a : b }
        func sourceTier(_ deck: CardDeck) -> Int {
            let pid = deck.paperId.lowercased()
            if pid.hasPrefix("arxiv:") { return 5 }
            if pid.hasPrefix("rss:") { return 4 }
            if pid.hasPrefix("github:") { return 3 }
            if pid.hasPrefix("hackernews:") || pid.hasPrefix("hn:") { return 2 }
            if pid.hasPrefix("twitter:") { return 2 }
            if pid.contains("loop:") || pid.lowercased().hasPrefix("loop") { return 1 }
            return 3
        }
        let ta = sourceTier(a)
        let tb = sourceTier(b)
        if ta != tb { return ta >= tb ? a : b }
        return a.paperId <= b.paperId ? a : b
    }

    /// Merge duplicates in array order (first slot wins position; richer deck replaces at that slot).
    static func mergingDuplicates(_ decks: [CardDeck]) -> [CardDeck] {
        var indexByKey: [String: Int] = [:]
        var rows: [CardDeck] = []
        rows.reserveCapacity(decks.count)
        for deck in decks {
            let key = canonicalKey(paperId: deck.paperId, url: deck.url, title: deck.title)
            if let idx = indexByKey[key] {
                rows[idx] = preferredDuplicate(rows[idx], deck)
            } else {
                indexByKey[key] = rows.count
                rows.append(deck)
            }
        }
        return rows
    }

    private static func normalizedArxivId(inPaperId paperId: String) -> String? {
        let trimmed = paperId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("arxiv:") else { return nil }
        var raw = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        raw = stripArxivVersionSuffix(raw).lowercased()
        return raw.isEmpty ? nil : raw
    }

    private static func normalizedArxivId(inURL string: String) -> String? {
        let lowered = string.lowercased()
        func capture(_ pattern: String) -> String? {
            guard let re = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = re.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)),
                  match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: lowered)
            else { return nil }
            var id = String(lowered[r])
            id = id.replacingOccurrences(of: ".pdf", with: "")
            id = stripArxivVersionSuffix(id).lowercased()
            return id.isEmpty ? nil : id
        }
        return capture(#"arxiv\.org/abs/([^?#\/]+)"#)
            ?? capture(#"arxiv\.org/pdf/([^?#\/]+)"#)
    }

    private static func stripArxivVersionSuffix(_ id: String) -> String {
        let newStyle = #"^([\d]+\.[\d]+)(?:v\d+)?$"#
        if let re = try? NSRegularExpression(pattern: newStyle),
           let m = re.firstMatch(in: id, range: NSRange(id.startIndex..., in: id)),
           let r = Range(m.range(at: 1), in: id) {
            return String(id[r])
        }
        return id
    }

    /// e.g. `https://www.nature.com/articles/323533a0`
    private static func natureArticleId(from urlString: String) -> String? {
        let lowered = urlString.lowercased()
        guard let re = try? NSRegularExpression(pattern: #"nature\.com/articles/([^?#/\s]+)"#, options: []),
              let m = re.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: lowered)
        else { return nil }
        let id = String(lowered[r])
        return id.isEmpty ? nil : id.lowercased()
    }

    private static func doiFromURL(_ urlString: String) -> String? {
        let lowered = urlString.lowercased()
        func grab(_ pattern: String) -> String? {
            guard let re = try? NSRegularExpression(pattern: pattern, options: []),
                  let m = re.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)),
                  m.numberOfRanges > 1,
                  let r = Range(m.range(at: 1), in: lowered)
            else { return nil }
            let raw = String(lowered[r])
            return raw.isEmpty ? nil : raw
        }
        return grab(#"doi\.org/([^?#\s]+)"#)
            ?? grab(#"doi[=:](10\.[^?&\s#]+)"#)
    }

    /// Curated `paper_id` rows that share a work with `loop:foundational:*` or bundle previews.
    private static func literatureCanonKey(forPaperId paperId: String) -> String? {
        switch paperId {
        case "loop:foundational:backprop", "rumelhart:1986", "backprop-001":
            return "article:nature:323533a0"
        case "loop:foundational:perceptron", "rosenblatt:1958", "perceptron-001":
            return "doi:10.1037/h0042519"
        default:
            return nil
        }
    }

    /// Collapses hyphen/space variants so “Back-Propagating” and “Back Propagating” share one key.
    private static func normalizeTitleForLandmarkMatch(_ t: String) -> String {
        t.lowercased()
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .joined(separator: " ")
    }

    private static func canonicalLandmarkWork(title: String?) -> String? {
        guard let t = title, t.count >= 28 else { return nil }
        let n = normalizeTitleForLandmarkMatch(t)
        switch n {
        case "learning representations by back propagating errors":
            return "article:nature:323533a0"
        case "the perceptron: a probabilistic model for information storage and organization in the brain":
            return "doi:10.1037/h0042519"
        default:
            return nil
        }
    }
}

extension CardDeck {
    /// Grouping key shared by all rows that distill the same underlying publication.
    var canonicalBraceKey: String {
        BraceIdentity.canonicalKey(paperId: paperId, url: url, title: title)
    }
}

extension Array where Element == CardDeck {
    /// One entry per canonical brace after merge; richer deck wins collisions.
    func mergingCanonicalBraceDuplicates() -> [CardDeck] {
        BraceIdentity.mergingDuplicates(self)
    }
}
