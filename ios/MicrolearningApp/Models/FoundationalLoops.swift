import Foundation
import SwiftUI

// MARK: - Foundational Bundle · Per-Paper Daily Loop Content
//
// Eight curated DailyLoopContent entries for the foundational papers that
// don't have a backend blueprint. Card 04 (the interactive nodes-and-edges
// diagram) is bespoke per paper, drawn from the corresponding card in
// `Aprecis-Bundle-Offline.html`. Other cards stay compact but render the full
// 7-card loop end-to-end.
//
// Routing: `BundleDetailView` consults `DailyLoopContent.foundational(slug:)`
// before falling back to the legacy paper deck. Published loop ids live in
// `CuratedPaperCatalog.interactiveLoopPaperIds`; do not duplicate that list elsewhere.
//
// Premium studios (cards 04, 05, 06 fully bespoke): perceptron, backprop,
// lenet, alexnet, word2vec, seq2seq, gans, resnet, attention/transformer, gpt3.
// `DailyLoopView` detects these by paper title and routes to the matching
// `*StudioViews.swift` file. The DLVizCard / diagramNodes content below those
// slots is left in place but is only used as a fallback if the title check
// ever misses.

extension DailyLoopContent {

    static func foundational(slug: String) -> DailyLoopContent? {
        var content: DailyLoopContent?
        switch slug {
        case "perceptron": content = .perceptron
        case "backprop":   content = .backprop
        case "lenet":      content = .lenet
        case "alexnet":    content = .alexnet
        case "word2vec":   content = .word2vec
        case "seq2seq":    content = .seq2seq
        case "gans":       content = .gans
        case "resnet":     content = .resnet
        case "attention":  content = .transformer
        case "gpt3":       content = .gpt3
        case "bert":       content = .bert
        default:           return nil
        }
        // Merge FoundationalGlossaries into the loop's inline glossary.
        // Existing entries on the literal (e.g. the rich GPT-3 set) win,
        // because they tend to be longer / more paper-specific. Anything
        // not already defined gets the curated FoundationalGlossaries
        // definition so inline terms light up in the body copy.
        if var c = content {
            let extra = FoundationalGlossaries.dict(for: slug)
            var merged = c.glossary
            for (k, v) in extra where merged[k] == nil {
                merged[k] = v
            }
            c.glossary = merged
            return c
        }
        return nil
    }

    // MARK: Perceptron (Rosenblatt 1958)

    static let perceptron = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · NEURONS",
        heroTitleSegments: [
            .plain("The first machine that "),
            .highlight("learned from examples")
        ],
        heroBody: "One tiny artificial neuron that could learn from its own mistakes. The seed every neural network grew from.",
        sourceLine: "Psychological Review 1958 · Frank Rosenblatt",

        hookSegments: [
            .plain("What if a machine could "),
            .highlight("teach itself"),
            .plain(" the right answer?")
        ],
        hookBody: "Before this, computers needed a programmer to spell out every rule. The Perceptron took a handful of inputs, weighed each one, and fired if the total crossed a threshold, then nudged its own weights whenever it got things wrong. It was the first machine that improved with practice. Across this loop you'll watch one neuron decide, see where a single line cannot go, and meet the wall that stalled the field for a decade.",

