import Foundation
import SwiftUI

// MARK: - Branch Daily Loop Content
//
// Curated branch papers that sit above the foundation trunk. These use the
// same DailyLoopContent grammar as the foundational loops, but avoid the
// native studio override path so they remain lightweight and data-like.

extension DailyLoopContent {

    static func branch(category: String, slug: String) -> DailyLoopContent? {
        var content: DailyLoopContent?
        let paperId: String
        switch (category, slug) {
        case ("vision", "vit"), (_, "vit"): content = .visionTransformer; paperId = "vit"
        case ("vision", "ddpm"), (_, "ddpm"): content = .ddpm; paperId = "ddpm"
        case ("vision", "clip"), (_, "clip"): content = .clip; paperId = "clip"
        case ("vision", "sd"), (_, "sd"), (_, "stable-diffusion"): content = .stableDiffusion; paperId = "stable-diffusion"
        case ("vision", "controlnet"), (_, "controlnet"): content = .controlNet; paperId = "controlnet"
        case ("vision", "sam"), (_, "sam"): content = .segmentAnything; paperId = "sam"
        case ("language", "t5"), (_, "t5"): content = .t5; paperId = "t5"
        case ("language", "chinchilla"), (_, "chinchilla"): content = .chinchilla; paperId = "chinchilla"
        case ("language", "llama"), (_, "llama"): content = .llama; paperId = "llama"
        case ("language", "palm"), (_, "palm"): content = .palm; paperId = "palm"
        case ("language", "mixtral"), (_, "mixtral"): content = .mixtral; paperId = "mixtral"
        case ("reasoning", "reflexion"), (_, "reflexion"): content = .reflexion; paperId = "reflexion"
        default: return nil
        }

        if var c = content {
            c.paperId = paperId
            return c
        }
        return nil
    }

    // MARK: ViT

    static let visionTransformer = DailyLoopContent(
        heroEyebrow: "VISION · TRANSFORMERS",
        heroTitleSegments: [
            .plain("An image becomes "),
            .highlight("a sentence of patches")
        ],
        heroBody: "ViT showed that a plain Transformer could understand images if you chop the picture into patches and treat those patches like tokens.",
        sourceLine: "arXiv:2010.11929 · Dosovitskiy et al.",

        hookSegments: [
            .plain("What if a photo could be "),
            .highlight("read"),
            .plain(" like text?")
        ],
        hookBody: "Before ViT, image models usually scanned pictures with small sliding filters. That made sense: nearby pixels form edges, edges form shapes, shapes form objects. ViT asked a stranger question. What if we cut the image into a grid of little squares, line them up like words, and let a Transformer decide which patches should look at each other?",

        coreIdeaSegments: [
            .plain("Three moves turn pixels into "),
            .highlight("tokens")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Cut the image into patches",
                detail: "A 224 by 224 image becomes a grid of 16 by 16 patches. Each patch is flattened into numbers, like one chunky visual word."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Add position so order survives",
                detail: "A Transformer has no built-in sense of left, right, top, or bottom. Position embeddings tell each patch where it came from in the picture."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Let attention connect the scene",
                detail: "Self-attention lets any patch read any other patch. A dog's eye can connect to its ear, tail, and background without waiting for many convolution layers."),
        ],

        eliAnalogyLabel: "ANALOGY · A MOSAIC ON A TABLE",
        eliHeadlineSegments: [
            .plain("Like solving a picture "),
            .highlight("tile by tile")
        ],
        eliBodyParts: [
            .plain("Imagine cutting a poster into square tiles and spreading them on a table. A normal vision model studies nearby tiles first. ViT lets every tile "),
            .bold("ask every other tile"),
            .plain(" what it contains, then builds the answer from the whole conversation."),
        ],
        eliArt: .map,