        coreIdeaSegments: [
            .plain("Three pieces, "),
            .highlight("one decision")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Inputs become a weighted vote",
                detail: "Each input xᵢ multiplies a learned weight wᵢ. The sum Σ wᵢxᵢ is one number that summarises the entire input through the neuron's lens of importance."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "A threshold turns the vote into a decision",
                detail: "If the sum crosses θ, output 1 (fire). Otherwise, output 0. The decision boundary is the hyperplane where the sum exactly equals the threshold."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Mistakes nudge the weights",
                detail: "On every misclassification, push the weights toward the correct answer: w ← w + η(y − ŷ)x. Repeat. If the data is linearly separable, the rule is guaranteed to converge."),
        ],

        eliAnalogyLabel: "ANALOGY · A NIGHTCLUB BOUNCER",
        eliHeadlineSegments: [
            .plain("Imagine a bouncer with "),
            .highlight("a clipboard"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("Each guest brings "),
            .bold("traits"),
            .plain(" (age, dress, sobriety). The bouncer assigns "),
            .bold("weights"),
            .plain(" to each trait, sums them, and lets you in if the total clears a threshold. After every regretted decision, the bouncer "),
            .bold("adjusts the weights"),
            .plain(". After enough nights, the door is consistent. That's the perceptron."),
        ],
        eliArt: .bouncer,

        diagramSegments: [
            .plain("How one neuron "),
            .highlight("makes a call")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "x", label: "Inputs", sublabel: "xᵢ",
                          panelTitle: "Inputs · the features",
                          panelBody: "Each xᵢ is one piece of evidence. A pixel value, a sensor reading, a feature in a vector. The neuron sees the world through this list of numbers."),
            DLDiagramNode(id: "w", label: "Weights", sublabel: "wᵢ",
                          panelTitle: "Weights · learned importance",
                          panelBody: "Each wᵢ is the importance the neuron places on its input. Negative weights argue against firing. Learning is just adjusting these numbers."),
            DLDiagramNode(id: "sum", label: "Sum", sublabel: "Σ wᵢxᵢ",
                          panelTitle: "Sum · a single scalar",
                          panelBody: "Pairwise multiply, add. The result is one number that compresses everything the neuron has been told."),
            DLDiagramNode(id: "out", label: "Step", sublabel: "fire if > θ",
                          panelTitle: "Step · the decision",
                          panelBody: "If the sum clears the threshold θ, output 1 (fire). Otherwise, output 0. One yes-or-no vote per neuron."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four parts of a single perceptron. Tap each to read its role.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE WALL",
                titleSegments: [
                    .plain("Two it can do, "),
                    .highlight("one it cannot")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Epochs to converge",
                    primaryLabel: "Linearly separable",
                    secondaryLabel: nil,
                    yMax: 20,
                    yTickLabels: ["0", "10", "∞"],
                    points: [
                        DLBarPoint(label: "AND", sublabel: "separable", primary: 4, secondary: nil,
                                   annotation: "AND truth table is linearly separable. Perceptron settles in 4 epochs."),
                        DLBarPoint(label: "OR",  sublabel: "separable", primary: 3, secondary: nil,
                                   annotation: "OR is also linearly separable. The boundary slides closer to the origin."),
                        DLBarPoint(label: "XOR", sublabel: "fails",     primary: 20, secondary: nil,
                                   annotation: "XOR cannot be separated by any straight line. Minsky and Papert proved this in 1969 and the field went quiet for a decade."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "wall",
                    defaultInsight: "Tap each problem. The third needs a hidden layer, which is where backprop will come in."
                )),
                caption: "Three logical functions. The first two converge in a handful of epochs. XOR oscillates forever.",
                takeaway: "A line cannot separate the diagonal. Depth is the answer."
            ),
            DLVizCard(
                kicker: "CARD 06 · ONE NEURON",
                titleSegments: [
                    .plain("Five parts, "),
                    .highlight("one vote")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Component",
                    primaryLabel: "Role",
                    secondaryLabel: nil,
                    yMax: 1,
                    yTickLabels: ["", "", ""],
                    points: [
                        DLBarPoint(label: "x",  sublabel: "inputs",     primary: 0.4, secondary: nil, annotation: "Features come in. The neuron sees the world only through these numbers."),
                        DLBarPoint(label: "w",  sublabel: "weights",    primary: 0.6, secondary: nil, annotation: "Learned importance. Adjusting these is the entire act of learning."),
                        DLBarPoint(label: "Σ",  sublabel: "sum",        primary: 0.7, secondary: nil, annotation: "Σ wᵢxᵢ collapses the input list to a single number."),
                        DLBarPoint(label: "θ",  sublabel: "threshold",  primary: 0.5, secondary: nil, annotation: "If the sum crosses the threshold, fire. Otherwise stay silent."),
                        DLBarPoint(label: "y",  sublabel: "output",     primary: 1.0, secondary: nil, annotation: "0 or 1. The neuron has voted. Stack a few thousand and you have a network."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap each piece. Stack a few hundred neurons in layers and you have a deep network."
                )),
                caption: "The five parts of one neuron, repeated identically across an entire network.",
                takeaway: "One vote, repeated billions of times, is a brain."
            ),
        ],

        completeTakeaway: "\"All later neural networks are just very deep perceptrons.\"",
        completeNextTease: "Up next: backprop, the algorithm that lets perceptrons stack.",
        paperTitle: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
        learningObjectives: [
            DLObjective(
                text: "How one neuron turns inputs into a yes or no",
                gloss: "Σ wᵢxᵢ against a threshold θ, the entire decision rule on one line."),
            DLObjective(
                text: "Why the learning rule actually converges",
                gloss: "On linearly separable data, every mistake nudges weights closer to a working boundary."),
            DLObjective(
                text: "Where a single line cannot go, and what fixes it",
                gloss: "XOR is the wall. Stacking neurons into hidden layers is the way through."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Four parts, "),
                .highlight("one decision boundary"),
            ],
            mini: .perceptron,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · WEIGHTED VOTE",
                    body: "You watched each input xᵢ get multiplied by a learned weight wᵢ and added together. That single number, Σ wᵢxᵢ, is the neuron's view of the whole input. Negative weights argue against firing, positive ones argue for it, and the magnitude says how loudly."),
                DLExplanationPara(
                    kicker: "P2 · THE THRESHOLD",
                    body: "The step function compared that sum to θ. Above, it fires (1). Below, it stays silent (0). Geometrically the threshold is a flat boundary in input space, on one side of the boundary the neuron says yes, on the other it says no."),
                DLExplanationPara(
                    kicker: "P3 · WHEN IT FAILS",
                    body: "Because the boundary is a straight line (or flat hyperplane), the perceptron can only solve problems where one straight line separates the classes. AND and OR pass, XOR does not. That is exactly the wall Minsky and Papert proved in 1969."),
            ],
            takeaway: "One line, one vote. Stack a few thousand and you have a brain."
        ),
        paperURL: "https://psycnet.apa.org/doi/10.1037/h0042519"
    )

    // MARK: Backprop (Rumelhart, Hinton, Williams 1986)

    static let backprop = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · TRAINING",
        heroTitleSegments: [
            .plain("One algorithm taught "),
            .highlight("hidden layers to learn")
        ],
        heroBody: "The trick that lets a deep network figure out which inner part caused the mistake, then nudge each one to do better next time.",
        sourceLine: "Nature 1986 · Rumelhart, Hinton, Williams",

        hookSegments: [
            .plain("What if every weight in a deep network "),
            .highlight("knew its own blame"),
            .plain("?")
        ],
        hookBody: "Before 1986, hidden layers were a black box. No one could tell a buried weight whether it had helped or hurt the final prediction. Backprop solved it with one move: walk the chain rule backward from the loss, layer by layer, and hand each weight its share of the error. Across this loop you'll see why deep nets couldn't learn before, how the chain rule fixed it, and the one algorithm that still trains every model on Earth.",

        coreIdeaSegments: [
            .plain("Three steps, "),
            .highlight("end to end")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Forward, compute the prediction",
                detail: "Activations propagate left to right. Each layer takes its input, applies its weights and nonlinearity, and hands the result to the next layer."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Compare prediction to truth",
                detail: "A loss function measures how wrong the prediction is. For mean-squared error, ∂L/∂ŷ has a closed form: just the prediction gap, signed."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Backward, walk the chain rule",
                detail: "Right to left, multiply local derivatives. ∂L/∂w₁ = ∂L/∂y · ∂y/∂h · ∂h/∂w₁. Each weight gets its blame; SGD updates them all in one stroke."),
        ],

        eliAnalogyLabel: "ANALOGY · A KITCHEN POSTMORTEM",
        eliHeadlineSegments: [
            .plain("Imagine asking, "),
            .highlight("who burnt the dish?"),
        ],
        eliBodyParts: [
            .plain("A bad meal lands at the table. The head chef tastes it and assigns "),
            .bold("blame backward"),
            .plain(": the plater overcooked, the saucier oversalted, the prep cook chopped wrong. Each cook hears their share. Tomorrow they each adjust. That's backprop, "),
            .bold("blame walks the chain"),
            .plain(", and every weight learns from one error signal."),
        ],
        eliArt: .exoskeleton,

        diagramSegments: [
            .plain("Forward, "),
            .highlight("then backward")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(id: "x", label: "Input", sublabel: "x",
                          panelTitle: "Input · constant for the pass",
                          panelBody: "The data point. Treated as a constant during this forward and backward pass; gradients stop here because the input itself is not learned."),
            DLDiagramNode(id: "h", label: "Hidden", sublabel: "h = σ(W₁x)",
                          panelTitle: "Hidden · the learned representation",
                          panelBody: "The hidden layer applies its weights and a nonlinearity. Backprop will hand it ∂L/∂h on the return trip and ask it to update W₁."),
            DLDiagramNode(id: "y", label: "Output", sublabel: "ŷ = W₂h",
                          panelTitle: "Output · the prediction",
                          panelBody: "The final layer projects the hidden representation onto the prediction space. ∂L/∂ŷ is the easiest gradient to compute, the loss is right next door."),
            DLDiagramNode(id: "L", label: "Loss", sublabel: "L(ŷ, y)",
                          panelTitle: "Loss · the error signal",
                          panelBody: "The scalar to minimise. Backprop starts here and walks the chain rule backward to every weight in the network."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four nodes of a tiny network. Tap each to see how forward and backward differ.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · ONE RULE, COMPOSED",
                titleSegments: [
                    .plain("Just the chain rule, "),
                    .highlight("repeated")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "|∂L/∂w₁|",
                    primaryLabel: "Magnitude",
                    secondaryLabel: nil,
                    yMax: 1,
                    yTickLabels: ["0", "0.5", "1.0"],
                    points: [
                        DLBarPoint(label: "x=−2",  sublabel: "left",  primary: 0.62, secondary: nil, annotation: "Input far left. Gradient strong: SGD pushes w₁ hard toward the correct direction."),
                        DLBarPoint(label: "x=0",   sublabel: "centre",primary: 0.18, secondary: nil, annotation: "Near zero input. Gradient is small because ∂z/∂w = x ≈ 0."),
                        DLBarPoint(label: "x=+2",  sublabel: "right", primary: 0.55, secondary: nil, annotation: "Input far right. Strong gradient again, opposite sign. SGD adjusts w₁ in the other direction."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Each bar is the same chain rule with a different x. The magnitude changes but the algorithm does not."
                )),
                caption: "Three input values. Same network, same chain rule, different gradient at the bottom of the network.",
                takeaway: "One rule, composed across layers. That's the entire algorithm."
            ),
            DLVizCard(
                kicker: "CARD 06 · CREDIT ASSIGNMENT",
                titleSegments: [
                    .plain("Hidden units finally "),
                    .highlight("learn for themselves")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Feature crispness",
                    primaryLabel: "With backprop",
                    secondaryLabel: "No backprop",
                    yMax: 1,
                    yTickLabels: ["random", "edge", "stroke"],
                    points: [
                        DLBarPoint(label: "Ep0",   sublabel: nil, primary: 0.05, secondary: 0.05, annotation: "Both networks initialise with random hidden filters. No structure yet."),
                        DLBarPoint(label: "Ep50",  sublabel: nil, primary: 0.45, secondary: 0.05, annotation: "Backprop net's hidden units begin to organise. The other stays random forever."),
                        DLBarPoint(label: "Ep200", sublabel: nil, primary: 0.95, secondary: 0.05, annotation: "Edge, corner, and stroke detectors emerge. Without backprop, hidden layers cannot improve at all."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Same network, same data, same epochs. Only the gradient signal differs."
                )),
                caption: "Hidden representations across training. With backprop, features become meaningful. Without, they stay random.",
                takeaway: "Hidden layers learn because backprop tells them what to learn."
            ),
        ],

        completeTakeaway: "\"Backprop is just the chain rule, applied without apology.\"",
        completeNextTease: "Up next: LeNet, where backprop trains the first working ConvNet.",
        paperTitle: "Learning Representations by Back Propagating Errors",
        learningObjectives: [
            DLObjective(
                text: "Why hidden layers couldn't learn before 1986",
                gloss: "No mechanism told a buried weight whether it had helped or hurt the loss."),
            DLObjective(
                text: "How the chain rule walks gradients backward",
                gloss: "Multiply local derivatives layer by layer, blame propagates to every weight."),
            DLObjective(
                text: "Why every modern net can train at all",
                gloss: "Backprop turned arbitrary depth into a solvable optimisation problem."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("One pass forward, "),
                .highlight("one pass back"),
            ],
            mini: .backprop,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · FORWARD",
                    body: "Activations propagated left to right. The input x became a hidden representation h = σ(W₁x), which became a prediction ŷ = W₂h. The network only ever computed; it didn't yet learn anything."),
                DLExplanationPara(
                    kicker: "P2 · BLAME",
                    body: "The loss L compared ŷ to the truth y. ∂L/∂ŷ is the easiest gradient to write down because the loss sits right next to the output. That single scalar is the seed for everything that follows."),
                DLExplanationPara(
                    kicker: "P3 · BACKWARD",
                    body: "Walking right to left, each layer's gradient is the product of the next layer's gradient and its own local derivative. ∂L/∂W₁ = ∂L/∂ŷ · ∂ŷ/∂h · ∂h/∂W₁. Every weight in the network now knows what to do next step."),
            ],
            takeaway: "One algorithm. Walks backward. Trains every weight that ever existed."
        ),
        paperURL: "https://www.nature.com/articles/323533a0"
    )

    // MARK: LeNet-5

    static let lenet = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · CNN",
        heroTitleSegments: [
            .plain("Eight layers that "),
            .highlight("read handwriting")
        ],
        heroBody: "The first network that learned to read shapes straight from raw pixels. Good enough to recognize handwritten zip codes for the postal service.",
        sourceLine: "IEEE 1998 · LeCun, Bottou, Bengio, Haffner",

        hookSegments: [
            .plain("What if a neural net could "),
            .highlight("learn its own features"),
            .plain("?")
        ],
        hookBody: "Before LeNet, every vision system relied on hand crafted rules. This network learned what to look for straight from raw pixels and read 99.2% of handwritten digits correctly, the template that would define vision for 20 years. Across this loop you'll see why one small reusable detector beats a million separate weights, how it can spot a digit anywhere on the page, and the hierarchy that emerges without anyone designing it.",

        coreIdeaSegments: [
            .plain("Three things conv layers "),
            .highlight("get right")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "One filter slid across the whole image",
                detail: "A 5×5 conv filter has 25 weights, used across every position in the image. A fully connected layer of comparable receptive field would have orders of magnitude more, and overfit on MNIST in seconds."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "It spots a digit anywhere on the page",
                detail: "Max/average pooling halves the spatial dimensions and lets a feature trigger no matter where it sits. Combined with conv, the same digit recognises whether it's drawn at the top or bottom of the box."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Each layer learns something more abstract",
                detail: "Conv1 fires on edges. Conv2 fires on combinations of edges, corners, curves. By the FC layer, units respond to whole strokes. No one designed that hierarchy; gradient descent did."),
        ],

        eliAnalogyLabel: "ANALOGY · A SLIDING MAGNIFYING GLASS",
        eliHeadlineSegments: [
            .plain("Imagine inspecting a photo with one "),
            .highlight("re usable lens"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("A fully connected layer is a "),
            .bold("custom inspector for every pixel"),
            .plain(", wasteful, since edges look the same at the top and bottom of the page. A conv filter is one "),
            .bold("magnifying glass slid across the whole image"),
            .plain(". Whatever pattern it learns, it finds everywhere, far fewer parts, far better generalisation."),
        ],
        eliArt: .magnifier,

        diagramSegments: [
            .plain("How pixels become "),
            .highlight("a digit")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "input",
                label: "Input",
                sublabel: "32×32",
                panelTitle: "Input · raw pixels",
                panelBody: "A 32×32 grayscale image of a handwritten digit. No features extracted, no preprocessing beyond centring. The network sees the same vector you'd see if you flattened the picture."),
            DLDiagramNode(
                id: "conv1",
                label: "Conv1",
                sublabel: "6 filters",
                panelTitle: "Conv1 · 6 learned filters",
                panelBody: "Six 5×5 filters slide across the image. Each learns one low level pattern, a horizontal edge, a curve, a corner. Output: 6 feature maps of size 28×28, each highlighting where its filter fired."),
            DLDiagramNode(
                id: "pool",
                label: "Pool",
                sublabel: "↓ 2×",
                panelTitle: "Pooling · halve and forget",
                panelBody: "Average pooling collapses every 2×2 patch into one value. Spatial size halves; the receptive field doubles. Translation invariance for free, a digit shifted a pixel left still looks identical to the next layer."),
            DLDiagramNode(
                id: "fc",
                label: "FC + Out",
                sublabel: "10 classes",
                panelTitle: "FC + Output · classify",
                panelBody: "After two more conv→pool blocks, the 5×5×16 feature map flattens to a vector. Two fully connected layers compress it to 10 logits, one per digit. The argmax is the prediction."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four stops along LeNet-5. Tap each to see what changes between layers.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE PARAM SAVINGS",
                titleSegments: [
                    .plain("Why "),
                    .highlight("convolution wins")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Trainable parameters (k)",
                    primaryLabel: "Conv layer",
                    secondaryLabel: "Fully connected",
                    yMax: 1.0,
                    yTickLabels: ["0", "500k", "1M"],
                    points: [
                        DLBarPoint(label: "L1", sublabel: "first layer", primary: 0.001, secondary: 0.78,
                                   annotation: "A 5×5 conv with 6 filters has 156 weights. A dense layer with the same receptive field would have ~780k. 5000× fewer parameters."),
                        DLBarPoint(label: "L2", sublabel: nil, primary: 0.003, secondary: 0.92,
                                   annotation: "Conv2: 16 filters of 5×5 over 6 channels = 2,416 weights. Equivalent dense layer: ~920k."),
                        DLBarPoint(label: "Acc", sublabel: "MNIST", primary: 0.992, secondary: 0.60,
                                   annotation: "And accuracy doesn't suffer. LeNet hits 99.2% on MNIST; a fully connected net of similar parameter budget tops out around 60%."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any layer. Conv (teal) beats dense (amber) on parameters every time, and matches on accuracy."
                )),
                caption: "Two layers' weight counts plus the final accuracy comparison. Convolution gives you small + good, where dense forces you to choose.",
                takeaway: "Spatial structure should be respected by the architecture."
            ),
            DLVizCard(
                kicker: "CARD 06 · DEPTH EARNS ABSTRACTION",
                titleSegments: [
                    .plain("Each layer sees "),
                    .highlight("a wider patch")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Receptive field (px)",
                    primaryLabel: "Receptive field",
                    secondaryLabel: nil,
                    yMax: 32,
                    yTickLabels: ["1px", "16px", "32px"],
                    points: [
                        DLBarPoint(label: "Conv1", sublabel: "edges", primary: 5, secondary: nil,
                                   annotation: "5×5 receptive field. Each unit sees a 5px patch. Filters learn edges, curves, gradients."),
                        DLBarPoint(label: "Pool1", sublabel: nil, primary: 6, secondary: nil,
                                   annotation: "After 2× downsampling, each new unit covers 6px of original input. Cheap effective field doubling."),
                        DLBarPoint(label: "Conv2", sublabel: "junctions", primary: 14, secondary: nil,
                                   annotation: "14×14 effective receptive field. Filters now combine multiple edges into corners and junctions."),
                        DLBarPoint(label: "FC", sublabel: "whole digit", primary: 32, secondary: nil,
                                   annotation: "Final layer sees the whole image. Each unit responds to a holistic shape, a 7, an 8, a loop."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any layer. Each step doubles the patch the network can integrate, building features from local to global."
                )),
                caption: "Receptive field grows monotonically with depth. By the FC layer, every unit can see the whole digit.",
                takeaway: "Edges → corners → strokes → digits, layer by layer."
            ),
        ],

        completeTakeaway: "\"Convolutions don't classify images. They learn the language of images.\"",
        completeNextTease: "Up next: AlexNet, the night this template went deep.",
        paperTitle: "Gradient Based Learning Applied to Document Recognition (LeNet-5)",
        learningObjectives: [
            DLObjective(
                text: "Why one filter is wiser than a million weights",
                gloss: "Same 5×5 kernel slid across every position. Translation-invariant by design."),
            DLObjective(
                text: "How pooling spots a digit anywhere on the page",
                gloss: "Down-sample features. The network no longer cares where in the image the stroke landed."),
            DLObjective(
                text: "Why each layer gets more abstract on its own",
                gloss: "Conv1 finds edges. Conv2 finds combinations. FC sees whole digits. No one designed the hierarchy."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("From pixels to "),
                .highlight("a digit, one layer at a time"),
            ],
            mini: .lenet,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · ONE FILTER, EVERYWHERE",
                    body: "Each 5×5 conv filter has only 25 learnable weights. The same filter is dragged across every position in the image. Cheap, translation-invariant, and impossible to overfit on small data the way a fully connected layer of comparable receptive field would."),
                DLExplanationPara(
                    kicker: "P2 · POOLING DROPS POSITION",
                    body: "Between conv blocks, max or average pooling halves the spatial dimensions. The unit no longer fires only when the stroke is at pixel (12,14), it fires when the stroke is roughly there. Position information leaks out and what remains is the feature itself."),
                DLExplanationPara(
                    kicker: "P3 · HIERARCHY FOR FREE",
                    body: "Conv1 learns edges and curves. Conv2 composes those into corners and strokes. By the FC layer, individual units respond to whole digits. Nobody told the network to build this ladder; gradient descent under translation invariance discovered it."),
            ],
            takeaway: "Convolutions don't classify images. They learn the language of images."
        ),
        paperURL: "https://yann.lecun.com/exdb/publis/pdf/lecun-98.pdf"
    )

    // MARK: AlexNet

    static let alexnet = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · VISION",
        heroTitleSegments: [
            .plain("The night vision "),
            .highlight("changed overnight")
        ],
        heroBody: "The moment vision tipped. A deeper image network suddenly halved the world's best error rate and pulled deep learning into the mainstream.",
        sourceLine: "NeurIPS 2012 · Krizhevsky, Sutskever, Hinton",

        hookSegments: [
            .plain("What if "),
            .highlight("five small tricks"),
            .plain(" ended a decade of hand engineering?")
        ],
        hookBody: "AlexNet wasn't smarter, it was bigger and stitched together a handful of practical tricks: a faster way for neurons to fire, randomly dropping pieces during training so the rest learn to cope, generating more training examples from the ones you have, and running the whole thing on graphics chips. Together they cut the world's best image error from 26% to 16% in one paper, and deep learning stopped being a niche.",

        coreIdeaSegments: [
            .plain("Three innovations that "),
            .highlight("compounded")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "A simpler activation makes training fast",
                detail: "max(0, x) trains 6× faster than tanh. No vanishing gradient in the positive region. The simplest activation function turned out to be the right one."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Turning off random neurons stops memorization",
                detail: "Randomly zero 50% of neurons each forward pass. Forces the network to build redundant representations and drops the test set error gap dramatically."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Gaming hardware made deep learning possible",
                detail: "Conv layers are embarrassingly parallel. Two GTX 580s training for a week were enough to fit 60M parameters across 1.2M images. Without GPUs, this paper doesn't happen."),
        ],

        eliAnalogyLabel: "ANALOGY · A KITCHEN, NOT A RECIPE",
        eliHeadlineSegments: [
            .plain("Imagine giving a chef "),
            .highlight("better tools"),
            .plain(", not a better cookbook.")
        ],
        eliBodyParts: [
            .plain("Hand crafted vision was "),
            .bold("a perfect recipe in a tiny kitchen"),
            .plain(". AlexNet was the same recipe, in a "),
            .bold("massive industrial kitchen with sharper knives"),
            .plain(", ReLU, dropout, augmentation, and GPUs. The dish was always the same; the kitchen finally caught up."),
        ],
        eliArt: .kitchen,

        diagramSegments: [
            .plain("Five innovations, "),
            .highlight("one paper")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "relu",
                label: "ReLU",
                sublabel: "max(0,x)",
                panelTitle: "ReLU · the activation",
                panelBody: "max(0, x) replaced tanh and sigmoid. Linear in the positive region means no vanishing gradient. Trains 6× faster, Krizhevsky's plot of training error vs. epochs is the canonical proof."),
            DLDiagramNode(
                id: "dropout",
                label: "Dropout",
                sublabel: "p=0.5",
                panelTitle: "Dropout · forced redundancy",
                panelBody: "Half the neurons are randomly silenced each forward pass. The network can't rely on any single unit, so it builds many redundant paths. Test error drops; train error stays. Best regulariser of the decade."),
            DLDiagramNode(
                id: "aug",
                label: "Aug.",
                sublabel: "crops + flips",
                panelTitle: "Data augmentation · free examples",
                panelBody: "Random 224×224 crops out of 256×256 inputs, plus horizontal flips and PCA based colour jitter. The network never sees the same image twice, multiplying the effective dataset roughly 2,048×."),
            DLDiagramNode(
                id: "gpu",
                label: "Dual GPU",
                sublabel: "2× GTX 580",
                panelTitle: "Two GPUs · the hardware hack",
                panelBody: "60M parameters didn't fit on one 3GB card. The team split the network across two GTX 580s with cross GPU connections at layer 3. A pragmatic hack that became the default for big models."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four innovations introduced in one 2012 paper. Tap each for the role it played.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE 10-POINT DROP",
                titleSegments: [
                    .plain("ImageNet error "),
                    .highlight("falls off a cliff")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Top-5 error (%)",
                    primaryLabel: "Method",
                    secondaryLabel: nil,
                    yMax: 30,
                    yTickLabels: ["0%", "15%", "30%"],
                    points: [
                        DLBarPoint(label: "2010", sublabel: "SIFT", primary: 28.2, secondary: nil,
                                   annotation: "2010 winner: hand crafted SIFT features + linear classifier. State of the art and stable for years."),
                        DLBarPoint(label: "2011", sublabel: "Fisher", primary: 25.8, secondary: nil,
                                   annotation: "2011 winner: Fisher vectors. A modest improvement, still hand engineered."),
                        DLBarPoint(label: "2012", sublabel: "AlexNet", primary: 16.4, secondary: nil,
                                   annotation: "AlexNet, 16.4% top-5 error. A 10-point drop. The runner up was still using hand crafted features."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "deep learning",
                    defaultInsight: "Tap any year. The drop in 2012 is so large it ended the era of hand crafted features overnight."
                )),
                caption: "Three years of ImageNet winners. The cliff at 2012 isn't gradual; it's a phase transition.",
                takeaway: "The gap wasn't bigger. It was qualitatively different."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHAT SCALE BOUGHT",
                titleSegments: [
                    .plain("Sixty million "),
                    .highlight("parameters")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Parameters (M)",
                    primaryLabel: "AlexNet",
                    secondaryLabel: "LeNet-5",
                    yMax: 60,
                    yTickLabels: ["0", "30M", "60M"],
                    points: [
                        DLBarPoint(label: "Conv", sublabel: nil, primary: 3.7, secondary: 0.05,
                                   annotation: "Conv stack: 3.7M params, vs LeNet's 50k. Wider filters, more channels, deeper stack."),
                        DLBarPoint(label: "FC", sublabel: nil, primary: 56.3, secondary: 0.06,
                                   annotation: "Fully connected layers carry the bulk: 56M parameters out of 60M. Dropout was invented to keep them honest."),
                        DLBarPoint(label: "Total", sublabel: nil, primary: 60.0, secondary: 0.06,
                                   annotation: "60M params, trained on 1.2M images for ~90 epochs across two GPUs in one week. The blueprint every modern vision model still follows."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "AlexNet has 1000× more parameters than LeNet. Most live in the FC head, which is why dropout matters."
                )),
                caption: "AlexNet vs LeNet, parameter by parameter. Most of the size, and most of the regularisation problem, is in the dense head.",
                takeaway: "Scale was the story. The tricks made scale stable."
            ),
        ],

        completeTakeaway: "\"AlexNet didn't outperform the runner up. It dethroned the field.\"",
        completeNextTease: "Up next: Word2Vec, meaning as geometry.",
        paperTitle: "ImageNet Classification with Deep Convolutional Neural Networks",
        learningObjectives: [
            DLObjective(
                text: "Why ReLU killed sigmoid for vision",
                gloss: "No saturation, no vanishing gradient. Six times faster to train at depth."),
            DLObjective(
                text: "How dropout teaches a network humility",
                gloss: "Drop random units each step. The survivors must learn redundant, generalisable features."),
            DLObjective(
                text: "What it really took to halve the ImageNet error",
                gloss: "Five tricks compounded on a deep ConvNet running on two GPUs for a week."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Five tricks, "),
                .highlight("one cliff drop"),
            ],
            mini: .alexnet,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · DEPTH",
                    body: "AlexNet was 8 layers deep, twice what anyone had successfully trained on real images. Depth alone would have failed; that's exactly what the next four tricks were there to rescue."),
                DLExplanationPara(
                    kicker: "P2 · TRICKS",
                    body: "ReLU replaced sigmoid so gradients didn't vanish in the middle layers. Dropout silenced random units each step, forcing redundancy. Data augmentation invented new images for free. Local response normalisation cleaned up the activations between conv blocks."),
                DLExplanationPara(
                    kicker: "P3 · HARDWARE",
                    body: "Two NVIDIA GTX 580 GPUs split the model in half because the weights wouldn't fit on one card. That detail wasn't decorative, it's the reason the network ran at all in 2012. Compute is the silent fifth author."),
            ],
            takeaway: "Deep learning shipped on a Tuesday in 2012. The field never went back."
        ),
        paperURL: "https://papers.nips.cc/paper_files/paper/2012/hash/c399862d3b9d6b76c8436e924a68c45b-Abstract.html"
    )

    // MARK: Word2Vec

    static let word2vec = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · EMBEDDINGS",
        heroTitleSegments: [
            .plain("Words become "),
            .highlight("coordinates")
        ],
        heroBody: "Turn words into points in space, and similar words land near each other. Suddenly you can do math on meaning: king minus man plus woman lands on queen.",
        sourceLine: "ICLR 2013 · Mikolov et al.",

        hookSegments: [
            .plain("What if "),
            .highlight("king − man + woman ≈ queen"),
            .plain(", just by geometry?")
        ],
        hookBody: "Word2Vec trains a shallow predictor: given a word, guess its neighbours (or vice versa). The hidden layer weights become 300-dim vectors. Similar words land near each other; relationships become directions you can add and subtract. Across this loop you'll see how a tiny prediction task births geometry, why King − Man + Woman lands on Queen, and what every modern language model still inherits from this idea.",

        coreIdeaSegments: [
            .plain("Three things embeddings "),
            .highlight("unlock")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Words that hang out together mean similar things",
                detail: "Train on enough text and \"cat\" and \"dog\" land near each other because they share contexts (\"my __ ate\", \"the __ barked\"). No grammar engineered, no labels, just the distributional hypothesis at scale."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Math on words actually works",
                detail: "vec(king) − vec(man) + vec(woman) lands near vec(queen). The same offset works for capitals, verb tenses, comparatives. Geometry alone captures regularities that took linguistics decades to formalise."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "A clever shortcut made training affordable",
                detail: "A full softmax over 1M words is impossibly slow. Mikolov's trick: contrast each true context word against 5 to 20 random negatives. Same gradient direction, ~1000× faster, used in every embedding training since."),
        ],

        eliAnalogyLabel: "ANALOGY · A MAP YOU NEVER DREW",
        eliHeadlineSegments: [
            .plain("Imagine a city "),
            .highlight("nobody planned"),
            .plain(", that lays itself out anyway.")
        ],
        eliBodyParts: [
            .plain("You drop houses on a blank field. Each house is a word. The rule: "),
            .bold("words that often live near each other in sentences should also live near each other on the map"),
            .plain(". Run the rule over Wikipedia and the map "),
            .bold("organises itself"),
            .plain(": royals in one neighbourhood, animals in another, capitals in a third. Nobody told it those categories existed."),
        ],
        eliArt: .map,

        diagramSegments: [
            .plain("Meaning as "),
            .highlight("clusters")
        ],
        diagramLayout: .hub,
        diagramNodes: [
            DLDiagramNode(
                id: "royalty",
                label: "Royalty",
                sublabel: "king, queen…",
                panelTitle: "Royalty cluster · titles",
                panelBody: "king, queen, prince, royal cluster tightly. Their contexts overlap (\"the __ ruled\", \"crowned __\"). Distance from this cluster to \"capitals\" is roughly the same as from \"animals\", geometry preserves category structure."),
            DLDiagramNode(
                id: "animals",
                label: "Animals",
                sublabel: "cat, dog…",
                panelTitle: "Animals cluster · creatures",
                panelBody: "cat, dog, wolf, lion form a separate cluster. Contexts: \"the __ chased\", \"my __ slept\". The sub structure within is also meaningful, cat sits closer to dog than to lion."),
            DLDiagramNode(
                id: "cities",
                label: "Capitals",
                sublabel: "Paris, Berlin…",
                panelTitle: "Capitals cluster · places",
                panelBody: "Paris, Berlin, London, Rome cluster together. The vector Paris−France ≈ Berlin−Germany ≈ Rome−Italy. The capital of relationship is encoded as a single offset shared across pairs."),
            DLDiagramNode(
                id: "arith",
                label: "k − m + w",
                sublabel: "≈ queen",
                panelTitle: "Vector arithmetic · directions are relations",
                panelBody: "vec(king) − vec(man) + vec(woman) lands within cosine 0.74 of vec(queen). The same arithmetic works for tense, plurality, comparative. Linear algebra over a co occurrence space."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Three semantic clusters and one arithmetic operation. Tap each to see how meaning becomes geometry.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · BEFORE / AFTER",
                titleSegments: [
                    .plain("From one hot to "),
                    .highlight("dense space")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Property",
                    primaryLabel: "Embeddings",
                    secondaryLabel: "One hot",
                    yMax: 1.0,
                    yTickLabels: ["worst", "mid", "best"],
                    points: [
                        DLBarPoint(label: "Dim", sublabel: "size", primary: 0.95, secondary: 0.05,
                                   annotation: "Dimensions: 300 vs 1M+. Embeddings are 3000× smaller and dense, every component carries information."),
                        DLBarPoint(label: "Sim", sublabel: "compare", primary: 0.90, secondary: 0.0,
                                   annotation: "Similarity: cosine over 300 dims gives a continuous, meaningful score. One hot vectors are always exactly orthogonal, so similarity is always zero."),
                        DLBarPoint(label: "Anal", sublabel: "arithmetic", primary: 0.85, secondary: 0.0,
                                   annotation: "Analogies: linear arithmetic actually works. king − man + woman ≈ queen. Impossible with one hot."),
                        DLBarPoint(label: "Gen", sublabel: "transfer", primary: 0.80, secondary: 0.0,
                                   annotation: "Generalisation: train on news, transfer to medical text, embeddings capture cross domain structure that one hot can't represent."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any property. Embeddings (teal) win on every axis, the only thing one hot has going for it is simplicity."
                )),
                caption: "Four properties of word representations. Dense embeddings dominate sparse one hot on every measurement that matters.",
                takeaway: "Sparse vectors compare nothing. Dense vectors compare everything."
            ),
            DLVizCard(
                kicker: "CARD 06 · CBOW VS SKIP GRAM",
                titleSegments: [
                    .plain("Two ways to learn "),
                    .highlight("from context")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Score",
                    primaryLabel: "Skip gram",
                    secondaryLabel: "CBOW",
                    yMax: 1.0,
                    yTickLabels: ["0", "0.5", "1.0"],
                    points: [
                        DLBarPoint(label: "Speed", sublabel: nil, primary: 0.55, secondary: 0.92,
                                   annotation: "CBOW trains ~3× faster: averaging context vectors is cheaper than predicting many separate words."),
                        DLBarPoint(label: "Rare", sublabel: "rare words", primary: 0.88, secondary: 0.62,
                                   annotation: "Skip gram dominates on rare words: it gets a separate prediction signal per context word, sharpening the rare word vector."),
                        DLBarPoint(label: "Freq", sublabel: "common", primary: 0.84, secondary: 0.86,
                                   annotation: "Roughly tied on frequent words. Both architectures see plenty of signal for these."),
                        DLBarPoint(label: "Anal", sublabel: "analogies", primary: 0.86, secondary: 0.74,
                                   annotation: "Skip gram's per context updates produce sharper analogy directions. CBOW smooths them out."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any axis. Skip gram (teal) wins on quality; CBOW (amber) wins on speed."
                )),
                caption: "Same data, two architectures. Skip gram's per context updates buy quality; CBOW's averaging buys speed.",
                takeaway: "Direction matters. Predict from one, or to one."
            ),
        ],

        completeTakeaway: "\"Word2Vec never reads a dictionary. It learns semantics from neighbours alone.\"",
        completeNextTease: "Up next: Seq2Seq, compress, then expand.",
        paperTitle: "Efficient Estimation of Word Representations in Vector Space",
        learningObjectives: [
            DLObjective(
                text: "Why words can be added like vectors",
                gloss: "King − Man + Woman lands on Queen. Meaning becomes a direction in space."),
            DLObjective(
                text: "How the model learns this without labels",
                gloss: "Predict the missing word from its neighbours. Embeddings fall out as a side effect."),
            DLObjective(
                text: "What this unlocked downstream",
                gloss: "Every modern NLP model starts where Word2Vec finished: words as dense, learned vectors."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Meaning collapsed into "),
                .highlight("300 numbers"),
            ],
            mini: .word2vec,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · DISTRIBUTIONAL",
                    body: "Words that appear in similar contexts mean similar things. Cat and dog show up around the same neighbour words; throne and parliament don't. Word2Vec turns this old linguistic observation into a training objective."),
                DLExplanationPara(
                    kicker: "P2 · TRAINING",
                    body: "Skip-gram picks a word, asks the network to predict its neighbours. The single hidden layer doesn't classify anything useful directly. What matters is the matrix of weights that pops out, one row per word in the vocabulary. Each row is that word's embedding."),
                DLExplanationPara(
                    kicker: "P3 · ARITHMETIC",
                    body: "Because contexts vary along consistent axes (gender, plurality, country–capital), the resulting vectors line up. Subtract Man from King, add Woman, you land near Queen. Nobody asked for this. The geometry emerged from prediction alone."),
            ],
            takeaway: "Meaning is direction. The compass came from a shallow neural net."
        ),
        paperURL: "https://arxiv.org/abs/1301.3781"
    )

    // MARK: Seq2Seq

    static let seq2seq = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · NLP",
        heroTitleSegments: [
            .plain("Compress, "),
            .highlight("then expand")
        ],
        heroBody: "One network reads a sentence in one language. Another speaks it back in another. End to end translation, no hand crafted rules.",
        sourceLine: "NeurIPS 2014 · Sutskever, Vinyals, Le",

        hookSegments: [
            .plain("What if a single "),
            .highlight("thought vector"),
            .plain(" could carry a whole sentence?")
        ],
        hookBody: "One network compressed a whole English sentence into a single summary, then a second network expanded that summary into French. End to end translation, no hand crafted rules. Across this loop you'll see how one network reads while another speaks, why funneling the whole sentence through a single summary is a problem, and how this bottleneck eventually forced the next idea into existence.",

        coreIdeaSegments: [
            .plain("Three pieces that "),
            .highlight("snap together")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Squeeze the whole sentence into one packet",
                detail: "An LSTM reads tokens left to right, updating its hidden state with each step. After the final token, the hidden state is treated as a complete summary of the input, a single point in 1000-dim space."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Unpack the packet into a new sentence",
                detail: "A second LSTM, initialised with the encoder's final state, generates the target sentence one token at a time. Each predicted token feeds back as the next step's input. Greedy or beam search at decode time."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Reading input backwards gave a free win",
                detail: "A small trick: feed the source sentence backwards. Now early target words are temporally close to early source words, gradients flow better, and translation quality jumps several BLEU points with no extra parameters."),
        ],

        eliAnalogyLabel: "ANALOGY · A WHISPER GAME WITH ONE NOTE",
        eliHeadlineSegments: [
            .plain("Imagine telling a friend a story, but only with "),
            .highlight("one sticky note"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("You read the whole sentence in English, then "),
            .bold("write everything you remember on one sticky note"),
            .plain(". A second person reads only the note, never the original, and "),
            .bold("speaks the French translation"),
            .plain(". The note is the bottleneck, and the reason attention was eventually invented."),
        ],
        eliArt: .whisper,

        diagramSegments: [
            .plain("How a sentence "),
            .highlight("crosses languages")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "src",
                label: "Source",
                sublabel: "Je suis…",
                panelTitle: "Source · the input",
                panelBody: "The source sentence is tokenised and reversed (a trick that improves gradient flow). Each token is embedded into a learned vector before entering the encoder."),
            DLDiagramNode(
                id: "enc",
                label: "Encoder",
                sublabel: "LSTM",
                panelTitle: "Encoder · compress",
                panelBody: "An LSTM reads the reversed source token by token, updating its hidden state. Crucially, only the final hidden state is passed forward, every intermediate state is discarded. That's the bottleneck."),
            DLDiagramNode(
                id: "ctx",
                label: "Context",
                sublabel: "thought vector",
                panelTitle: "Context · the thought vector",
                panelBody: "A single ~1000-dim vector that supposedly encodes the entire source sentence. For short sentences, fine. For long ones, this is where information is lost, the motivating problem for attention."),
            DLDiagramNode(
                id: "dec",
                label: "Decoder",
                sublabel: "LSTM",
                panelTitle: "Decoder · expand",
                panelBody: "A second LSTM initialised with the context vector. At each step it predicts the next target token, conditions the next step on it, and continues until <EOS>. Greedy at training, beam search at inference."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four stages of one translation. Tap each to see how a sentence becomes a single vector and back again.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE LENGTH PROBLEM",
                titleSegments: [
                    .plain("Quality "),
                    .highlight("falls with length")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "BLEU",
                    primaryLabel: "Seq2Seq",
                    secondaryLabel: "Phrase based",
                    yMax: 40,
                    yTickLabels: ["0", "20", "40"],
                    points: [
                        DLBarPoint(label: "≤10", sublabel: "short", primary: 35, secondary: 28,
                                   annotation: "Short sentences (≤10 tokens): seq2seq beats phrase based MT comfortably. The thought vector still fits."),
                        DLBarPoint(label: "11-20", sublabel: nil, primary: 33, secondary: 30,
                                   annotation: "Mid length: seq2seq stays ahead but the gap narrows. The fixed vector starts to strain."),
                        DLBarPoint(label: "21-40", sublabel: nil, primary: 28, secondary: 31,
                                   annotation: "Long sentences (21 to 40): phrase based pulls ahead. The encoder's final state can't fit the whole thing."),
                        DLBarPoint(label: "41+", sublabel: "long", primary: 22, secondary: 30,
                                   annotation: "Very long: seq2seq drops sharply. This length cliff is exactly what attention was invented to fix."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "the cliff",
                    defaultInsight: "Tap any bin. Seq2Seq wins on short sentences; loses on long ones. The bottleneck is the fixed size vector."
                )),
                caption: "BLEU score by sentence length. The crossover at ~20 tokens is the moment the thought vector runs out of capacity.",
                takeaway: "Compression has a length limit."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHY REVERSE",
                titleSegments: [
                    .plain("Reversing the source "),
                    .highlight("helps gradients")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "BLEU gain",
                    primaryLabel: "Reversed source",
                    secondaryLabel: "Forward",
                    yMax: 40,
                    yTickLabels: ["0", "20", "40"],
                    points: [
                        DLBarPoint(label: "Forward", sublabel: nil, primary: 0, secondary: 25.9,
                                   annotation: "Source fed in normal order. BLEU 25.9. Gradients have to travel many time steps from output back to early source tokens."),
                        DLBarPoint(label: "Reversed", sublabel: nil, primary: 30.6, secondary: 0,
                                   annotation: "Source fed in reverse. BLEU 30.6, a +4.7 point jump from a one line code change. Early target tokens now sit close to early source tokens in the unrolled graph."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap either bar. Same model, same data; reversing the source buys 5 BLEU because it shortens the gradient path."
                )),
                caption: "Same architecture, same dataset. The reversal is purely about how gradients flow through time, and it's worth more than most architecture changes.",
                takeaway: "Distance in the unrolled graph matters more than distance in the sentence."
            ),
        ],

        completeTakeaway: "\"Seq2Seq proved language can be compressed. Attention proved it shouldn't always be.\"",
        completeNextTease: "Up next: GANs, when two networks fight.",
        paperTitle: "Sequence to Sequence Learning with Neural Networks",
        learningObjectives: [
            DLObjective(
                text: "How one network reads and another speaks",
                gloss: "Encoder LSTM ingests the source. Decoder LSTM unrolls the target one token at a time."),
            DLObjective(
                text: "Why everything funnels through a single vector",
                gloss: "The encoder's final hidden state IS the meaning. The decoder reads from it and nothing else."),
            DLObjective(
                text: "Where this bottleneck breaks",
                gloss: "Long inputs lose detail. Reversing helped. Attention will eventually replace it entirely."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("A sentence, "),
                .highlight("compressed and unrolled"),
            ],
            mini: .seq2seq,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · ENCODE",
                    body: "The encoder LSTM reads the source sentence one token at a time. Its hidden state evolves with every word. After the last word, that final hidden state is supposed to summarise the entire sentence in a few hundred numbers."),
                DLExplanationPara(
                    kicker: "P2 · CONTEXT",
                    body: "That single vector c is the only thing the decoder ever sees from the source side. Translation, by construction, is a thought passed between two networks. The capacity of c is the capacity of the model to remember anything from the input."),
                DLExplanationPara(
                    kicker: "P3 · DECODE",
                    body: "The decoder LSTM unrolls c into the target language, one token at a time, feeding its own previous output back in. Variable-length output falls out for free. Long inputs crush the bottleneck, which is exactly the problem attention will be invented to solve."),
            ],
            takeaway: "Translation as a thought, passed between two networks."
        ),
        paperURL: "https://arxiv.org/abs/1409.3215"
    )

    // MARK: GANs

    static let gans = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · GENERATIVE",
        heroTitleSegments: [
            .plain("Two networks in an "),
            .highlight("endless game")
        ],
        heroBody: "Two networks face off: one tries to forge realistic images, the other tries to catch the fakes. They push each other until the fakes look real.",
        sourceLine: "NeurIPS 2014 · Goodfellow et al.",

        hookSegments: [
            .plain("What if a generator's "),
            .highlight("loss function"),
            .plain(" was another network?")
        ],
        hookBody: "Train two networks at the same time, against each other. One tries to forge realistic fakes, the other tries to spot them. They push each other until the fakes are indistinguishable from real data. The trick birthed deepfakes, StyleGAN, and modern image synthesis. Across this loop you'll see why two networks beat one, how you can make new samples without ever writing down a probability, and the exact ways the duel falls apart.",

        coreIdeaSegments: [
            .plain("Three things make the "),
            .highlight("game work")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "One network forges fake images",
                detail: "G(z) maps a random latent vector z into a candidate sample. Random in, structured out. The same fixed mapping defines a probability distribution over samples, the one G is trying to match to the real data distribution."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Another network plays detective",
                detail: "D is a binary classifier: it should output 1 on real data x and 0 on G(z). Crucially, D's parameters change too, as G improves, D has to get better at spotting subtler fakes."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "They get better by competing",
                detail: "min_G max_D E[log D(x)] + E[log(1 − D(G(z)))]. At equilibrium, p_G = p_data and D collapses to ½ everywhere. In practice, training is unstable, but the asymptote is mathematically clean."),
        ],

        eliAnalogyLabel: "ANALOGY · A FORGER AND A DETECTIVE",
        eliHeadlineSegments: [
            .plain("Imagine training a forger by "),
            .highlight("hiring a detective"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("Every day the forger paints a fake. The detective tries to spot it. When the detective wins, the forger learns "),
            .bold("what gave it away"),
            .plain(" and fixes it. When the forger wins, the detective learns "),
            .bold("a new tell"),
            .plain(". After a year, the forgeries are perfect, and the detective can't do better than guessing."),
        ],
        eliArt: .forger,

        diagramSegments: [
            .plain("Generator vs "),
            .highlight("discriminator")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "noise",
                label: "Noise z",
                sublabel: "p(z)",
                panelTitle: "Noise · the seed",
                panelBody: "z is a random vector drawn from p(z), usually a standard normal. It carries no semantic content; it's pure entropy. The generator's job is to turn this noise into a structured sample."),
            DLDiagramNode(
                id: "g",
                label: "Generator",
                sublabel: "G(z)",
                panelTitle: "Generator · the forger",
                panelBody: "G is a neural network that maps z to a candidate sample. Its goal: produce something that fools D into outputting 1. G never sees real data directly, it only learns from D's mistakes."),
            DLDiagramNode(
                id: "d",
                label: "Discriminator",
                sublabel: "D(x)",
                panelTitle: "Discriminator · the detective",
                panelBody: "D is a binary classifier. It sees a mixture of real samples and fakes from G, outputting 1 for real and 0 for fake. Its loss: maximise log D(real) + log(1 − D(fake))."),
            DLDiagramNode(
                id: "real",
                label: "Real x",
                sublabel: "p_data",
                panelTitle: "Real data · the target distribution",
                panelBody: "Real samples drawn from p_data. They never train G directly, only D. The whole game is about making p_G match p_data, mediated entirely by D's predictions."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four nodes form one GAN training step. Tap each to see who's doing what.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · CONVERGENCE",
                titleSegments: [
                    .plain("D's accuracy "),
                    .highlight("falls to ½")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "Training step (k)",
                    yAxisLabel: "D accuracy",
                    xTickLabels: ["0", "50k", "100k", "150k"],
                    yTickLabels: ["0.5", "0.75", "1.0"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Discriminator",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0,   y: 0.95, milestone: "start", annotation: "Start: G outputs noise, D classifies it perfectly. Accuracy ≈ 1."),
                                DLTrainingCurvePoint(x: 30,  y: 0.85, milestone: nil,    annotation: "G picks up basic structure. D still wins but is starting to make mistakes."),
                                DLTrainingCurvePoint(x: 70,  y: 0.70, milestone: nil,    annotation: "Half way: G's samples are crude but plausible. D's accuracy is dropping fast."),
                                DLTrainingCurvePoint(x: 120, y: 0.55, milestone: "near eq.", annotation: "Near equilibrium. D is barely better than chance. G's samples look like real data on most axes."),
                                DLTrainingCurvePoint(x: 160, y: 0.51, milestone: "Nash", annotation: "Nash equilibrium. p_G ≈ p_data. D ≈ ½ everywhere. The game is stable, in theory."),
                            ]
                        ),
                    ],
                    defaultInsight: "Tap any milestone. D starts at ~95% accuracy and falls to chance as G learns to match the real distribution."
                )),
                caption: "D's accuracy across training. The slide from 1.0 to 0.5 is the only metric that matters in a GAN.",
                takeaway: "When D can't tell, G has won."
            ),
            DLVizCard(
                kicker: "CARD 06 · MODE COLLAPSE",
                titleSegments: [
                    .plain("When G plays it "),
                    .highlight("too safe")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Sample diversity",
                    primaryLabel: "Healthy",
                    secondaryLabel: "Collapsed",
                    yMax: 1.0,
                    yTickLabels: ["0", "0.5", "1.0"],
                    points: [
                        DLBarPoint(label: "Mode 1", sublabel: nil, primary: 0.30, secondary: 0.95,
                                   annotation: "Mode 1: in healthy training, ~30% of samples land here. In a collapsed model, almost everything does, G has found one realistic output and stopped exploring."),
                        DLBarPoint(label: "Mode 2", sublabel: nil, primary: 0.28, secondary: 0.03,
                                   annotation: "Mode 2: a different cluster of real samples. Healthy G covers it; collapsed G ignores it entirely."),
                        DLBarPoint(label: "Mode 3", sublabel: nil, primary: 0.24, secondary: 0.01,
                                   annotation: "Mode 3: starved. The collapsed G has no idea this region of data even exists."),
                        DLBarPoint(label: "Mode 4", sublabel: nil, primary: 0.18, secondary: 0.01,
                                   annotation: "Mode 4: also starved. The diversity loss is invisible to D, both sets pass D's check, which is why the failure mode persists."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any mode. Mode collapse is invisible to D, both healthy and collapsed G's pass D's checks, but only one covers the data."
                )),
                caption: "Sample diversity across four modes of the real distribution. A collapsed G covers one mode perfectly and ignores the rest.",
                takeaway: "Fooling D is necessary. Covering the data is not, unless you make it so."
            ),
        ],

        completeTakeaway: "\"No labels needed. The discriminator is the loss function.\"",
        completeNextTease: "Up next: ResNet, the shortcut that saved depth.",
        paperTitle: "Generative Adversarial Nets",
        learningObjectives: [
            DLObjective(
                text: "Why two networks beat one at generation",
                gloss: "Generator and discriminator co-train. Each only improves when the other does."),
            DLObjective(
                text: "How sampling replaces explicit likelihood",
                gloss: "No probability formula to write. Just samples that have to fool a learned critic."),
            DLObjective(
                text: "Where the duel falls apart",
                gloss: "Mode collapse, vanishing D gradients, unstable equilibria. Beautiful, fragile."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Forger and detective, "),
                .highlight("trained together"),
            ],
            mini: .gans,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · FORGER",
                    body: "G is just a neural net that maps random noise z to a fake sample x̂. At the start it produces nonsense. It has no idea what real data even looks like, only what gradient flows back through D telling it which direction to nudge."),
                DLExplanationPara(
                    kicker: "P2 · DETECTIVE",
                    body: "D is a binary classifier trying to tell real samples from G's fakes. Every step, D's gradient on G says exactly which dimensions of x̂ were too obvious. That gradient is the only teacher G ever has."),
                DLExplanationPara(
                    kicker: "P3 · EQUILIBRIUM",
                    body: "At the minimax saddle point, D is 50% confused on every sample and G is producing the data distribution exactly. The math is clean. The training, less so, oscillation, mode collapse, and gradient starvation are the practical bestiary you'll meet next."),
            ],
            takeaway: "Two networks, locked in a duel. Out comes a forger nobody can catch."
        ),
        paperURL: "https://arxiv.org/abs/1406.2661"
    )

    // MARK: ResNet

    static let resnet = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · ARCHITECTURE",
        heroTitleSegments: [
            .plain("The shortcut that "),
            .highlight("saved depth")
        ],
        heroBody: "Adding a tiny shortcut between layers let networks be far deeper than anyone thought possible. 152 layers deep, still learning.",
        sourceLine: "CVPR 2016 · He, Zhang, Ren, Sun",

        hookSegments: [
            .plain("What if making nets "),
            .highlight("deeper made them worse"),
            .plain(", until you added a wire?")
        ],
        hookBody: "Plain CNNs degraded past 20 layers, adding depth made training and test error rise. ResNet's fix: add a single skip connection per block. Suddenly 152 layers trained cleanly and won ImageNet 2015. Across this loop you'll see why deeper got worse before 2015, what a skip connection actually does, and why every Transformer block still uses one today.",

        coreIdeaSegments: [
            .plain("Three properties of "),
            .highlight("residual blocks")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Learn what to change, not everything",
                detail: "Instead of learning H(x) directly, learn F(x) = H(x) − x. The block then outputs F(x) + x. If the optimal mapping is identity, F can just learn 0, far easier than learning identity from scratch."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "A shortcut keeps signals alive",
                detail: "The skip connection gives gradients a clean path back to early layers, bypassing the non linearities that would otherwise vanish them. Even at 152 layers, signal still reaches the input."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Adding more layers stops breaking the model",
                detail: "On ImageNet, a 34-layer plain net was worse than an 18-layer one. ResNet's 34-layer version was better. The 152-layer ResNet broke records. Skip connections converted depth from a liability into an asset."),
        ],

        eliAnalogyLabel: "ANALOGY · AN EMERGENCY EXIT",
        eliHeadlineSegments: [
            .plain("Imagine a tall office building "),
            .highlight("with a fire pole"),
            .plain(" on every floor.")
        ],
        eliBodyParts: [
            .plain("Each conv layer is a flight of stairs. Going down, useful signal, and going up, gradients, has to "),
            .bold("traverse every floor"),
            .plain(". Add fire poles between floors and "),
            .bold("information can take the express route"),
            .plain(". The stairs still exist for nuance, but the fast path keeps the building from collapsing under its own depth."),
        ],
        eliArt: .exit,

        diagramSegments: [
            .plain("How identity "),
            .highlight("rescues depth")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "x",
                label: "x",
                sublabel: "input",
                panelTitle: "Input · what comes in",
                panelBody: "x is the activation entering the block. Without a skip, x would be transformed and discarded; with one, it's also added back at the end. That direct connection is the whole trick."),
            DLDiagramNode(
                id: "f1",
                label: "Conv1",
                sublabel: "BN + ReLU",
                panelTitle: "Conv1 · first transform",
                panelBody: "The first conv (with batch norm and ReLU) extracts a candidate feature update. Note: nothing about this layer is special, what matters is what happens to its output."),
            DLDiagramNode(
                id: "f2",
                label: "Conv2",
                sublabel: "F(x)",
                panelTitle: "Conv2 · the residual",
                panelBody: "The second conv produces F(x), the residual. F doesn't need to learn the full mapping; it only needs to learn the *change* from x. If x is already good, F just outputs zeros."),
            DLDiagramNode(
                id: "add",
                label: "F(x) + x",
                sublabel: "skip add",
                panelTitle: "Add · the shortcut",
                panelBody: "The skip connection adds x back to F(x), then a final ReLU. Forward, identity flows through; backward, gradients flow through. Stack hundreds of these and depth stops hurting."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four parts of one residual block. Tap each to see how the skip changes the math.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · DEPTH STOPS HURTING",
                titleSegments: [
                    .plain("Plain nets degrade. "),
                    .highlight("ResNet doesn't")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "ImageNet top-5 error (%)",
                    primaryLabel: "ResNet",
                    secondaryLabel: "Plain",
                    yMax: 12,
                    yTickLabels: ["0%", "6%", "12%"],
                    points: [
                        DLBarPoint(label: "18", sublabel: "shallow", primary: 8.6, secondary: 9.2,
                                   annotation: "18 layers: ResNet and plain are roughly tied. Skip connections don't hurt."),
                        DLBarPoint(label: "34", sublabel: nil, primary: 7.0, secondary: 9.6,
                                   annotation: "34 layers: ResNet drops to 7.0%. Plain net actually got worse, the depth degradation problem in action."),
                        DLBarPoint(label: "50", sublabel: "bottleneck", primary: 5.3, secondary: 11.0,
                                   annotation: "50 layers: ResNet uses bottleneck blocks, hits 5.3%. Plain net would diverge, not even attempted in the original paper."),
                        DLBarPoint(label: "152", sublabel: "winner", primary: 3.6, secondary: 0,
                                   annotation: "152 layers: ResNet at 3.6%, ImageNet 2015 winner. A plain 152-layer net is untrainable; the bar isn't shown because it never converged."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any depth. ResNet (teal) drops monotonically with depth. Plain (amber) gets worse past 20 layers."
                )),
                caption: "Top-5 error vs network depth. The plain net curve U turns around 20 layers; the ResNet curve keeps falling.",
                takeaway: "Skip connections didn't make ResNet faster. They made depth productive."
            ),
            DLVizCard(
                kicker: "CARD 06 · GRADIENT FLOW",
                titleSegments: [
                    .plain("Gradients survive "),
                    .highlight("the skip")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "Layer (deep → shallow)",
                    yAxisLabel: "‖∇‖ (log)",
                    xTickLabels: ["L=152", "L=100", "L=50", "L=1"],
                    yTickLabels: ["10⁻⁶", "10⁻³", "1"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Plain",
                            color: .rose,
                            dashed: true,
                            points: [
                                DLTrainingCurvePoint(x: 0,   y: 0.9, milestone: "output", annotation: "Output side: gradient is healthy in both architectures."),
                                DLTrainingCurvePoint(x: 50,  y: 0.6, milestone: nil,      annotation: "After 50 layers of plain stack, gradient has decayed by ~3 orders of magnitude."),
                                DLTrainingCurvePoint(x: 100, y: 0.3, milestone: nil,      annotation: "100 layers in: plain net's gradient is essentially noise. Early layers stop learning."),
                                DLTrainingCurvePoint(x: 152, y: 0.05, milestone: "input", annotation: "At the input: plain gradient is ~10⁻⁶, six orders of magnitude smaller than the output. Vanishing gradient in action."),
                            ]
                        ),
                        DLTrainingCurveSeries(
                            label: "ResNet",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0,   y: 0.9, milestone: nil, annotation: "Output: same starting magnitude as plain net."),
                                DLTrainingCurvePoint(x: 50,  y: 0.85, milestone: nil, annotation: "50 layers in: barely any decay. Skip connections give gradients a parallel path."),
                                DLTrainingCurvePoint(x: 100, y: 0.78, milestone: nil, annotation: "100 layers: still close to full magnitude. The shortcut is doing its job."),
                                DLTrainingCurvePoint(x: 152, y: 0.72, milestone: "input", annotation: "At the input: ResNet's gradient is ~80% of the output's. Trainable. That's the whole win."),
                            ]
                        ),
                    ],
                    defaultInsight: "Tap any layer. Plain (amber, dashed) loses gradient signal exponentially. ResNet (teal) keeps it alive."
                )),
                caption: "Gradient magnitude vs layer position. Plain nets vanish; ResNet preserves the signal end to end.",
                takeaway: "Identity mappings are just gradient highways."
            ),
        ],

        completeTakeaway: "\"The network only has to learn what to change, not what to keep.\"",
        completeNextTease: "Up next: Attention, the architecture that replaced recurrence.",
        paperTitle: "Deep Residual Learning for Image Recognition",
        learningObjectives: [
            DLObjective(
                text: "Why deeper networks got WORSE before 2015",
                gloss: "Vanishing gradients and pure degradation. Adding layers actively hurt training error."),
            DLObjective(
                text: "What a skip connection actually does",
                gloss: "Learn the residual F(x) added to a clean copy of x. Identity becomes the default."),
            DLObjective(
                text: "Why 1000 layers suddenly worked",
                gloss: "Gradients flow through the identity shortcut. No signal drowns in depth."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Don't learn the layer, "),
                .highlight("learn what it changes"),
            ],
            mini: .resnet,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · DEGRADATION",
                    body: "Before ResNet, training a 56-layer plain CNN gave higher training error than the 20-layer version. Not overfitting, training error. Optimisation itself was failing at depth, gradients were vanishing or exploding before reaching the early layers."),
                DLExplanationPara(
                    kicker: "P2 · IDENTITY DEFAULT",
                    body: "ResNet reformulates each block: instead of y = F(x), use y = F(x) + x. If the optimal mapping is close to identity, the network only has to push F toward zero. Doing nothing is now a free option, not a feat of optimisation."),
                DLExplanationPara(
                    kicker: "P3 · GRADIENT HIGHWAY",
                    body: "On the backward pass, gradients have a direct path through the identity shortcut. Even at 152 layers, the signal at the bottom of the network resembles the signal at the top. That's why depth stopped hurting and started helping again."),
            ],
            takeaway: "Don't add a layer. Add what the layer should change."
        ),
        paperURL: "https://arxiv.org/abs/1512.03385"
    )

    // MARK: Transformer (Attention Is All You Need)

    static let transformer = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · TRANSFORMERS",
        heroTitleSegments: [
            .plain("Five pieces, "),
            .highlight("one revolution")
        ],
        heroBody: "Stop reading word by word. Let every word look at every other word at once. The design behind every modern language model was born here.",
        sourceLine: "NeurIPS 2017 · Vaswani et al.",

        hookSegments: [
            .plain("What if every word could "),
            .highlight("look at every other word"),
            .plain(", in parallel?")
        ],
        hookBody: "Stop reading word by word. Let every word look at every other word at once and decide how much each one matters. Faster to train, easier to scale, and the foundation of GPT, BERT, and Claude. Across this loop you'll see why reading one word at a time had to go, how attention replaces it in one step, and why nearly every modern AI traces back to this paper.",

        coreIdeaSegments: [
            .plain("Three things attention "),
            .highlight("changes")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Any word can talk to any other instantly",
                detail: "In an RNN, two tokens n apart need n hops to talk. In a Transformer, every pair is exactly one attention step apart. Long range dependencies stop vanishing in the gradient."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Many tiny readers work in parallel",
                detail: "8 heads run in parallel, each learning a different relationship, syntax, coreference, semantics, position. Their outputs concatenate and project back. One model, eight specialists."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Word order is stamped on, not assumed",
                detail: "Without recurrence, the model is order blind. Sinusoidal position encodings give each position a unique frequency fingerprint, added to the token embedding before the first attention layer."),
        ],

        eliAnalogyLabel: "ANALOGY · A ROOM OF READERS",
        eliHeadlineSegments: [
            .plain("Imagine a room where every reader can "),
            .highlight("ask every other reader"),
            .plain(" anything.")
        ],
        eliBodyParts: [
            .plain("An RNN is a "),
            .bold("relay race"),
            .plain(": each reader whispers to the next, so the last hears a "),
            .bold("garbled summary"),
            .plain(". A Transformer is a "),
            .bold("round table"),
            .plain(": every reader hears every other directly, weighted by relevance. The conversation finishes in one round."),
        ],
        eliArt: .readers,

        diagramSegments: [
            .plain("How tokens "),
            .highlight("look at each other")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "q",
                label: "Q",
                sublabel: "query",
                panelTitle: "Q · the seeker",
                panelBody: "Each token projects itself to a query vector, the question \"what context do I need?\". Different heads ask different questions; that's why multi head matters."),
            DLDiagramNode(
                id: "k",
                label: "K",
                sublabel: "key",
                panelTitle: "K · the index",
                panelBody: "Every other token projects to a key vector, its \"address\" in the head's space. Q · K dot products score how relevant each key is to the current query."),
            DLDiagramNode(
                id: "softmax",
                label: "softmax",
                sublabel: "weights",
                panelTitle: "Softmax · the attention weights",
                panelBody: "The QK scores normalise into probabilities that sum to 1. These are the attention weights, the per token mixture coefficients. A peaky softmax means strong focus; flat means broad attention."),
            DLDiagramNode(
                id: "v",
                label: "V",
                sublabel: "value",
                panelTitle: "V · the payload",
                panelBody: "Each token also projects to a value vector, its content. The output is the weighted sum of all values, weighted by the softmax. That's the new representation: a context aware blend."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Q, K, V, softmax, the four ingredients of self attention. Tap each to see its role.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · ATTENTION HEATMAP",
                titleSegments: [
                    .plain("\"It\" attends to "),
                    .highlight("the animal")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Attention weight",
                    primaryLabel: "from \"it\"",
                    secondaryLabel: nil,
                    yMax: 0.5,
                    yTickLabels: ["0", "0.25", "0.5"],
                    points: [
                        DLBarPoint(label: "the", sublabel: nil, primary: 0.06, secondary: nil,
                                   annotation: "Determiner. Negligible attention, \"it\" doesn't need this."),
                        DLBarPoint(label: "animal", sublabel: "ref", primary: 0.43, secondary: nil,
                                   annotation: "The antecedent. \"It\" pours 43% of its attention here, learning coreference with no explicit rule."),
                        DLBarPoint(label: "didn't", sublabel: nil, primary: 0.12, secondary: nil,
                                   annotation: "Negation. Some attention, relevant for sentiment but not reference."),
                        DLBarPoint(label: "cross", sublabel: nil, primary: 0.10, secondary: nil,
                                   annotation: "Verb. Light attention, \"it\" knows the action but doesn't depend on it for resolution."),
                        DLBarPoint(label: "tired", sublabel: "explanation", primary: 0.23, secondary: nil,
                                   annotation: "Why clause. Surprising amount of attention, \"it\" needs to know why to resolve to the right antecedent."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any token. \"It\" attends most strongly to \"animal\", coreference learned, no rule written."
                )),
                caption: "One row from a multi head attention map. The peak on \"animal\" is the coreference resolution emerging from data alone.",
                takeaway: "No syntax engineered. Attention learns relations directly."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHY NO RECURRENCE",
                titleSegments: [
                    .plain("Path length: "),
                    .highlight("O(n) → O(1)")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Steps between tokens",
                    primaryLabel: "Transformer",
                    secondaryLabel: "RNN",
                    yMax: 100,
                    yTickLabels: ["1", "50", "100"],
                    points: [
                        DLBarPoint(label: "n=10", sublabel: nil, primary: 1, secondary: 10,
                                   annotation: "Short context: RNN needs 10 hops between extremes; Transformer always 1. Marginal but present."),
                        DLBarPoint(label: "n=50", sublabel: nil, primary: 1, secondary: 50,
                                   annotation: "Mid context: RNN's gradient has to travel 50 time steps. Vanishing kicks in. Transformer still 1 step."),
                        DLBarPoint(label: "n=100", sublabel: nil, primary: 1, secondary: 100,
                                   annotation: "Long context: RNN is effectively dead, 100 backprop steps and the gradient is noise. Transformer unchanged."),
                        DLBarPoint(label: "n=1k+", sublabel: "long", primary: 1, secondary: 1000,
                                   annotation: "Very long: RNN can't learn 1000-token dependencies. Transformer pays only quadratic compute, not gradient depth."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any length. Transformer (teal) stays at 1 step. RNN (amber) grows linearly, gradients vanish, training stalls."
                )),
                caption: "Steps a gradient takes between two tokens, by sequence length. The constant vs linear gap is the entire reason Transformers won.",
                takeaway: "Distance in the graph is the real bottleneck."
            ),
        ],

        completeTakeaway: "\"The Transformer didn't improve NLP. It made NLP scalable.\"",
        completeNextTease: "Up next: GPT-3, when scale becomes capability.",
        paperTitle: "Attention Is All You Need",
        learningObjectives: [
            DLObjective(
                text: "Why recurrence had to go",
                gloss: "RNNs trained sequentially. Couldn't parallelise. Couldn't see across long inputs."),
            DLObjective(
                text: "How self-attention replaces the sequence model",
                gloss: "Every token attends to every other in one parallel step. Distance becomes free."),
            DLObjective(
                text: "Why this scaled to absolutely everything",
                gloss: "No recurrence, GPU-friendly, depth and width are pure compute. One recipe, every modality."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Replace the loop "),
                .highlight("with a look"),
            ],
            mini: .transformer,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · Q · K · V",
                    body: "Each token's embedding is projected three ways: into a Query (what am I looking for?), a Key (what do I represent?), and a Value (what do I carry?). The same vector wearing three different hats."),
                DLExplanationPara(
                    kicker: "P2 · SOFTMAX SCORES",
                    body: "For every pair of tokens, compute QKᵀ / √d. Softmax across keys turns those scores into a probability distribution. This tells each token where to look. The division by √d keeps the softmax sane at long sequence lengths."),
                DLExplanationPara(
                    kicker: "P3 · WEIGHTED VALUES",
                    body: "Multiply the scores by V and sum. Each token's new representation is a weighted average of every other token's value, weighted by how relevant that other token is. The next layer reads from this and does it all again."),
            ],
            takeaway: "Replace the loop with a look. Every modern model descends from this card."
        ),
        paperURL: "https://arxiv.org/abs/1706.03762"
    )

    // MARK: GPT-3

    static let gpt3 = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · LLMS",
        heroTitleSegments: [
            .plain("The model that learned from "),
            .highlight("one example")
        ],
        heroBody: "Same model design as before, just massively bigger. At this scale it could pick up brand new tasks from a single example you typed into the prompt.",
        sourceLine: "NeurIPS 2020 · Brown et al.",

        hookSegments: [
            .plain("What if making the model "),
            .highlight("100× bigger"),
            .plain(" let it learn from a single example?")
        ],
        hookBody: "GPT-3 is GPT-2's architecture, scaled up. No new training tricks, no new losses. At 175B parameters it could translate, summarise, and code from a few examples in the prompt, capabilities smaller models simply couldn't acquire. Across this loop you'll see what in-context learning really is, why 175 billion parameters crossed a threshold, and how the prompt itself became the new programming interface.",

        coreIdeaSegments: [
            .plain("Three things scale "),
            .highlight("unlocks")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Show it a few examples and it picks up the task",
                detail: "Show GPT-3 a few worked examples in the prompt and it picks up the task, no gradient updates, no fine tuning. The model treats the context as a runtime program. Smaller models can't do this; the ability appears around ~10B parameters."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Bigger models get steadily smarter",
                detail: "Across 8 sizes from 125M to 175B, accuracy on most tasks rises predictably with log parameters. The scaling laws turn out to be remarkably clean, and they suggested 175B wasn't even the ceiling."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Size matters more than clever tricks",
                detail: "GPT-3 reframed AI research. Maybe most progress is a function of parameters × data × compute, and architectural cleverness barely matters at scale. Half the field is still arguing about this."),
        ],

        eliAnalogyLabel: "ANALOGY · A LIBRARIAN WITH PERFECT RECALL",
        eliHeadlineSegments: [
            .plain("Imagine a librarian who "),
            .highlight("memorised the internet"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("Ask a small librarian to translate Latin and they "),
            .bold("don't know what to do"),
            .plain(". Ask one who has memorised every Latin textbook ever written, and they can "),
            .bold("imitate the patterns"),
            .plain(", not because they understand Latin, but because they've seen so many examples that the next word becomes obvious from context."),
        ],
        eliArt: .librarian,

        diagramSegments: [
            .plain("Learning without "),
            .highlight("learning")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "zero",
                label: "0-shot",
                sublabel: "no examples",
                panelTitle: "0-shot · pure instruction",
                panelBody: "\"Translate English to French: cat →\". No examples shown. GPT-3 infers the task from the instruction alone. Works on common tasks; struggles when the format is ambiguous."),
            DLDiagramNode(
                id: "one",
                label: "1-shot",
                sublabel: "one example",
                panelTitle: "1-shot · format primed",
                panelBody: "Add one worked example before the test case. The single example primes the format and disambiguates the task. Often a substantial accuracy jump from 0-shot."),
            DLDiagramNode(
                id: "few",
                label: "Few shot",
                sublabel: "k examples",
                panelTitle: "Few shot · in context learning",
                panelBody: "3 to 10 examples in the prompt. The model extracts the pattern and applies it. No weights change. This is the regime where GPT-3 dominates supervised baselines on many tasks."),
            DLDiagramNode(
                id: "scale",
                label: "Scale",
                sublabel: "175B params",
                panelTitle: "Scale · the prerequisite",
                panelBody: "None of this works at 1.3B. At 13B it kind of works. At 175B it works well. In context learning is an emergent capability, not a continuous improvement, but a phase transition past a parameter threshold."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four shot regimes plus the parameter threshold that enables them. Tap each.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · CAPABILITY VS SCALE",
                titleSegments: [
                    .plain("Few shot accuracy "),
                    .highlight("scales with size")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Few shot accuracy (%)",
                    primaryLabel: "GPT-3",
                    secondaryLabel: nil,
                    yMax: 80,
                    yTickLabels: ["0%", "40%", "80%"],
                    points: [
                        DLBarPoint(label: "125M", sublabel: "small", primary: 9, secondary: nil,
                                   annotation: "125M parameters: barely works. Few shot examples confuse the model more than help."),
                        DLBarPoint(label: "1.3B", sublabel: nil, primary: 23, secondary: nil,
                                   annotation: "1.3B: starting to follow patterns. Few shot shows up as a small improvement over zero shot."),
                        DLBarPoint(label: "13B", sublabel: nil, primary: 41, secondary: nil,
                                   annotation: "13B: in context learning is clearly working. The model recognises the task from examples."),
                        DLBarPoint(label: "175B", sublabel: "GPT-3", primary: 65, secondary: nil,
                                   annotation: "175B: GPT-3 proper. Few shot accuracy is now competitive with fine tuned BERT on many tasks, without any gradient steps."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any size. The curve isn't linear; it bends upward, every order of magnitude buys disproportionate capability."
                )),
                caption: "Average few shot accuracy across the suite of GPT-3 evaluations. Each 10× in parameters buys roughly +20 points.",
                takeaway: "Scale isn't quantity. Past a threshold, it's quality."
            ),
            DLVizCard(
                kicker: "CARD 06 · SHOT COUNT MATTERS",
                titleSegments: [
                    .plain("Examples in the prompt "),
                    .highlight("are the loop")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Accuracy (%)",
                    primaryLabel: "175B",
                    secondaryLabel: "1.3B",
                    yMax: 80,
                    yTickLabels: ["0%", "40%", "80%"],
                    points: [
                        DLBarPoint(label: "0-shot", sublabel: nil, primary: 50, secondary: 12,
                                   annotation: "0-shot: instruction only. 175B at 50%, 1.3B at 12%. The big model already follows instructions; the small one barely does."),
                        DLBarPoint(label: "1-shot", sublabel: nil, primary: 60, secondary: 18,
                                   annotation: "1-shot: one example added. 175B jumps to 60%; 1.3B inches up. The big model uses the example; the small one mostly ignores it."),
                        DLBarPoint(label: "10-shot", sublabel: nil, primary: 68, secondary: 23,
                                   annotation: "10-shot: full in context regime. 175B at 68%; 1.3B at 23%. The gap between scales widens with more shots, not narrows."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any shot count. More examples help GPT-3 sharply; the small model barely benefits, in context learning is a scale gated capability."
                )),
                caption: "Accuracy by shot count for two model sizes. The 175B curve climbs steeply; the 1.3B curve barely budges.",
                takeaway: "Examples are programs. Only big models can run them."
            ),
        ],

        completeTakeaway: "\"GPT-3 unlocked capabilities smaller models can't acquire, no matter how long you train them.\"",
        completeNextTease: "You've finished the foundational bundle.",
        paperTitle: "Language Models are Few Shot Learners (GPT-3)",
        glossary: [
            "GPT-3":              "OpenAI's 175 billion parameter language model from 2020. Same Transformer recipe as GPT-2, scaled 100×. Famous for handling brand new tasks just from examples in the prompt.",
            "parameter":          "A single number the model learns. Think of it as one knob the network can tune. GPT-3 has 175 billion of them. More knobs means more nuanced behaviour, but also more memory and compute.",
            "parameters":         "The numbers the model learns during training. More parameters means more capacity to encode patterns. GPT-3 has 175 billion; GPT-2 had 1.5 billion.",
            "in context learning": "When a model picks up a new task from a few examples shown inside the prompt, without any weight updates. The 'learning' is happening in the prompt, not in the model.",
            "in-context learning": "When a model picks up a new task from a few examples shown inside the prompt, without any weight updates. The 'learning' is happening in the prompt, not in the model.",
            "few shot":           "A prompt that includes a small number of worked examples (typically 3 to 10) before the test question. The model uses them as a template.",
            "few-shot":           "A prompt that includes a small number of worked examples (typically 3 to 10) before the test question. The model uses them as a template.",
            "1-shot":             "A prompt with exactly one worked example before the test question. Often a big jump over zero shot because the example fixes the format.",
            "0-shot":             "A prompt with no examples, only an instruction. The model has to infer the task purely from the wording.",
            "zero shot":          "A prompt with no examples, only an instruction. The model has to infer the task purely from the wording.",
            "fine tuning":        "Training a pretrained model on a smaller task specific dataset to specialise it. GPT-3's headline result was that you could often skip this and just write a good prompt.",
            "fine-tuning":        "Training a pretrained model on a smaller task specific dataset to specialise it. GPT-3's headline result was that you could often skip this and just write a good prompt.",
            "prompt":             "The text you feed the model. Includes instructions, examples, and the test question. With GPT-3, the prompt became the new way to 'program' the model.",
            "Transformer":        "The neural network architecture (Vaswani et al., 2017) underneath GPT and most modern LLMs. Built on self attention, it scales cleanly to hundreds of billions of parameters.",
            "175B":               "Shorthand for 175 billion parameters, the size of the largest GPT-3 model. About 100× larger than GPT-2 and 10× larger than the previous biggest dense model.",
            "175 billion":        "The parameter count of the largest GPT-3 model, roughly 100× the size of GPT-2 and 10× the previous record dense model.",
            "scaling laws":       "Empirical curves showing model loss falls predictably as parameters, data, and compute grow. Discovered by Kaplan et al. and confirmed at GPT-3 scale.",
            "emergent":           "A capability that is absent in smaller models and appears suddenly past a parameter threshold. In context learning is the canonical example.",
            "emergence":          "When a capability appears suddenly past a parameter threshold rather than improving smoothly. Hard to predict from smaller models alone.",
            "BERT":               "A 2018 Transformer (Devlin et al.) trained with masked language modelling. The dominant fine tuning baseline GPT-3 was compared against, often beaten without any fine tuning.",
            "BLEU":               "A score that measures how close a machine translation is to a human reference translation. 0 to 100, higher is better.",
            "compute":            "The total number of arithmetic operations used to train or run a model, usually measured in FLOPs. Scaling laws treat compute as one of the three main inputs alongside parameters and data.",
            "tokens":             "The chunks of text a language model reads and writes, typically sub words. GPT-3 was trained on roughly 300 billion tokens.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why 175 billion parameters changed everything",
                gloss: "Capabilities emerged that smaller models couldn't reach with any amount of training."),
            DLObjective(
                text: "What in-context learning actually is",
                gloss: "The model picks up new tasks from examples in the prompt. Zero weight updates."),
            DLObjective(
                text: "Where fine-tuning lost its monopoly",
                gloss: "A well-written prompt often beats a fine-tuned smaller model. Programming-by-prompt."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Scale crossed "),
                .highlight("a threshold"),
            ],
            mini: .gpt3,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · SCALE",
                    body: "GPT-3 is the same Transformer recipe from 2017, scaled roughly 100× larger than GPT-2. No new architecture, no new loss function. Just more parameters, more data, more compute. The interesting part is what scale alone unlocked."),
                DLExplanationPara(
                    kicker: "P2 · IN-CONTEXT LEARNING",
                    body: "Show GPT-3 a handful of input-output examples in the prompt, then a new input. It produces the correct output without any gradient updates. The model treats the examples as a template it should imitate. This is not training. It is reading."),
                DLExplanationPara(
                    kicker: "P3 · EMERGENCE",
                    body: "Arithmetic, translation between dozens of language pairs, basic code completion, none of these were trained for. They emerged from next-token prediction at scale. Smaller models showed no trace of them. Past a parameter threshold, capability appears."),
            ],
            takeaway: "The prompt is the new program. The model is the new compiler."
        ),
        paperURL: "https://arxiv.org/abs/2005.14165"
    )

    // MARK: BERT (Devlin et al. 2018)

    static let bert = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · LANGUAGE",
        heroTitleSegments: [
            .plain("Read both sides "),
            .highlight("at once")
        ],
        heroBody: "The encoder that learned by filling in blanks, then powered every NLP task with one shared body and a tiny task-specific head.",
        sourceLine: "NAACL 2019 · Devlin, Chang, Lee, Toutanova",

        hookSegments: [
            .plain("What if a model trained itself by "),
            .highlight("filling in the blanks"),
            .plain("?")
        ],
        hookBody: "Before BERT, language models read left to right. To work out the next word, they had no idea what came after it. BERT hid 15% of tokens at random and trained the model to guess them using everything on both sides. No human labels, just billions of self-supplied cloze tests. The pretrained body then served every downstream task with just a small head added on top.",

        coreIdeaSegments: [
            .plain("Three moves that "),
            .highlight("changed NLP")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Hide some words, predict them",
                detail: "Masked language modelling: mask 15 percent of input tokens, then train the model to recover them. Free supervision from the text itself, scales to any corpus."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Look both ways at every step",
                detail: "The encoder is a stack of self-attention layers; each token mixes information from every other token in one shot, left and right. Bidirectional context drops in for free."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Pretrain once, fine-tune anywhere",
                detail: "After pretraining, swap the vocabulary head for a tiny task head. Q&A, sentiment, NER, entailment, all reuse the same body. Set the state of the art on 11 benchmarks at once."),
        ],

        eliAnalogyLabel: "ANALOGY · A CLOZE TEST",
        eliHeadlineSegments: [
            .plain("Imagine a language exam where you "),
            .highlight("fill in the blanks"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("Old language models read the page "),
            .bold("one finger, one direction"),
            .plain(". BERT trained on cloze tests: hide a word at random, see what comes "),
            .bold("before and after"),
            .plain(", and guess. Do that ten billion times and the model has soaked up enough about language to ace any short test you throw at it."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [
            .plain("How one body "),
            .highlight("becomes many tasks")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "mlm",
                label: "MLM",
                sublabel: "mask 15%",
                panelTitle: "Masked language modelling",
                panelBody: "The pretraining objective. Hide 15 percent of the tokens at random and ask the model to recover each one from the surrounding context, both sides. Free supervision: every sentence on the internet supplies its own answers."),
            DLDiagramNode(
                id: "bi",
                label: "Bidirectional",
                sublabel: "self-attention",
                panelTitle: "Bidirectional encoder",
                panelBody: "Each layer is multi-head self-attention. Every token sees every other token in the input in one step. There is no reading order, so the representation of any word mixes its left and right neighbours equally."),
            DLDiagramNode(
                id: "body",
                label: "Body",
                sublabel: "110M params",
                panelTitle: "Pretrained body",
                panelBody: "Twelve transformer layers, 110 million parameters for BERT-Base; 24 layers and 340M for BERT-Large. After pretraining on Wikipedia and BookCorpus, this stack is a general-purpose text reader."),
            DLDiagramNode(
                id: "head",
                label: "Head",
                sublabel: "per task",
                panelTitle: "Fine-tune head",
                panelBody: "A tiny task-specific output layer. For sentiment, one classifier on the [CLS] token. For NER, one classifier per token. For Q&A, two pointers, start and end. A few epochs of fine-tuning and the whole stack does the task."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four pieces of the BERT recipe. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · ELEVEN BENCHMARKS",
                titleSegments: [
                    .plain("New record on "),
                    .highlight("every leaderboard")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Score",
                    primaryLabel: "BERT-Large",
                    secondaryLabel: "Previous SOTA",
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "GLUE",   sublabel: "9 tasks", primary: 80.5, secondary: 75.1,
                                   annotation: "GLUE average across 9 sentence and sentence-pair tasks. BERT-Large jumped 5+ points over the prior best."),
                        DLBarPoint(label: "SQuAD",  sublabel: "Q&A v1", primary: 93.2, secondary: 91.7,
                                   annotation: "SQuAD v1 F1: extractive question answering. BERT-Large passed the published human baseline."),
                        DLBarPoint(label: "SQuAD2", sublabel: "Q&A v2", primary: 83.1, secondary: 73.0,
                                   annotation: "SQuAD v2 F1: harder, includes unanswerable questions. BERT opened a 10-point gap over the prior best."),
                        DLBarPoint(label: "NER",    sublabel: "CoNLL", primary: 92.8, secondary: 92.6,
                                   annotation: "Named-entity recognition on CoNLL-2003. Less headroom here; even so, BERT eked out a new high."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any benchmark. BERT lifted the state of the art on 11 NLP tasks in one paper."
                )),
                caption: "Four representative benchmarks. The teal bars are BERT-Large; the amber are the best previous numbers.",
                takeaway: "One pretrained body, every task lifted at once."
            ),
            DLVizCard(
                kicker: "CARD 06 · WHY MASKING MATTERS",
                titleSegments: [
                    .plain("Bidirectional beats "),
                    .highlight("one direction")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "MNLI accuracy",
                    primaryLabel: "Variant",
                    secondaryLabel: nil,
                    yMax: 90,
                    yTickLabels: ["70", "80", "90"],
                    points: [
                        DLBarPoint(label: "L→R", sublabel: "GPT-style", primary: 82.1, secondary: nil,
                                   annotation: "Same architecture, trained left-to-right only. Strong but ceilinged: at every step the model is blind to the right side."),
                        DLBarPoint(label: "BiLM", sublabel: "ELMo-style", primary: 83.4, secondary: nil,
                                   annotation: "Two LMs run separately then concatenated. Each half is still one-directional; the join is shallow."),
                        DLBarPoint(label: "MLM", sublabel: "BERT", primary: 86.6, secondary: nil,
                                   annotation: "Masked LM. One model, both sides used at every layer. Several accuracy points clear of the unidirectional alternatives."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "bidir",
                    defaultInsight: "Same data, same params, three pretraining objectives. The bidirectional objective wins."
                )),
                caption: "Ablation from the original paper. The objective is what matters; the architecture is the same.",
                takeaway: "The breakthrough was the training task, not the network."
            ),
        ],

        completeTakeaway: "\"BERT does not write. It reads, deeply, both ways.\"",
        completeNextTease: "Up next: the line BERT and GPT-3 both ride, scaled.",
        paperTitle: "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
        glossary: [
            "BERT":            "Bidirectional Encoder Representations from Transformers. A 2018 model from Google that pretrained on a fill-in-the-blank task and powered most NLP systems for years after.",
            "masked language modelling": "The pretraining task. Hide 15 percent of input tokens at random, ask the model to predict them from the surrounding words on both sides.",
            "MLM":             "Short for masked language modelling, BERT's pretraining task.",
            "[MASK]":          "The placeholder symbol that takes the place of a hidden token during pretraining. The model never sees it at fine-tune time.",
            "[CLS]":           "A special token added to the front of every input. Its output vector serves as a summary of the whole sentence for classification.",
            "[SEP]":           "A separator token. Marks the boundary between two sentences in pair tasks like entailment or Q&A.",
            "bidirectional":   "Reading both directions at once. Every token mixes information from the words to its left and to its right in one step.",
            "pretraining":     "A long, expensive training run on a huge generic corpus. Teaches the model the shape of language with no task in mind.",
            "fine tuning":     "A short follow-up training run on a small task-specific dataset. Keeps the pretrained body, adds a small task head, and adjusts a few epochs.",
            "fine-tuning":     "A short follow-up training run on a small task-specific dataset. Keeps the pretrained body, adds a small task head, and adjusts a few epochs.",
            "encoder":         "A network that maps an input sequence to a sequence of context-rich vectors. BERT is encoder-only.",
            "next sentence prediction": "A second pretraining task: given two sentences, predict whether the second follows the first. Helped early but later models dropped it.",
            "NSP":             "Next sentence prediction. The auxiliary pretraining task BERT used alongside MLM.",
            "GLUE":            "A nine-task benchmark suite for English natural-language understanding. BERT topped it on release.",
            "SQuAD":           "Stanford Question Answering Dataset. Extractive Q&A: pick the answer span out of a passage.",
            "NER":             "Named-entity recognition. Tag each token with a category like PERSON, LOCATION, ORGANIZATION.",
            "WordPiece":       "BERT's sub-word tokenizer. Breaks rare words into common pieces so the vocabulary stays around thirty thousand tokens.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why filling in blanks teaches a model language",
                gloss: "Masked language modelling: hide tokens, recover them from both sides. Self-supervised at internet scale."),
            DLObjective(
                text: "What 'bidirectional' actually buys you",
                gloss: "Every token mixes left and right neighbours in one step. Reading comprehension jumps over one-direction baselines."),
            DLObjective(
                text: "How one pretrained body fits every downstream task",
                gloss: "Bolt a tiny head on top, fine-tune for a few epochs. The recipe every encoder model since has used."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("One body, "),
                .highlight("both sides, every task"),
            ],
            mini: .bert,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · CLOZE PRETRAIN",
                    body: "BERT trained on a single task: fill in 15 percent of the tokens that were hidden at random. The labels came from the text itself, which meant the model could chew through Wikipedia and BookCorpus end to end with no human in the loop."),
                DLExplanationPara(
                    kicker: "P2 · BIDIRECTIONAL ENCODER",
                    body: "Because every prediction needed both sides of every blank, the encoder learned to mix information across the whole input in one step. There was no reading order. The same self-attention layers from Vaswani et al. (2017), trained on a new objective."),
                DLExplanationPara(
                    kicker: "P3 · ONE BODY, MANY HEADS",
                    body: "After pretraining, every downstream task just bolted a tiny head onto the same body. A classifier on [CLS] for sentiment, two pointers for Q&A, a per-token tagger for NER. Eleven benchmarks fell to one recipe."),
            ],
            takeaway: "BERT did not write. It read everything, both ways, and made every reader smarter."
        ),
        paperURL: "https://arxiv.org/abs/1810.04805"
    )
}