        diagramSegments: [
            .plain("How ViT "),
            .highlight("reads an image")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "image", label: "Image", sublabel: "pixels",
                          panelTitle: "Image · the raw picture",
                          panelBody: "The input is still ordinary pixels. ViT's first trick is not a new camera, it is a new way to package the picture."),
            DLDiagramNode(id: "patches", label: "Patches", sublabel: "16 x 16",
                          panelTitle: "Patches · visual tokens",
                          panelBody: "The picture is split into equal squares. Each square becomes one token, the same role a word token plays in a language Transformer."),
            DLDiagramNode(id: "positions", label: "Position", sublabel: "where",
                          panelTitle: "Position · the lost grid",
                          panelBody: "Flattening the patches would erase layout. Position embeddings put the grid back so the model knows which patch was above, below, left, or right."),
            DLDiagramNode(id: "attention", label: "Attention", sublabel: "global",
                          panelTitle: "Attention · the whole scene",
                          panelBody: "Every patch can compare itself with every other patch. The model learns long-range visual relationships directly."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four steps from pixels to a Transformer-friendly image. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · PATCH SIZE",
                titleSegments: [
                    .plain("Smaller patches, "),
                    .highlight("more tokens")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "tokens per 224px image",
                    primaryLabel: "Tokens",
                    secondaryLabel: nil,
                    yMax: 800,
                    yTickLabels: ["0", "400", "800"],
                    points: [
                        DLBarPoint(label: "32px", sublabel: "coarse", primary: 49, secondary: nil,
                                   annotation: "Big patches mean few tokens, so attention is cheaper, but each token hides a lot of detail."),
                        DLBarPoint(label: "16px", sublabel: "ViT-B", primary: 196, secondary: nil,
                                   annotation: "The common ViT-B/16 setup uses 196 patch tokens for a 224px image."),
                        DLBarPoint(label: "8px", sublabel: "fine", primary: 784, secondary: nil,
                                   annotation: "Tiny patches preserve more detail, but attention cost rises fast because every token compares with every other token."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a bar. Patch size is the tradeoff between visual detail and attention cost."
                )),
                caption: "ViT turns a picture into a token sequence. Patch size decides how long that sequence gets.",
                takeaway: "The image is not scanned first. It is tokenised first."
            ),
            DLVizCard(
                kicker: "CARD 06 · DATA SCALE",
                titleSegments: [
                    .plain("Transformers need "),
                    .highlight("lots of images")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "ImageNet accuracy pattern",
                    primaryLabel: "Performance",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Small", sublabel: "limited data", primary: 62, secondary: nil,
                                   annotation: "With modest data, convolutional networks often win because their image bias is helpful."),
                        DLBarPoint(label: "Large", sublabel: "pretrain", primary: 84, secondary: nil,
                                   annotation: "With large pretraining, ViT catches up and then becomes very strong."),
                        DLBarPoint(label: "Huge", sublabel: "scale", primary: 90, secondary: nil,
                                   annotation: "At very large scale, the flexible Transformer pays off."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "pretrain",
                    defaultInsight: "Tap a bar. ViT's weakness on small data becomes strength once pretraining is large enough."
                )),
                caption: "The paper's lesson was not just architecture. It was architecture plus scale.",
                takeaway: "ViT trades built-in vision bias for flexibility, then buys the difference with data."
            ),
        ],

        completeTakeaway: "\"A picture can become a sequence, and attention can learn the scene.\"",
        completeNextTease: "Up next: CLIP, where images and words learn one shared map.",
        paperTitle: "An Image is Worth 16x16 Words: Transformers for Image Recognition at Scale",
        glossary: [
            "patch": "A square chunk of an image treated like one token.",
            "position embedding": "A learned marker that tells the model where a token came from.",
            "self-attention": "A mechanism where every token compares itself with every other token.",
            "convolution": "A sliding filter that scans nearby pixels, the classic building block of vision models.",
            "pretraining": "Training on a large broad dataset before adapting to a specific task.",
        ],
        learningObjectives: [
            DLObjective(text: "How images become tokens", gloss: "Patches play the same role as words."),
            DLObjective(text: "Why positions matter", gloss: "Flattening loses the image grid unless position is added."),
            DLObjective(text: "Why scale unlocked ViT", gloss: "Less built-in bias needs more pretraining data."),
        ],
        paperURL: "https://arxiv.org/abs/2010.11929"
    )

    // MARK: CLIP

    static let clip = DailyLoopContent(
        heroEyebrow: "VISION · LANGUAGE",
        heroTitleSegments: [
            .plain("Images and words meet "),
            .highlight("on one map")
        ],
        heroBody: "CLIP learned from internet image-caption pairs until pictures and text landed in the same embedding space.",
        sourceLine: "arXiv:2103.00020 · OpenAI",

        hookSegments: [
            .plain("How do you search photos with "),
            .highlight("ordinary words"),
            .plain("?")
        ],
        hookBody: "You can type \"a dog wearing sunglasses\" and expect a photo app to find it. That feels normal now, but it requires a model to know that a sentence and an image can point to the same idea. CLIP made that bridge by training on noisy image-caption pairs from the web.",

        coreIdeaSegments: [
            .plain("The trick is "),
            .highlight("matching pairs")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Encode the image",
                detail: "An image encoder turns a picture into a vector, a point on a high-dimensional map."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Encode the text",
                detail: "A text encoder turns its caption into another vector on the same map."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Pull matches together",
                detail: "The real image-caption pair is pulled close. All the mismatched captions in the batch are pushed away."),
        ],

        eliAnalogyLabel: "ANALOGY · A TWO-LANGUAGE ATLAS",
        eliHeadlineSegments: [
            .plain("Like a map where "),
            .highlight("photos and captions share streets")
        ],
        eliBodyParts: [
            .plain("Imagine a city map where one person places photos and another places captions. If "),
            .bold("red bicycle"),
            .plain(" and the actual bike photo land on the same corner, search becomes simple: find the nearest neighbor."),
        ],
        eliArt: .map,

        diagramSegments: [
            .plain("How CLIP "),
            .highlight("aligns two worlds")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "image", label: "Image", sublabel: "encoder",
                          panelTitle: "Image encoder · seeing",
                          panelBody: "The image side turns pixels into a vector. Similar images should end up nearby."),
            DLDiagramNode(id: "text", label: "Text", sublabel: "encoder",
                          panelTitle: "Text encoder · naming",
                          panelBody: "The text side turns captions into vectors in the same space as the image vectors."),
            DLDiagramNode(id: "contrast", label: "Contrast", sublabel: "match",
                          panelTitle: "Contrastive loss · the game",
                          panelBody: "For each batch, the correct image-caption pair is the match. Every other pairing is a negative example."),
            DLDiagramNode(id: "map", label: "Shared map", sublabel: "zero-shot",
                          panelTitle: "Shared map · the payoff",
                          panelBody: "Once images and captions share a map, a new label can work without training a new classifier."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four pieces create one shared image-text space. Tap each one.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE BATCH GAME",
                titleSegments: [
                    .plain("One match, "),
                    .highlight("many decoys")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "similarity score",
                    primaryLabel: "Score",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Dog", sublabel: "correct", primary: 92, secondary: nil,
                                   annotation: "The real caption should score highest for this image."),
                        DLBarPoint(label: "Car", sublabel: "decoy", primary: 18, secondary: nil,
                                   annotation: "A mismatched caption is pushed away."),
                        DLBarPoint(label: "Soup", sublabel: "decoy", primary: 9, secondary: nil,
                                   annotation: "Another mismatch, another push away."),
                        DLBarPoint(label: "Beach", sublabel: "decoy", primary: 14, secondary: nil,
                                   annotation: "The model learns from lots of wrong pairings at once."),
                    ],
                    cliffIndex: 0,
                    cliffLabel: "match",
                    defaultInsight: "Tap a bar. CLIP learns by making the true pair outrank every wrong pair in the batch."
                )),
                caption: "A single batch creates many negative examples for free.",
                takeaway: "CLIP learns meaning by contrast: this caption, not those."
            ),
            DLVizCard(
                kicker: "CARD 06 · ZERO-SHOT CLASSIFYING",
                titleSegments: [
                    .plain("Labels become "),
                    .highlight("prompts")
                ],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "photo", label: "Photo", sublabel: "image vector", role: .input,
                                       panelTitle: "Photo",
                                       panelBody: "The image is encoded once into the shared space.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "prompts", label: "Prompts", sublabel: "a photo of ...", role: .process,
                                       panelTitle: "Prompt labels",
                                       panelBody: "Each possible label is written as text, like \"a photo of a dog\".",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "nearest", label: "Nearest", sublabel: "highest match", role: .process,
                                       panelTitle: "Nearest text",
                                       panelBody: "The model compares the photo vector to every text vector.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "label", label: "Label", sublabel: "dog", role: .output,
                                       panelTitle: "Zero-shot label",
                                       panelBody: "The closest text prompt becomes the prediction, even if no classifier was trained for that exact task.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "photo", to: "nearest", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "prompts", to: "nearest", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "nearest", to: "label", label: "pick", kind: .forward),
                    ],
                    defaultInsight: "Tap a box. CLIP can classify by comparing an image with text prompts."
                )),
                caption: "Zero-shot classification is just nearest-neighbor search between one image and many label prompts.",
                takeaway: "Once words and images share a map, labels can be written instead of trained."
            ),
        ],

        completeTakeaway: "\"CLIP did not learn one fixed label list. It learned a bridge between seeing and naming.\"",
        completeNextTease: "Up next: Chinchilla, the scaling-law correction that changed how labs spend compute.",
        paperTitle: "Learning Transferable Visual Models From Natural Language Supervision",
        glossary: [
            "embedding space": "A map of vectors where nearby points mean similar things.",
            "contrastive loss": "A training objective that pulls matching pairs together and pushes mismatches apart.",
            "zero-shot": "Doing a task without training specifically on that task's examples.",
            "encoder": "A model component that turns an input into a vector representation.",
            "negative example": "A deliberately wrong pairing used to teach the model what does not match.",
        ],
        learningObjectives: [
            DLObjective(text: "How image-text matching works", gloss: "Two encoders place images and captions on one map."),
            DLObjective(text: "Why contrast teaches meaning", gloss: "Correct pairs move together, decoys move apart."),
            DLObjective(text: "Why zero-shot works", gloss: "New labels can be written as prompts."),
        ],
        paperURL: "https://arxiv.org/abs/2103.00020"
    )

    // MARK: Chinchilla

    static let chinchilla = DailyLoopContent(
        heroEyebrow: "LANGUAGE · SCALING",
        heroTitleSegments: [
            .plain("Bigger models needed "),
            .highlight("more words")
        ],
        heroBody: "Chinchilla showed many large language models were undertrained: too many parameters, too little data for the compute being spent.",
        sourceLine: "arXiv:2203.15556 · DeepMind",

        hookSegments: [
            .plain("If you buy a bigger brain, "),
            .highlight("should you also buy more books"),
            .plain("?")
        ],
        hookBody: "Early scaling races mostly asked how many parameters a model had. Chinchilla reframed the budget. If your compute is fixed, making the model larger is only half the purchase. You also need enough training tokens, or the big model never gets enough practice.",

        coreIdeaSegments: [
            .plain("The compute budget has "),
            .highlight("two knobs")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Parameters are capacity",
                detail: "More parameters give the model more room to store patterns, but capacity alone does not teach it."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Tokens are practice",
                detail: "More training tokens give the model more examples. Chinchilla found earlier large models had not seen enough text."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Balance beats brute size",
                detail: "For the same compute, a smaller model trained on more data can beat a much larger undertrained one."),
        ],

        eliAnalogyLabel: "ANALOGY · A STUDENT AND A LIBRARY",
        eliHeadlineSegments: [
            .plain("A genius still needs "),
            .highlight("homework")
        ],
        eliBodyParts: [
            .plain("Imagine two students. One has a huge notebook but only reads a few pages. The other has a smaller notebook and works through the whole library. Chinchilla says the second student often learns more, because "),
            .bold("practice"),
            .plain(" was the missing ingredient."),
        ],
        eliArt: .librarian,

        diagramSegments: [
            .plain("How Chinchilla "),
            .highlight("spends compute")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "budget", label: "Compute", sublabel: "fixed",
                          panelTitle: "Compute · the budget",
                          panelBody: "Training spend is limited. The question is how to divide it between model size and data size."),
            DLDiagramNode(id: "params", label: "Params", sublabel: "capacity",
                          panelTitle: "Parameters · memory for patterns",
                          panelBody: "A larger model can represent more patterns, but each parameter still needs enough examples to become useful."),
            DLDiagramNode(id: "tokens", label: "Tokens", sublabel: "practice",
                          panelTitle: "Tokens · examples to learn from",
                          panelBody: "Training tokens are practice problems. More tokens let the model refine its weights instead of staying undertrained."),
            DLDiagramNode(id: "balance", label: "Balance", sublabel: "optimal",
                          panelTitle: "Balance · the Chinchilla point",
                          panelBody: "The best model for a compute budget balances parameters and tokens instead of spending everything on size."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four pieces explain compute-optimal training. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · SAME COMPUTE",
                titleSegments: [
                    .plain("Smaller, "),
                    .highlight("better trained")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "relative downstream score",
                    primaryLabel: "Score",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Gopher", sublabel: "280B", primary: 78, secondary: nil,
                                   annotation: "A very large model, but comparatively undertrained for its compute budget."),
                        DLBarPoint(label: "Chinchilla", sublabel: "70B", primary: 88, secondary: nil,
                                   annotation: "Four times smaller, trained on far more tokens, and stronger across many tasks."),
                        DLBarPoint(label: "Too small", sublabel: "limited", primary: 64, secondary: nil,
                                   annotation: "If the model is too small, extra data cannot fully compensate."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "balanced",
                    defaultInsight: "Tap a bar. Chinchilla wins by spending compute on more data, not more parameters."
                )),
                caption: "The headline result: a 70B model trained properly beat a 280B model trained too briefly.",
                takeaway: "Undertrained giant models were wasting compute."
            ),
            DLVizCard(
                kicker: "CARD 06 · THE RATIO",
                titleSegments: [
                    .plain("Size and data should "),
                    .highlight("grow together")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "training tokens per parameter →",
                    yAxisLabel: "loss improves ↑",
                    xTickLabels: ["too few", "balanced", "too many"],
                    yTickLabels: ["low", "", "high"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Compute-optimal",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.25, milestone: "starved",
                                                     annotation: "Too few tokens per parameter leaves the model undertrained."),
                                DLTrainingCurvePoint(x: 0.5, y: 0.92, milestone: "sweet spot",
                                                     annotation: "The Chinchilla-style balance gives each parameter enough practice."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.72, milestone: "data-heavy",
                                                     annotation: "Past the balance point, the model may be too small to absorb all that data efficiently."),
                            ]),
                    ],
                    defaultInsight: "Tap a point. The goal is not maximum size or maximum data, but the best balance for the compute."
                )),
                caption: "A sketch of the compute-optimal idea: parameters and tokens need to scale together.",
                takeaway: "Scaling laws became a budgeting rule, not just a bragging contest."
            ),
        ],

        completeTakeaway: "\"For a fixed training budget, the smartest model is the one with enough parameters and enough practice.\"",
        completeNextTease: "Up next: PaLM, where scale returns with a better recipe.",
        paperTitle: "Training Compute-Optimal Large Language Models",
        glossary: [
            "parameter": "A learned number inside a model. More parameters usually mean more capacity.",
            "token": "A chunk of text the model trains on, often a word piece.",
            "compute": "The total training calculation budget, usually measured in floating-point operations.",
            "scaling law": "A rule that predicts how model performance changes with size, data, and compute.",
            "undertrained": "A model with many parameters but too few training tokens for those parameters to learn well.",
        ],
        learningObjectives: [
            DLObjective(text: "Why bigger was not enough", gloss: "Large models needed more tokens to use their capacity."),
            DLObjective(text: "How compute gets split", gloss: "Training budget is divided between size and data."),
            DLObjective(text: "What compute-optimal means", gloss: "Best performance for the same spend."),
        ],
        paperURL: "https://arxiv.org/abs/2203.15556"
    )

    // MARK: DDPM

    static let ddpm = DailyLoopContent(
        heroEyebrow: "VISION · DIFFUSION",
        heroTitleSegments: [
            .plain("Make an image by "),
            .highlight("removing noise")
        ],
        heroBody: "DDPM taught image generation as a cleanup game: add noise until pictures vanish, then learn to reverse the mess one tiny step at a time.",
        sourceLine: "arXiv:2006.11239 · Ho et al.",

        hookSegments: [
            .plain("Can you recover a picture from "),
            .highlight("static"),
            .plain("?")
        ],
        hookBody: "Imagine taking a photo and adding a little TV static. Then more. Then more, until nothing recognizable remains. DDPM trains a model on both directions: first a fixed path that destroys images into noise, then a learned path that removes the noise back into an image.",

        coreIdeaSegments: [
            .plain("Diffusion is "),
            .highlight("reverse corruption")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Add noise in known steps",
                           detail: "The forward process slowly corrupts a real image with Gaussian noise. This part is fixed and easy to compute."),
            DLCoreIdeaItem(roman: "ii", title: "Predict the noise",
                           detail: "The model sees a noisy image and a timestep, then predicts what noise was added at that step."),
            DLCoreIdeaItem(roman: "iii", title: "Denoise from pure static",
                           detail: "At generation time, start with random noise and repeatedly subtract predicted noise until an image appears."),
        ],

        eliAnalogyLabel: "ANALOGY · RESTORING A SMUDGED DRAWING",
        eliHeadlineSegments: [
            .plain("Like cleaning a sketch "),
            .highlight("one smudge at a time")
        ],
        eliBodyParts: [
            .plain("A diffusion model is not drawing from a blank page. It starts with a page covered in smudges and learns the tiny cleanup moves that make the hidden picture sharper after every pass."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [
            .plain("How DDPM "),
            .highlight("runs backward")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "clean", label: "Clean", sublabel: "x0",
                          panelTitle: "Clean image",
                          panelBody: "Training starts with a real image from the dataset."),
            DLDiagramNode(id: "noise", label: "Noise", sublabel: "q step",
                          panelTitle: "Forward noising",
                          panelBody: "A known process adds a little Gaussian noise at each timestep until the image becomes random static."),
            DLDiagramNode(id: "predict", label: "Predict", sublabel: "epsilon",
                          panelTitle: "Predict the added noise",
                          panelBody: "The neural network learns to identify the noise component inside the noisy image."),
            DLDiagramNode(id: "sample", label: "Sample", sublabel: "reverse",
                          panelTitle: "Reverse into an image",
                          panelBody: "Sampling starts from pure noise and applies the learned cleanup step again and again."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four pieces make diffusion feel less magical. Tap each one.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE TIMELINE",
                titleSegments: [.plain("Noise rises, "), .highlight("image fades")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "noise level",
                    primaryLabel: "Noise",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "t0", sublabel: "clean", primary: 0, secondary: nil,
                                   annotation: "At the start, the training image is clean."),
                        DLBarPoint(label: "t250", sublabel: "fuzzy", primary: 35, secondary: nil,
                                   annotation: "Noise has softened the image but structure remains."),
                        DLBarPoint(label: "t750", sublabel: "hidden", primary: 75, secondary: nil,
                                   annotation: "Only faint structure remains. The model still gets trained to predict the noise."),
                        DLBarPoint(label: "t1000", sublabel: "static", primary: 100, secondary: nil,
                                   annotation: "At the end, the image is basically pure Gaussian noise."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a step. Training teaches the model the whole path from picture to static."
                )),
                caption: "The forward process is simple. The learned model is the reverse process.",
                takeaway: "Generation is the noising movie played backward."
            ),
            DLVizCard(
                kicker: "CARD 06 · THE CLEANUP LOOP",
                titleSegments: [.plain("Many tiny fixes "), .highlight("beat one big guess")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "start", label: "Random", sublabel: "noise", role: .input,
                                       panelTitle: "Start from noise",
                                       panelBody: "A sample begins as random pixels, not as a sketch.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "step", label: "Denoise", sublabel: "one step", role: .process,
                                       panelTitle: "One learned cleanup",
                                       panelBody: "The model predicts the noise at the current timestep and removes a small amount.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "repeat", label: "Repeat", sublabel: "hundreds", role: .process,
                                       panelTitle: "Repeat the same move",
                                       panelBody: "The same denoising skill is applied many times, with the timestep telling the model how noisy the image still is.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "image", label: "Image", sublabel: "sample", role: .output,
                                       panelTitle: "Generated image",
                                       panelBody: "After enough small cleanups, a coherent image emerges.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "start", to: "step", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "step", to: "repeat", label: "again", kind: .forward),
                        DLFlowRichEdge(from: "repeat", to: "image", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. DDPM samples by repeating one denoising move many times."
                )),
                caption: "Diffusion generation is iterative by design, which made early models slow but stable.",
                takeaway: "The model learns a small correction, then compounds it into a picture."
            ),
        ],

        completeTakeaway: "\"Diffusion makes images by learning how to undo noise.\"",
        completeNextTease: "Up next: Stable Diffusion, the same idea moved into a smaller latent space.",
        paperTitle: "Denoising Diffusion Probabilistic Models",
        glossary: [
            "diffusion": "A generation method that learns to reverse a gradual noising process.",
            "Gaussian noise": "Random noise shaped like a normal distribution.",
            "timestep": "The position on the noise schedule, telling the model how corrupted the image is.",
            "denoising": "Removing predicted noise from a noisy image.",
            "sampling": "Generating a new image by running the reverse process.",
        ],
        learningObjectives: [
            DLObjective(text: "Why noising helps", gloss: "A simple corruption path creates a learnable reverse path."),
            DLObjective(text: "What the model predicts", gloss: "It predicts the noise, not the whole image at once."),
            DLObjective(text: "How sampling works", gloss: "Start from static, denoise step by step."),
        ],
        paperURL: "https://arxiv.org/abs/2006.11239"
    )

    // MARK: Stable Diffusion

    static let stableDiffusion = DailyLoopContent(
        heroEyebrow: "VISION · LATENT DIFFUSION",
        heroTitleSegments: [
            .plain("Diffusion gets "),
            .highlight("small enough to ship")
        ],
        heroBody: "Stable Diffusion made image generation practical by denoising compressed latent images instead of full pixel grids.",
        sourceLine: "arXiv:2112.10752 · Rombach et al.",

        hookSegments: [
            .plain("Why clean every pixel when you can clean "),
            .highlight("the sketch"),
            .plain("?")
        ],
        hookBody: "Pixel diffusion works, but it is expensive because every denoising step touches every pixel. Latent Diffusion first compresses the image into a smaller representation, runs diffusion there, then decodes the result back into pixels. Same cleanup story, much cheaper room to work in.",

        coreIdeaSegments: [
            .plain("Stable Diffusion has "),
            .highlight("three rooms")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Compress the image",
                           detail: "An autoencoder turns pixels into a compact latent map that keeps the important visual structure."),
            DLCoreIdeaItem(roman: "ii", title: "Denoise the latent",
                           detail: "The diffusion model works in that smaller space, so each step costs far less."),
            DLCoreIdeaItem(roman: "iii", title: "Guide it with text",
                           detail: "A text encoder conditions the denoising process so the generated image follows the prompt."),
        ],

        eliAnalogyLabel: "ANALOGY · RENOVATING THE BLUEPRINT",
        eliHeadlineSegments: [.plain("Edit the blueprint, "), .highlight("then build the house")],
        eliBodyParts: [
            .plain("Instead of repainting a whole building brick by brick, Stable Diffusion works on the blueprint. Change the compact plan first, then render the finished building from it."),
        ],
        eliArt: .map,

        diagramSegments: [.plain("How Stable Diffusion "), .highlight("saves work")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "prompt", label: "Prompt", sublabel: "text",
                          panelTitle: "Prompt",
                          panelBody: "Text supplies the direction: astronaut, watercolor, city at night, or whatever the user asks for."),
            DLDiagramNode(id: "latent", label: "Latent", sublabel: "small map",
                          panelTitle: "Latent space",
                          panelBody: "The image lives as a compressed feature map, smaller than pixels but still visually meaningful."),
            DLDiagramNode(id: "denoise", label: "Denoise", sublabel: "U-Net",
                          panelTitle: "Latent denoising",
                          panelBody: "A U-Net repeatedly removes noise from the latent map while listening to the text condition."),
            DLDiagramNode(id: "decode", label: "Decode", sublabel: "pixels",
                          panelTitle: "Decode to pixels",
                          panelBody: "The autoencoder decoder turns the cleaned latent back into a full image."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Stable Diffusion is DDPM plus compression plus text control. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · WHERE THE SAVINGS COME FROM",
                titleSegments: [.plain("Denoise fewer "), .highlight("numbers")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "relative working grid",
                    primaryLabel: "Grid size",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Pixels", sublabel: "full image", primary: 100, secondary: nil,
                                   annotation: "Pixel diffusion works directly on the full image grid."),
                        DLBarPoint(label: "Latent", sublabel: "compressed", primary: 6, secondary: nil,
                                   annotation: "Latent diffusion works on a much smaller representation, so denoising is far cheaper."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "cheap",
                    defaultInsight: "Tap a bar. The key saving is moving diffusion into a compressed space."
                )),
                caption: "The model spends most of its time in the compact latent map, not the full pixel canvas.",
                takeaway: "Compression made diffusion practical."
            ),
            DLVizCard(
                kicker: "CARD 06 · TEXT CONTROL",
                titleSegments: [.plain("The prompt steers "), .highlight("each cleanup")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "words", label: "Words", sublabel: "encoder", role: .input,
                                       panelTitle: "Text encoder",
                                       panelBody: "The prompt becomes conditioning vectors the image model can attend to.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "noise", label: "Noisy latent", sublabel: "step t", role: .input,
                                       panelTitle: "Noisy latent",
                                       panelBody: "The current image state is still noisy, but it is already in the compact latent space.",
                                       column: 0, row: 1),
                        DLFlowRichNode(id: "unet", label: "U-Net", sublabel: "guided", role: .process,
                                       panelTitle: "Guided denoiser",
                                       panelBody: "The denoiser combines the noisy latent, the timestep, and the text condition.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "cleaner", label: "Cleaner", sublabel: "latent", role: .output,
                                       panelTitle: "Cleaner latent",
                                       panelBody: "One step closer to a prompt-matching image.",
                                       column: 2, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "words", to: "unet", label: "condition", kind: .forward),
                        DLFlowRichEdge(from: "noise", to: "unet", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "unet", to: "cleaner", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. The text prompt guides the denoising step, not just the final image."
                )),
                caption: "Text conditioning is threaded through the repeated cleanup process.",
                takeaway: "The prompt acts like a steering signal at every step."
            ),
        ],

        completeTakeaway: "\"Stable Diffusion made diffusion small enough to run outside the biggest labs.\"",
        completeNextTease: "Up next: ControlNet, where extra structure steers the same generation process.",
        paperTitle: "High-Resolution Image Synthesis with Latent Diffusion Models",
        glossary: [
            "latent": "A compressed representation that keeps important structure while using fewer numbers.",
            "autoencoder": "A model that compresses data and then reconstructs it.",
            "U-Net": "A neural network shape often used for image-to-image prediction.",
            "conditioning": "Extra information, such as text, that guides generation.",
            "decoder": "The part that turns the latent representation back into pixels.",
        ],
        learningObjectives: [
            DLObjective(text: "Why latent space matters", gloss: "It makes denoising much cheaper."),
            DLObjective(text: "How prompts guide images", gloss: "Text conditions every denoising step."),
            DLObjective(text: "Why this changed access", gloss: "Smaller compute made high-quality generation widely usable."),
        ],
        paperURL: "https://arxiv.org/abs/2112.10752"
    )

    // MARK: T5

    static let t5 = DailyLoopContent(
        heroEyebrow: "LANGUAGE · TEXT-TO-TEXT",
        heroTitleSegments: [.plain("Every language task becomes "), .highlight("text in, text out")],
        heroBody: "T5 unified translation, summarization, classification, and question answering by casting every task as text-to-text.",
        sourceLine: "arXiv:1910.10683 · Raffel et al.",

        hookSegments: [.plain("What if every homework question used "), .highlight("one answer box"), .plain("?")],
        hookBody: "Before T5, different NLP tasks often used different heads and formats. Translation produced text. Classification produced labels. Question answering pointed to spans. T5 flattened the mess: write a task prefix, feed in text, and train the model to output text.",

        coreIdeaSegments: [.plain("One format, "), .highlight("many tasks")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Prefix the task",
                           detail: "Inputs start with instructions like translate English to German, summarize, or answer question."),
            DLCoreIdeaItem(roman: "ii", title: "Use one encoder-decoder model",
                           detail: "The encoder reads the input text, and the decoder writes the output text."),
            DLCoreIdeaItem(roman: "iii", title: "Pretrain by filling spans",
                           detail: "Instead of masking single tokens like BERT, T5 removes chunks of text and asks the model to generate the missing spans."),
        ],

        eliAnalogyLabel: "ANALOGY · ONE UNIVERSAL WORKSHEET",
        eliHeadlineSegments: [.plain("Same worksheet, "), .highlight("different prompts")],
        eliBodyParts: [
            .plain("Imagine a teacher gives every assignment on the same worksheet. The top line says translate, summarize, or classify. The student reads the prompt and writes the answer in the same box every time."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [.plain("How T5 "), .highlight("standardises NLP")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "prefix", label: "Prefix", sublabel: "task",
                          panelTitle: "Task prefix",
                          panelBody: "A short phrase tells the model what job to do."),
            DLDiagramNode(id: "input", label: "Input", sublabel: "text",
                          panelTitle: "Input text",
                          panelBody: "The actual sentence, document, or question comes after the task prefix."),
            DLDiagramNode(id: "model", label: "T5", sublabel: "encoder-decoder",
                          panelTitle: "Text-to-text Transformer",
                          panelBody: "One encoder-decoder Transformer handles all tasks through the same interface."),
            DLDiagramNode(id: "output", label: "Output", sublabel: "text",
                          panelTitle: "Output text",
                          panelBody: "The answer is always generated text, whether it is a sentence, label, or number."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four pieces turn many NLP tasks into one interface. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · MANY JOBS",
                titleSegments: [.plain("Different tasks, "), .highlight("same doorway")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "format complexity removed",
                    primaryLabel: "Unification",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Translate", sublabel: "text", primary: 92, secondary: nil,
                                   annotation: "Translation already fits text-to-text naturally."),
                        DLBarPoint(label: "Summarize", sublabel: "text", primary: 90, secondary: nil,
                                   annotation: "Summarization becomes another output string."),
                        DLBarPoint(label: "Classify", sublabel: "label", primary: 85, secondary: nil,
                                   annotation: "Even classification is written as text, such as positive or negative."),
                        DLBarPoint(label: "QA", sublabel: "answer", primary: 88, secondary: nil,
                                   annotation: "Question answering becomes generating the answer text."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a task. T5 makes each one use the same input-output format."
                )),
                caption: "The contribution is partly architectural and partly product-thinking: one clean API for NLP.",
                takeaway: "Text-to-text made transfer learning simpler to reason about."
            ),
            DLVizCard(
                kicker: "CARD 06 · SPAN CORRUPTION",
                titleSegments: [.plain("Hide chunks, "), .highlight("regenerate them")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "sentence", label: "Sentence", sublabel: "original", role: .input,
                                       panelTitle: "Original text",
                                       panelBody: "Start with ordinary text from a large corpus.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "mask", label: "Sentinels", sublabel: "<extra_id>", role: .process,
                                       panelTitle: "Span corruption",
                                       panelBody: "Remove whole spans and replace them with special sentinel tokens.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "generate", label: "Generate", sublabel: "missing spans", role: .process,
                                       panelTitle: "Generate missing text",
                                       panelBody: "The decoder learns to write the missing spans in order.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "learn", label: "Transfer", sublabel: "many tasks", role: .output,
                                       panelTitle: "Transfer",
                                       panelBody: "This pretraining gives the model broad language skill before task-specific fine tuning.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "sentence", to: "mask", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "mask", to: "generate", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "generate", to: "learn", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. T5 pretraining hides spans and trains the model to generate them."
                )),
                caption: "Span corruption teaches both understanding and generation in the same model.",
                takeaway: "T5 learns by reconstructing missing pieces of text."
            ),
        ],

        completeTakeaway: "\"T5 turned NLP into one sentence-shaped interface.\"",
        completeNextTease: "Up next: Chinchilla, where scale gets a stricter budget.",
        paperTitle: "Exploring the Limits of Transfer Learning with a Unified Text-to-Text Transformer",
        glossary: [
            "text-to-text": "A setup where both the input and output are text strings.",
            "encoder-decoder": "A model with one part that reads and another part that writes.",
            "task prefix": "Instruction text placed before the input to tell the model what to do.",
            "span corruption": "A pretraining task where chunks of text are removed and regenerated.",
            "transfer learning": "Using knowledge learned from one broad training setup on many downstream tasks.",
        ],
        learningObjectives: [
            DLObjective(text: "Why one format helps", gloss: "Every task shares the same model interface."),
            DLObjective(text: "How prefixes steer tasks", gloss: "Short instructions tell the model what output to write."),
            DLObjective(text: "What span corruption teaches", gloss: "Regenerating chunks builds broad language skill."),
        ],
        paperURL: "https://arxiv.org/abs/1910.10683"
    )

    // MARK: LLaMA

    static let llama = DailyLoopContent(
        heroEyebrow: "LANGUAGE · OPEN WEIGHTS",
        heroTitleSegments: [.plain("Smaller models, "), .highlight("trained harder")],
        heroBody: "LLaMA showed that carefully trained open-weight models could punch far above their parameter count.",
        sourceLine: "arXiv:2302.13971 · Meta AI",

        hookSegments: [.plain("What if the secret was not bigger, but "), .highlight("better trained"), .plain("?")],
        hookBody: "After GPT-3, model size became the headline. LLaMA took a different path: train smaller models on many more tokens, use strong data and modern Transformer details, then release the weights to researchers. The result made capable language models much easier to study and adapt.",

        coreIdeaSegments: [.plain("LLaMA's recipe is "), .highlight("efficient scale")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "More tokens per parameter",
                           detail: "The models were trained on far more text than older similarly sized models, following the Chinchilla lesson."),
            DLCoreIdeaItem(roman: "ii", title: "Modern Transformer details",
                           detail: "RMSNorm, SwiGLU, and rotary position embeddings made the architecture cleaner and stronger."),
            DLCoreIdeaItem(roman: "iii", title: "Open weights changed the ecosystem",
                           detail: "Researchers could fine tune, inspect, compress, and run capable models locally."),
        ],

        eliAnalogyLabel: "ANALOGY · A COMPACT ATHLETE",
        eliHeadlineSegments: [.plain("Not the biggest body, "), .highlight("the best training camp")],
        eliBodyParts: [
            .plain("LLaMA is like a smaller athlete with excellent coaching, endless drills, and a clean routine. It beats larger rivals that looked impressive but did not get enough practice."),
        ],
        eliArt: .bouncer,

        diagramSegments: [.plain("How LLaMA "), .highlight("punches up")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "data", label: "Data", sublabel: "tokens",
                          panelTitle: "More training tokens",
                          panelBody: "LLaMA trains smaller models longer, so each parameter gets more practice."),
            DLDiagramNode(id: "arch", label: "Architecture", sublabel: "modern",
                          panelTitle: "Modern Transformer tweaks",
                          panelBody: "Small architectural choices improve stability and efficiency without changing the basic language-model loop."),
            DLDiagramNode(id: "weights", label: "Weights", sublabel: "released",
                          panelTitle: "Released weights",
                          panelBody: "Open weights let the research community build directly on the model instead of only querying an API."),
            DLDiagramNode(id: "adapt", label: "Adapt", sublabel: "fine tune",
                          panelTitle: "Adaptation wave",
                          panelBody: "Fine-tuned descendants made local chat models, instruction models, and domain models explode in popularity."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "LLaMA is a recipe: train efficiently, release weights, let adaptation happen. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · SIZE IS NOT EVERYTHING",
                titleSegments: [.plain("Fewer parameters, "), .highlight("more practice")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "relative capability",
                    primaryLabel: "Capability",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "13B", sublabel: "well trained", primary: 72, secondary: nil,
                                   annotation: "A smaller LLaMA model could compete with much larger older models."),
                        DLBarPoint(label: "33B", sublabel: "strong", primary: 84, secondary: nil,
                                   annotation: "More size plus the same efficient training recipe improved results."),
                        DLBarPoint(label: "65B", sublabel: "frontier-ish", primary: 92, secondary: nil,
                                   annotation: "The largest LLaMA approached models that were much bigger but less compute-optimal."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a model. The story is not raw size, it is training quality per parameter."
                )),
                caption: "Representative pattern from the paper: LLaMA models competed above their weight class.",
                takeaway: "Efficient training made smaller models matter again."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHY OPEN WEIGHTS MATTER",
                titleSegments: [.plain("Release the weights, "), .highlight("multiply the lab")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "base", label: "Base model", sublabel: "LLaMA", role: .input,
                                       panelTitle: "Base model",
                                       panelBody: "The pretrained model contains broad language ability but is not yet a polished assistant.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "fine", label: "Fine tune", sublabel: "task data", role: .process,
                                       panelTitle: "Fine tune",
                                       panelBody: "Researchers can specialize the weights for chat, code, medicine, or a private dataset.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "compress", label: "Compress", sublabel: "local", role: .process,
                                       panelTitle: "Compress",
                                       panelBody: "Quantization and distillation make the model cheaper to run.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "ecosystem", label: "Ecosystem", sublabel: "many models", role: .output,
                                       panelTitle: "Ecosystem",
                                       panelBody: "Open weights let thousands of derivatives appear quickly.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "base", to: "fine", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "fine", to: "compress", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "compress", to: "ecosystem", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. LLaMA mattered technically and socially because the weights could be reused."
                )),
                caption: "The release model turned one paper into a whole open model ecosystem.",
                takeaway: "Open weights made frontier-ish capability hackable."
            ),
        ],

        completeTakeaway: "\"LLaMA made capable language models feel reachable.\"",
        completeNextTease: "Up next: Mixtral, where only part of the model wakes up for each token.",
        paperTitle: "LLaMA: Open and Efficient Foundation Language Models",
        glossary: [
            "open weights": "Model parameters released so others can run and adapt the model.",
            "parameter": "A learned number inside a model.",
            "fine tune": "Continue training a model on a smaller task-specific dataset.",
            "rotary position embedding": "A way to encode token position inside attention.",
            "quantization": "Compressing model weights into fewer bits so inference is cheaper.",
        ],
        learningObjectives: [
            DLObjective(text: "Why LLaMA was efficient", gloss: "More tokens per parameter improved capability."),
            DLObjective(text: "What open weights unlocked", gloss: "Researchers could adapt the model directly."),
            DLObjective(text: "Why smaller models mattered", gloss: "They became strong enough to run and customize."),
        ],
        paperURL: "https://arxiv.org/abs/2302.13971"
    )

    // MARK: Reflexion

    static let reflexion = DailyLoopContent(
        heroEyebrow: "REASONING · AGENTS",
        heroTitleSegments: [.plain("After failing, "), .highlight("write the lesson down")],
        heroBody: "Reflexion gives an agent a verbal memory of what went wrong, so the next attempt starts wiser.",
        sourceLine: "arXiv:2303.11366 · Shinn et al.",

        hookSegments: [.plain("What do you do after bombing a test? "), .highlight("You review the mistake"), .plain(".")],
        hookBody: "A normal model can fail, get a score, and try again with no lasting lesson. Reflexion adds a simple habit: after each attempt, the agent writes a short reflection about what went wrong and stores it in memory. The next attempt reads that note before acting.",

        coreIdeaSegments: [.plain("Reflexion adds "), .highlight("verbal memory")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Act in the world",
                           detail: "The agent tries a task, such as coding, web navigation, or question answering."),
            DLCoreIdeaItem(roman: "ii", title: "Evaluate the attempt",
                           detail: "An external signal says whether the attempt worked, failed, or partly succeeded."),
            DLCoreIdeaItem(roman: "iii", title: "Reflect before retrying",
                           detail: "The model writes a natural-language lesson and includes that memory in the next prompt."),
        ],

        eliAnalogyLabel: "ANALOGY · A NOTEBOOK OF MISTAKES",
        eliHeadlineSegments: [.plain("Like keeping a "), .highlight("mistake journal")],
        eliBodyParts: [
            .plain("After a bad chess game, you might write: stop moving the queen out early. Next game, that note changes your choices. Reflexion gives agents the same kind of notebook."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [.plain("How Reflexion "), .highlight("learns without weight updates")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "try", label: "Try", sublabel: "act",
                          panelTitle: "Try the task",
                          panelBody: "The agent produces actions or an answer using its current prompt."),
            DLDiagramNode(id: "score", label: "Score", sublabel: "feedback",
                          panelTitle: "Score the result",
                          panelBody: "A test, environment, or evaluator marks the attempt as success or failure."),
            DLDiagramNode(id: "reflect", label: "Reflect", sublabel: "lesson",
                          panelTitle: "Write a reflection",
                          panelBody: "The model turns the failure into a short natural-language note about what to change."),
            DLDiagramNode(id: "memory", label: "Memory", sublabel: "next try",
                          panelTitle: "Use memory next time",
                          panelBody: "The next prompt includes the reflection, so behavior changes without retraining the model weights."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Reflexion is a loop of try, score, reflect, remember. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · WHAT IMPROVES",
                titleSegments: [.plain("Memory turns failure into "), .highlight("signal")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "task success pattern",
                    primaryLabel: "Success",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "No note", sublabel: "repeat", primary: 35, secondary: nil,
                                   annotation: "Without memory, the agent may repeat the same mistake."),
                        DLBarPoint(label: "Reflection", sublabel: "learn", primary: 68, secondary: nil,
                                   annotation: "A useful verbal lesson changes the next attempt."),
                        DLBarPoint(label: "Bad note", sublabel: "noise", primary: 42, secondary: nil,
                                   annotation: "Reflection only helps if the note captures the real failure."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "lesson",
                    defaultInsight: "Tap a bar. Reflexion helps when feedback can be turned into a useful memory."
                )),
                caption: "The key move is converting outcome feedback into a reusable instruction.",
                takeaway: "Reflection is memory, not magic."
            ),
            DLVizCard(
                kicker: "CARD 06 · NO RETRAINING",
                titleSegments: [.plain("The weights stay still, "), .highlight("the prompt changes")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "weights", label: "Weights", sublabel: "same model", role: .input,
                                       panelTitle: "Same model",
                                       panelBody: "Reflexion does not update the neural network parameters.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "note", label: "Note", sublabel: "memory", role: .process,
                                       panelTitle: "Verbal memory",
                                       panelBody: "A reflection is stored as text and added to the next prompt.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "prompt", label: "Prompt", sublabel: "augmented", role: .process,
                                       panelTitle: "Augmented prompt",
                                       panelBody: "The next attempt sees the task plus the previous lesson.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "better", label: "Better try", sublabel: "adapted", role: .output,
                                       panelTitle: "Behavior changes",
                                       panelBody: "The model can avoid a repeated error even though its weights did not change.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "weights", to: "prompt", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "note", to: "prompt", label: "add", kind: .forward),
                        DLFlowRichEdge(from: "prompt", to: "better", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. Reflexion adapts through text memory instead of gradient updates."
                )),
                caption: "This is why Reflexion fits agents: the lesson can be written, stored, retrieved, and revised.",
                takeaway: "Agents can improve across attempts by changing context."
            ),
        ],

        completeTakeaway: "\"Reflexion turns a failed attempt into a note the next attempt can use.\"",
        completeNextTease: "Up next: deeper agent memory, planning, and tool loops.",
        paperTitle: "Reflexion: Language Agents with Verbal Reinforcement Learning",
        glossary: [
            "agent": "A model-driven system that can act, observe results, and continue.",
            "reflection": "A natural-language note about what went wrong or what to try next.",
            "verbal reinforcement learning": "Improving behavior through text feedback and memory rather than weight updates.",
            "memory": "Stored context from earlier attempts that can be added to a future prompt.",
            "evaluator": "A test or judge that scores whether the attempt succeeded.",
        ],
        learningObjectives: [
            DLObjective(text: "Why failure can help", gloss: "Feedback becomes a reusable written lesson."),
            DLObjective(text: "How memory changes behavior", gloss: "The next prompt includes the reflection."),
            DLObjective(text: "Why no retraining is needed", gloss: "The model adapts through context."),
        ],
        paperURL: "https://arxiv.org/abs/2303.11366"
    )

    // MARK: ControlNet

    static let controlNet = DailyLoopContent(
        heroEyebrow: "VISION · CONTROL",
        heroTitleSegments: [.plain("Tell diffusion "), .highlight("where things go")],
        heroBody: "ControlNet adds a trainable side network that lets sketches, poses, edges, and depth maps steer a frozen diffusion model.",
        sourceLine: "arXiv:2302.05543 · Zhang et al.",

        hookSegments: [.plain("A prompt says what. A sketch says "), .highlight("where"), .plain(".")],
        hookBody: "Text-to-image models are great at style and subject, but weak at exact layout. Ask for a person in a certain pose and the model may improvise. ControlNet fixes that by giving diffusion an extra control signal, such as a pose skeleton or edge map, while preserving the pretrained image model underneath.",

        coreIdeaSegments: [.plain("ControlNet adds "), .highlight("a steering copy")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Keep the base model frozen",
                           detail: "The original diffusion model keeps its image knowledge instead of being overwritten."),
            DLCoreIdeaItem(roman: "ii", title: "Train a control branch",
                           detail: "A copied branch learns how to read structure inputs like edges, depth, poses, or scribbles."),
            DLCoreIdeaItem(roman: "iii", title: "Inject control at each block",
                           detail: "Zero-initialized connections let the control branch guide generation without breaking the base model at the start."),
        ],

        eliAnalogyLabel: "ANALOGY · COLORING INSIDE A STENCIL",
        eliHeadlineSegments: [.plain("The model paints, "), .highlight("the stencil holds shape")],
        eliBodyParts: [
            .plain("A prompt is like telling someone to paint a dancer. ControlNet is handing them a stencil of the dancer's pose. The painting can still be creative, but the body lands where the stencil says."),
        ],
        eliArt: .magnifier,

        diagramSegments: [.plain("How ControlNet "), .highlight("steers diffusion")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "condition", label: "Control", sublabel: "pose or edge",
                          panelTitle: "Control input",
                          panelBody: "A structure image provides layout information the prompt cannot specify precisely."),
            DLDiagramNode(id: "frozen", label: "Frozen", sublabel: "base",
                          panelTitle: "Frozen diffusion model",
                          panelBody: "The pretrained model keeps its broad image generation skill."),
            DLDiagramNode(id: "branch", label: "Branch", sublabel: "trainable",
                          panelTitle: "Trainable control branch",
                          panelBody: "A parallel branch learns how the control input should influence each layer."),
            DLDiagramNode(id: "image", label: "Image", sublabel: "guided",
                          panelTitle: "Guided image",
                          panelBody: "The result follows both the prompt and the supplied structure."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "ControlNet is a steering layer for diffusion. Tap each part.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · CONTROL TYPES",
                titleSegments: [.plain("Different maps, "), .highlight("different control")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "layout precision",
                    primaryLabel: "Control",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Pose", sublabel: "body", primary: 92, secondary: nil,
                                   annotation: "A skeleton can lock character posture."),
                        DLBarPoint(label: "Edges", sublabel: "outline", primary: 86, secondary: nil,
                                   annotation: "An edge map preserves object boundaries and composition."),
                        DLBarPoint(label: "Depth", sublabel: "space", primary: 78, secondary: nil,
                                   annotation: "A depth map guides foreground, background, and 3D structure."),
                        DLBarPoint(label: "Scribble", sublabel: "rough", primary: 62, secondary: nil,
                                   annotation: "Even a rough sketch can steer the image while leaving room for interpretation."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a control type. Each one constrains a different part of the image."
                )),
                caption: "ControlNet turned image generation from prompt-only guessing into structure-guided creation.",
                takeaway: "The control image anchors layout."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHY ZERO CONVS",
                titleSegments: [.plain("Start with "), .highlight("no damage")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "base", label: "Base", sublabel: "good images", role: .input,
                                       panelTitle: "Pretrained base",
                                       panelBody: "The original diffusion model already knows how to make good images.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "zero", label: "Zero conv", sublabel: "starts silent", role: .process,
                                       panelTitle: "Zero-initialized connection",
                                       panelBody: "The control branch starts with no effect, so training begins safely.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "learn", label: "Learn", sublabel: "control", role: .process,
                                       panelTitle: "Gradual control",
                                       panelBody: "As training proceeds, the side branch learns how strongly to steer each block.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "guided", label: "Guided", sublabel: "stable", role: .output,
                                       panelTitle: "Stable control",
                                       panelBody: "The model gains structure control without forgetting image quality.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "base", to: "zero", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "zero", to: "learn", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "learn", to: "guided", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. Zero connections let ControlNet learn steering without disrupting the base model."
                )),
                caption: "The clever engineering detail is starting the control path silent, then letting it grow.",
                takeaway: "Control is added gently, not forced all at once."
            ),
        ],

        completeTakeaway: "\"ControlNet gives diffusion a steering wheel for structure.\"",
        completeNextTease: "Up next: Segment Anything, where one click can select almost any object.",
        paperTitle: "Adding Conditional Control to Text-to-Image Diffusion Models",
        glossary: [
            "control signal": "An extra input, such as a pose or edge map, that guides image generation.",
            "frozen model": "A model whose weights are kept unchanged during training.",
            "zero convolution": "A connection initialized to output zero so it starts with no effect.",
            "conditioning": "Extra information that guides a generative model.",
            "edge map": "An image that marks object boundaries and outlines.",
        ],
        learningObjectives: [
            DLObjective(text: "Why prompts are not enough", gloss: "Text struggles with exact layout."),
            DLObjective(text: "How the side branch helps", gloss: "It reads structure while the base model stays intact."),
            DLObjective(text: "Why zero starts safe", gloss: "Control grows without damaging the pretrained model."),
        ],
        paperURL: "https://arxiv.org/abs/2302.05543"
    )

    // MARK: Segment Anything

    static let segmentAnything = DailyLoopContent(
        heroEyebrow: "VISION · SEGMENTATION",
        heroTitleSegments: [.plain("Click anything, "), .highlight("cut it out")],
        heroBody: "SAM made image segmentation promptable: click, box, or mask an object, and the model returns a clean segment.",
        sourceLine: "arXiv:2304.02643 · Meta AI",

        hookSegments: [.plain("What if Photoshop's magic wand worked on "), .highlight("almost anything"), .plain("?")],
        hookBody: "Segmentation means drawing the exact pixels that belong to an object. Old models were usually trained for specific categories. SAM reframed segmentation as a promptable task: give the model a point, box, or rough mask, and it predicts the object you meant.",

        coreIdeaSegments: [.plain("SAM separates "), .highlight("image understanding from prompting")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Encode the image once",
                           detail: "A large vision encoder turns the image into reusable features."),
            DLCoreIdeaItem(roman: "ii", title: "Encode the prompt",
                           detail: "A point, box, or mask tells the model what object the user is asking about."),
            DLCoreIdeaItem(roman: "iii", title: "Decode possible masks",
                           detail: "A lightweight decoder outputs candidate masks and scores their quality."),
        ],

        eliAnalogyLabel: "ANALOGY · POINTING AT A SHOP WINDOW",
        eliHeadlineSegments: [.plain("You point, "), .highlight("it understands the object")],
        eliBodyParts: [
            .plain("If you point at a jacket in a crowded shop window, a person knows you mean the jacket, not the glass or the mannequin. SAM gives a model that same pointing interface for images."),
        ],
        eliArt: .magnifier,

        diagramSegments: [.plain("How SAM "), .highlight("answers a click")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "image", label: "Image", sublabel: "encoder",
                          panelTitle: "Image encoder",
                          panelBody: "The model computes rich visual features for the full image."),
            DLDiagramNode(id: "prompt", label: "Prompt", sublabel: "point or box",
                          panelTitle: "Prompt encoder",
                          panelBody: "The user prompt tells the model which region or object matters."),
            DLDiagramNode(id: "decoder", label: "Decoder", sublabel: "mask",
                          panelTitle: "Mask decoder",
                          panelBody: "A fast decoder combines image features and prompt features to propose masks."),
            DLDiagramNode(id: "score", label: "Score", sublabel: "quality",
                          panelTitle: "Mask score",
                          panelBody: "SAM can return multiple masks when the prompt is ambiguous, then score them."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "SAM is image features plus prompt features plus a mask decoder. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · PROMPT TYPES",
                titleSegments: [.plain("Different hints, "), .highlight("same task")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "prompt specificity",
                    primaryLabel: "Specificity",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Point", sublabel: "quick", primary: 45, secondary: nil,
                                   annotation: "A single click is fast, but sometimes ambiguous."),
                        DLBarPoint(label: "Box", sublabel: "bounded", primary: 75, secondary: nil,
                                   annotation: "A box narrows the object region."),
                        DLBarPoint(label: "Mask", sublabel: "rough", primary: 92, secondary: nil,
                                   annotation: "A rough mask gives the strongest hint."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a prompt. More specific prompts usually reduce ambiguity."
                )),
                caption: "Promptable segmentation lets the same model serve many editing and annotation workflows.",
                takeaway: "The user supplies intent with a tiny prompt."
            ),
            DLVizCard(
                kicker: "CARD 06 · DATA ENGINE",
                titleSegments: [.plain("The model improved by "), .highlight("labeling with humans")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "model", label: "Model", sublabel: "suggests", role: .input,
                                       panelTitle: "Model proposes masks",
                                       panelBody: "SAM's team used model-assisted labeling to speed up annotation.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "human", label: "Human", sublabel: "corrects", role: .process,
                                       panelTitle: "Human correction",
                                       panelBody: "Annotators corrected masks, creating better training data.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "data", label: "Data", sublabel: "SA-1B", role: .process,
                                       panelTitle: "Huge mask dataset",
                                       panelBody: "The loop produced SA-1B, a billion-mask dataset.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "better", label: "Better SAM", sublabel: "general", role: .output,
                                       panelTitle: "Better model",
                                       panelBody: "More varied masks improved segmentation across new images.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "model", to: "human", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "human", to: "data", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "data", to: "better", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. SAM is also a data-engine paper: model and annotators improved each other."
                )),
                caption: "The dataset-building loop mattered as much as the architecture.",
                takeaway: "General segmentation came from promptability plus massive mask data."
            ),
        ],

        completeTakeaway: "\"SAM turned segmentation into a promptable interface.\"",
        completeNextTease: "Up next: language scaling, where bigger models start showing new behaviors.",
        paperTitle: "Segment Anything",
        glossary: [
            "segmentation": "Marking exactly which pixels belong to an object or region.",
            "mask": "A pixel-level selection of an object.",
            "promptable": "Able to respond to user hints like points, boxes, or masks.",
            "decoder": "The model component that turns features into the final mask.",
            "SA-1B": "The billion-mask dataset introduced with SAM.",
        ],
        learningObjectives: [
            DLObjective(text: "What segmentation means", gloss: "It selects exact object pixels."),
            DLObjective(text: "How prompts guide SAM", gloss: "Points, boxes, and masks tell it what you mean."),
            DLObjective(text: "Why data mattered", gloss: "Huge mask data made the model general."),
        ],
        paperURL: "https://arxiv.org/abs/2304.02643"
    )

    // MARK: PaLM

    static let palm = DailyLoopContent(
        heroEyebrow: "LANGUAGE · SCALE",
        heroTitleSegments: [.plain("Scale made abilities "), .highlight("show up")],
        heroBody: "PaLM scaled a dense Transformer to 540B parameters and highlighted abilities that appeared more clearly at large scale.",
        sourceLine: "arXiv:2204.02311 · Chowdhery et al.",

        hookSegments: [.plain("Some skills only appear after "), .highlight("enough practice"), .plain(".")],
        hookBody: "A child might know words, then sentences, then suddenly jokes and explanations start to work. PaLM studied a similar curve in language models: as size and training grew, capabilities like reasoning, code, and multilingual transfer became much stronger.",

        coreIdeaSegments: [.plain("PaLM is about "), .highlight("large-scale capability")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "A very large dense model",
                           detail: "PaLM used 540 billion parameters in one dense Transformer, trained on a broad multilingual corpus."),
            DLCoreIdeaItem(roman: "ii", title: "Pathways made training possible",
                           detail: "Google's Pathways system coordinated training across thousands of accelerator chips."),
            DLCoreIdeaItem(roman: "iii", title: "Emergent behaviors became visible",
                           detail: "Some tasks improved slowly with scale, while others showed sharper jumps at larger sizes."),
        ],

        eliAnalogyLabel: "ANALOGY · A CITY GETS PUBLIC TRANSIT",
        eliHeadlineSegments: [.plain("At small size, roads work. At city size, "), .highlight("new patterns appear")],
        eliBodyParts: [
            .plain("A tiny town has streets. A giant city needs subways, stations, and rush hour patterns. PaLM is a reminder that scaling a system can create behavior you would not notice in the small version."),
        ],
        eliArt: .map,

        diagramSegments: [.plain("What PaLM "), .highlight("scaled")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "data", label: "Data", sublabel: "broad",
                          panelTitle: "Broad data",
                          panelBody: "The model trained on multilingual web text, books, code, and other sources."),
            DLDiagramNode(id: "params", label: "Params", sublabel: "540B",
                          panelTitle: "Model size",
                          panelBody: "A dense 540B-parameter Transformer gave the model huge capacity."),
            DLDiagramNode(id: "system", label: "Pathways", sublabel: "TPUs",
                          panelTitle: "Training system",
                          panelBody: "The engineering system distributed training across many chips."),
            DLDiagramNode(id: "skills", label: "Skills", sublabel: "emerge",
                          panelTitle: "Capabilities",
                          panelBody: "Reasoning, code, and multilingual behavior became stronger with scale."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "PaLM is a scale story across data, parameters, systems, and abilities. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · SIZE CURVE",
                titleSegments: [.plain("Some scores climb "), .highlight("late")],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "model scale →",
                    yAxisLabel: "task performance ↑",
                    xTickLabels: ["small", "medium", "PaLM"],
                    yTickLabels: ["low", "", "high"],
                    series: [
                        DLTrainingCurveSeries(label: "Smooth tasks", color: .teal, dashed: false,
                                              points: [
                                                DLTrainingCurvePoint(x: 0.0, y: 0.25, milestone: "small",
                                                                     annotation: "Many language tasks improve gradually with scale."),
                                                DLTrainingCurvePoint(x: 0.5, y: 0.58, milestone: "medium",
                                                                     annotation: "Bigger models steadily improve."),
                                                DLTrainingCurvePoint(x: 1.0, y: 0.82, milestone: "large",
                                                                     annotation: "PaLM pushes the curve higher."),
                                              ]),
                        DLTrainingCurveSeries(label: "Emergent tasks", color: .amber, dashed: true,
                                              points: [
                                                DLTrainingCurvePoint(x: 0.0, y: 0.05, milestone: nil,
                                                                     annotation: "Some tasks look near impossible at small scale."),
                                                DLTrainingCurvePoint(x: 0.5, y: 0.12, milestone: nil,
                                                                     annotation: "They remain weak for a while."),
                                                DLTrainingCurvePoint(x: 1.0, y: 0.68, milestone: "jump",
                                                                     annotation: "At large enough scale, performance can rise sharply."),
                                              ]),
                    ],
                    defaultInsight: "Tap a point. PaLM made scale-linked capability jumps hard to ignore."
                )),
                caption: "The exact curves vary by task, but the lesson is stable: scale changes what a model can do.",
                takeaway: "Scale can reveal abilities, not just improve old ones."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHAT HAD TO SCALE",
                titleSegments: [.plain("Not just model size, "), .highlight("the whole stack")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "required scale",
                    primaryLabel: "Scale",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Data", sublabel: "corpus", primary: 82, secondary: nil,
                                   annotation: "Large models need broad data to learn from."),
                        DLBarPoint(label: "Params", sublabel: "capacity", primary: 100, secondary: nil,
                                   annotation: "PaLM's headline number was 540B parameters."),
                        DLBarPoint(label: "Compute", sublabel: "TPUs", primary: 96, secondary: nil,
                                   annotation: "Training required huge distributed compute."),
                        DLBarPoint(label: "Eval", sublabel: "tasks", primary: 75, secondary: nil,
                                   annotation: "The paper measured many tasks to see where scale helped."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap a bar. PaLM was an entire scaling stack, not just a big checkpoint."
                )),
                caption: "Large language models are systems papers as much as model papers.",
                takeaway: "Capability came from scaling data, model, compute, and evaluation together."
            ),
        ],

        completeTakeaway: "\"PaLM made the scale story impossible to ignore.\"",
        completeNextTease: "Up next: LLaMA, where strong open-weight models made scale more accessible.",
        paperTitle: "PaLM: Scaling Language Modeling with Pathways",
        glossary: [
            "dense model": "A model where all parameters are active for each token, unlike a sparse expert model.",
            "emergent ability": "A capability that appears or improves sharply at larger scale.",
            "parameter": "A learned number inside a model.",
            "Pathways": "Google's distributed training system used for PaLM.",
            "multilingual": "Working across multiple languages.",
        ],
        learningObjectives: [
            DLObjective(text: "What PaLM scaled", gloss: "Data, parameters, compute, and evaluations."),
            DLObjective(text: "Why emergence mattered", gloss: "Some abilities appeared strongly only at large scale."),
            DLObjective(text: "Why systems matter", gloss: "Training required a coordinated compute stack."),
        ],
        paperURL: "https://arxiv.org/abs/2204.02311"
    )

    // MARK: Mixtral

    static let mixtral = DailyLoopContent(
        heroEyebrow: "LANGUAGE · EXPERTS",
        heroTitleSegments: [.plain("A big model where only "), .highlight("some experts wake up")],
        heroBody: "Mixtral uses a sparse mixture of experts so each token activates only a small part of a much larger model.",
        sourceLine: "arXiv:2401.04088 · Mistral AI",

        hookSegments: [.plain("Why ask the whole committee when "), .highlight("two specialists"), .plain(" will do?")],
        hookBody: "A normal dense model runs the same full network for every token. Mixtral has multiple expert feed-forward networks and a router. For each token, the router chooses the top experts, so the model has lots of total knowledge but only pays for part of it each time.",

        coreIdeaSegments: [.plain("Mixtral is "), .highlight("sparse expertise")],
        coreIdeaItems: [
            DLCoreIdeaItem(roman: "i", title: "Many experts exist",
                           detail: "Each layer has several expert networks that can specialize in different patterns."),
            DLCoreIdeaItem(roman: "ii", title: "A router picks a few",
                           detail: "For each token, a learned router sends the token to the most relevant experts."),
            DLCoreIdeaItem(roman: "iii", title: "Compute stays lower",
                           detail: "Only selected experts run, so active parameters are much smaller than total parameters."),
        ],

        eliAnalogyLabel: "ANALOGY · A HELP DESK WITH SPECIALISTS",
        eliHeadlineSegments: [.plain("Route each question to "), .highlight("the right desks")],
        eliBodyParts: [
            .plain("A help desk might have billing, hardware, travel, and security specialists. You do not ask everyone every question. A router sends each request to the two people most likely to know."),
        ],
        eliArt: .librarian,

        diagramSegments: [.plain("How Mixtral "), .highlight("routes tokens")],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "token", label: "Token", sublabel: "input",
                          panelTitle: "Incoming token",
                          panelBody: "Each token reaches a mixture-of-experts layer."),
            DLDiagramNode(id: "router", label: "Router", sublabel: "top 2",
                          panelTitle: "Router",
                          panelBody: "A small learned router scores experts and picks the best few for this token."),
            DLDiagramNode(id: "experts", label: "Experts", sublabel: "sparse",
                          panelTitle: "Selected experts",
                          panelBody: "Only the chosen experts process the token."),
            DLDiagramNode(id: "combine", label: "Combine", sublabel: "output",
                          panelTitle: "Combine outputs",
                          panelBody: "The expert outputs are weighted and merged before the model continues."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Mixtral is a routing trick inside Transformer layers. Tap each piece.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · TOTAL VS ACTIVE",
                titleSegments: [.plain("Lots of parameters, "), .highlight("fewer active")],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "parameters involved",
                    primaryLabel: "Parameters",
                    secondaryLabel: nil,
                    yMax: 50,
                    yTickLabels: ["0", "25B", "50B"],
                    points: [
                        DLBarPoint(label: "Total", sublabel: "all experts", primary: 47, secondary: nil,
                                   annotation: "Mixtral has roughly 47B total parameters across all experts."),
                        DLBarPoint(label: "Active", sublabel: "per token", primary: 13, secondary: nil,
                                   annotation: "Only around 13B parameters are active for each token."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "cheap path",
                    defaultInsight: "Tap a bar. Sparse experts separate total capacity from per-token compute."
                )),
                caption: "This is the core advantage: big capacity without paying full dense-model cost on every token.",
                takeaway: "Sparse routing buys capacity with lower active compute."
            ),
            DLVizCard(
                kicker: "CARD 06 · ROUTING",
                titleSegments: [.plain("Each token chooses "), .highlight("its specialists")],
                visualization: .flowRich(DLFlowRichSpec(
                    layout: .horizontal,
                    nodes: [
                        DLFlowRichNode(id: "word", label: "Token", sublabel: "question", role: .input,
                                       panelTitle: "Token",
                                       panelBody: "The current token needs processing by the feed-forward part of the layer.",
                                       column: 0, row: 0),
                        DLFlowRichNode(id: "gate", label: "Gate", sublabel: "scores", role: .process,
                                       panelTitle: "Expert gate",
                                       panelBody: "The router scores which experts seem useful for this token.",
                                       column: 1, row: 0),
                        DLFlowRichNode(id: "top", label: "Top experts", sublabel: "2 of 8", role: .process,
                                       panelTitle: "Top experts",
                                       panelBody: "Only the best-scoring experts run.",
                                       column: 2, row: 0),
                        DLFlowRichNode(id: "merge", label: "Merge", sublabel: "weighted", role: .output,
                                       panelTitle: "Weighted merge",
                                       panelBody: "The selected expert outputs are combined into the layer output.",
                                       column: 3, row: 0),
                    ],
                    edges: [
                        DLFlowRichEdge(from: "word", to: "gate", label: nil, kind: .forward),
                        DLFlowRichEdge(from: "gate", to: "top", label: "choose", kind: .forward),
                        DLFlowRichEdge(from: "top", to: "merge", label: nil, kind: .forward),
                    ],
                    defaultInsight: "Tap a box. The router decides which small slice of the big model runs."
                )),
                caption: "Mixture-of-experts models are conditional compute: different tokens can take different paths.",
                takeaway: "The route is learned, token by token."
            ),
        ],

        completeTakeaway: "\"Mixtral separates model capacity from active compute.\"",
        completeNextTease: "Up next: agent loops that remember, search, and act.",
        paperTitle: "Mixtral of Experts",
        glossary: [
            "mixture of experts": "A model layer with several specialist networks and a router that picks which ones run.",
            "router": "A learned gate that sends each token to selected experts.",
            "sparse": "Only part of the model activates for each input.",
            "active parameters": "The parameters actually used for a token.",
            "dense model": "A model where the same full set of parameters runs for every token.",
        ],
        learningObjectives: [
            DLObjective(text: "Why experts help", gloss: "Capacity can grow without all parts running every time."),
            DLObjective(text: "How routing works", gloss: "A gate picks the best experts per token."),
            DLObjective(text: "What active compute means", gloss: "Only selected parameters do work."),
        ],
        paperURL: "https://arxiv.org/abs/2401.04088"
    )
}
