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
        case "instructgpt": content = .instructGPT
        case "chain-of-thought": content = .chainOfThought
        case "scratchpad": content = .scratchpad
        case "self-consistency": content = .selfConsistency
        case "tot": content = .treeOfThoughts
        case "least-to-most": content = .leastToMost
        case "react": content = .reAct
        case "toolformer": content = .toolformer
        case "grokking": content = .grokking
        case "deepseek-r1": content = .deepseekR1
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

    // MARK: DeepSeek-R1 (DeepSeek-AI 2025)

    static let deepseekR1 = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("Learn to think from "),
            .highlight("a reward")
        ],
        heroBody: "The reasoning model that skipped worked examples entirely: reward right answers, and step-by-step thinking, self-checking, and longer deliberation grow on their own.",
        sourceLine: "arXiv:2501.12948 · DeepSeek-AI",

        hookSegments: [
            .plain("What if a model learned to reason with "),
            .highlight("no worked examples"),
            .plain("?")
        ],
        hookBody: "Before R1, you taught reasoning by showing a model thousands of human-written solutions to copy. R1 asked a bolder question: skip the examples, just reward the right final answer. The first version, R1-Zero, trained on pure reinforcement learning and spontaneously taught itself to write long chains of thought, backtrack, and verify its own work. The full R1 then cleaned that up with a small readable warm-up and distilled the skill into small, cheap models.",

        coreIdeaSegments: [
            .plain("Three moves that "),
            .highlight("grew reasoning")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Reward the answer, not the method",
                detail: "Pure reinforcement learning on a base model. The only signal is whether the final answer is correct and well-formatted. No worked solutions, no human reasoning to imitate. Good thinking habits emerge because they earn the reward."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Judge against the group (GRPO)",
                detail: "Group Relative Policy Optimization samples a group of answers per question and scores each against the group's own average. That free baseline replaces the heavy critic network PPO needs, making RL on a giant model affordable."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Then distill it down",
                detail: "R1's reasoning is distilled into small dense models (1.5B to 70B). The distilled models out-reason far larger ones, showing reasoning can be transferred cheaply, not just bought with scale."),
        ],

        eliAnalogyLabel: "ANALOGY · LEARNING MATHS",
        eliHeadlineSegments: [
            .plain("Like getting good at maths from "),
            .highlight("right or wrong"),
            .plain(" alone.")
        ],
        eliBodyParts: [
            .plain("Nobody handed you the one perfect method for times tables. A teacher just said "),
            .bold("right or wrong"),
            .plain(", and chasing that, you invented your own tricks: round up then subtract, double and check the answer back. R1 learned to reason the same way, "),
            .bold("millions of times over"),
            .plain(", with only a score on the final answer to guide it."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [
            .plain("How a reward "),
            .highlight("becomes reasoning")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "rl",
                label: "RL",
                sublabel: "reward only",
                panelTitle: "Reinforcement learning",
                panelBody: "Start from a base language model. Give it problems with checkable answers (maths, code). Reward = did it get the right answer in the right format? No worked solutions are ever shown. The model just tries, scores, and shifts toward what worked."),
            DLDiagramNode(
                id: "grpo",
                label: "GRPO",
                sublabel: "group baseline",
                panelTitle: "Group Relative Policy Optimization",
                panelBody: "For each question the model writes a group of answers. Each answer's reward is compared to the group's average, so above-average answers are reinforced and below-average ones discouraged. The group is its own yardstick, so there is no separate value or critic network to train."),
            DLDiagramNode(
                id: "aha",
                label: "Aha",
                sublabel: "self-check",
                panelTitle: "Emergent reasoning",
                panelBody: "Nobody programmed it to think longer. Chasing the reward, R1-Zero began allocating more thinking to harder problems and spontaneously wrote self-checks like 'wait, let me re-verify'. The paper calls this the aha moment: reasoning behaviour that emerged on its own."),
            DLDiagramNode(
                id: "distill",
                label: "Distill",
                sublabel: "to small models",
                panelTitle: "Distillation",
                panelBody: "The big R1's reasoning traces are used to fine-tune small dense models (Qwen and Llama, 1.5B to 70B). These distilled students inherit the reasoning and beat much larger non-reasoning models, so the capability spreads cheaply."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four stages of the R1 recipe. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · IT ACTUALLY WORKED",
                titleSegments: [
                    .plain("Reward alone "),
                    .highlight("closed the gap")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "AIME 2024 (pass@1)",
                    primaryLabel: "Accuracy",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Base", sublabel: "DeepSeek-V3", primary: 39.2, secondary: nil,
                                   annotation: "The base model before any reasoning RL. Competent, but it stumbles on hard competition maths."),
                        DLBarPoint(label: "R1-Zero", sublabel: "pure RL", primary: 71.0, secondary: nil,
                                   annotation: "Pure reinforcement learning, no worked examples. Accuracy nearly doubled just from rewarding correct answers."),
                        DLBarPoint(label: "R1", sublabel: "full recipe", primary: 79.8, secondary: nil,
                                   annotation: "Adds a small readable warm-up then more RL. Matches the strongest closed reasoning models of its day."),
                        DLBarPoint(label: "o1", sublabel: "OpenAI", primary: 79.2, secondary: nil,
                                   annotation: "OpenAI's o1, the leading closed reasoning model at release. R1 reached it with open weights."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "pure RL",
                    defaultInsight: "Tap any bar. The jump from Base to R1-Zero came from reward alone, with no human reasoning to copy."
                )),
                caption: "Pass@1 on AIME 2024, a hard competition-maths benchmark. Numbers are representative of the paper's reported results.",
                takeaway: "Reasoning grew from reward, not from imitation."
            ),
            DLVizCard(
                kicker: "CARD 06 · IT LEARNED TO THINK LONGER",
                titleSegments: [
                    .plain("Thinking "),
                    .highlight("grew on its own")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "RL training steps →",
                    yAxisLabel: "avg thinking length →",
                    xTickLabels: ["start", "mid", "late"],
                    yTickLabels: ["short", "", "long"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Response length",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.08, milestone: "start",
                                                     annotation: "Early on, answers are short, around a hundred tokens. The model mostly guesses."),
                                DLTrainingCurvePoint(x: 0.35, y: 0.28, milestone: nil,
                                                     annotation: "As reward favours correct answers, the model starts writing out more steps."),
                                DLTrainingCurvePoint(x: 0.62, y: 0.58, milestone: "aha",
                                                     annotation: "The aha moment: self-checks and backtracking appear with no prompting. Thinking gets noticeably longer."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.95, milestone: "late",
                                                     annotation: "By late training, the model deliberates over thousands of tokens on the hardest problems, then verifies its answer."),
                            ])
                    ],
                    defaultInsight: "Tap a point. Nobody set a target length. The thinking grew because longer, checked reasoning earned more reward."
                )),
                caption: "Average response length over RL training, sketched from the paper's R1-Zero curve.",
                takeaway: "Longer deliberation was emergent, never an instruction."
            ),
        ],

        completeTakeaway: "\"R1 was not shown how to think. It was rewarded for thinking well, and the rest grew itself.\"",
        completeNextTease: "Up next: the reasoning frontier this opened.",
        paperTitle: "DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning",
        glossary: [
            "DeepSeek-R1":    "A 2025 open-weights reasoning model from DeepSeek-AI, trained with reinforcement learning to think step by step.",
            "R1-Zero":        "The first version, trained with pure reinforcement learning and no worked examples. It learned to reason but its writing was messy and mixed languages.",
            "reinforcement learning": "Learning from rewards rather than answer keys. The model tries something, gets a score, and shifts toward whatever scored higher.",
            "RL":             "Short for reinforcement learning.",
            "reward":         "The single number telling the model how good an attempt was. For R1 it is mostly: correct final answer, in the right format.",
            "GRPO":           "Group Relative Policy Optimization. The model writes a group of answers per question and judges each against the group's own average, removing the need for a separate critic network.",
            "chain of thought": "The model writing its reasoning out step by step before giving a final answer.",
            "aha moment":     "The point in R1-Zero's training where it spontaneously began re-checking and backtracking on its own, with no instruction to do so.",
            "distillation":   "Training a smaller model to copy a larger model's behaviour, so the small one reasons almost as well far more cheaply.",
            "cold start":     "A small batch of clean, readable example reasoning used to warm up R1 before RL, fixing R1-Zero's messy output.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why a reward can teach reasoning with no examples",
                gloss: "Pure RL on right/wrong answers. Good thinking habits emerge because they earn the reward."),
            DLObjective(
                text: "What GRPO does and why it's cheaper",
                gloss: "Judge a group of answers against their own average. No separate critic network to train."),
            DLObjective(
                text: "How the 'aha moment' and distillation followed",
                gloss: "Self-checking emerged on its own, then distilled into small models that out-reason bigger ones."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("A reward, "),
                .highlight("and reasoning grew"),
            ],
            mini: .deepseekR1,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · REWARD ONLY",
                    body: "R1-Zero started from a plain base model and trained with reinforcement learning on problems with checkable answers. The only signal was whether the final answer was right and well-formatted. No human reasoning was ever shown to copy."),
                DLExplanationPara(
                    kicker: "P2 · GRPO BASELINE",
                    body: "For each question the model wrote a group of answers and scored each against the group's own average. That free baseline replaced PPO's separate critic network, which is what made reinforcement learning on a model this large affordable."),
                DLExplanationPara(
                    kicker: "P3 · EMERGE, THEN DISTILL",
                    body: "Chasing the reward, the model began thinking longer and checking its own work, the aha moment. The full R1 then cleaned this up with a small readable warm-up, and the reasoning was distilled into small dense models that beat far larger ones."),
            ],
            takeaway: "R1 was rewarded for thinking well, and the long, self-checking reasoning grew itself."
        ),
        paperURL: "https://arxiv.org/abs/2501.12948"
    )

    static let instructGPT = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · LANGUAGE",
        heroTitleSegments: [
            .plain("Teach a model to "),
            .highlight("follow you")
        ],
        heroBody: "GPT-3 knew a great deal but often ignored what you actually asked. InstructGPT closed that gap with human feedback, and a 1.3B model ended up preferred over the 175B GPT-3.",
        sourceLine: "arXiv:2203.02155 · OpenAI",

        hookSegments: [
            .plain("What if the model is huge, but still "),
            .highlight("won't listen"),
            .plain("?")
        ],
        hookBody: "A raw language model is trained to predict the next likely word, not to do what you ask. So GPT-3 could be fluent and knowledgeable yet unhelpful: rambling, ignoring the instruction, or making things up. InstructGPT fixed this with a three step recipe. Show it good answers (SFT), have people rank its tries to train a reward model, then use reinforcement learning to nudge it toward what people preferred. The aligned model was more helpful, more truthful, and slightly less toxic.",

        coreIdeaSegments: [
            .plain("Three moves that "),
            .highlight("aligned the model")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Show good answers (SFT)",
                detail: "Labelers write ideal responses to real prompts, and GPT-3 is fine-tuned to imitate them. This supervised fine-tuning teaches the model the basic shape of being helpful."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Rank, then score (reward model)",
                detail: "For a prompt the model writes several answers and people rank them best to worst. Those rankings train a reward model that can score any new answer the way people would, no rulebook required."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Nudge toward preferred (RLHF)",
                detail: "Reinforcement learning optimizes the model against the reward model: generate, score, nudge. A KL penalty keeps it close to the sensible SFT model so it improves without drifting into nonsense."),
        ],

        eliAnalogyLabel: "ANALOGY · TRAINING A NEW COOK",
        eliHeadlineSegments: [
            .plain("Like coaching a cook by "),
            .highlight("ranking the dishes"),
        ],
        eliBodyParts: [
            .plain("You can't hand someone a formula for a "),
            .bold("delicious"),
            .plain(" meal. But taste a few of their dishes and you can easily say which is best and which is worst. Do that often enough and the cook learns your taste, then chases it on dishes you have never tried. InstructGPT trained a model the same way: people "),
            .bold("ranked"),
            .plain(" answers, and the model learned to cook to that taste."),
        ],
        eliArt: .kitchen,

        diagramSegments: [
            .plain("How feedback "),
            .highlight("becomes alignment")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "sft",
                label: "SFT",
                sublabel: "show good answers",
                panelTitle: "Supervised fine-tuning",
                panelBody: "Labelers write ideal answers to a set of real prompts. GPT-3 is fine-tuned to imitate them. This gives the model a first sense of what a helpful, on-instruction answer looks like, before any reward is involved."),
            DLDiagramNode(
                id: "rm",
                label: "Reward",
                sublabel: "rank, then score",
                panelTitle: "Reward model",
                panelBody: "For each prompt the model writes several answers. People rank them best to worst, which is far easier than writing a rule for quality. Those rankings train a reward model that assigns any answer a score matching human preference, even on prompts nobody ranked."),
            DLDiagramNode(
                id: "rlhf",
                label: "RLHF",
                sublabel: "generate, score, nudge",
                panelTitle: "Reinforcement learning from human feedback",
                panelBody: "The model generates an answer, the reward model scores it, and PPO nudges the model toward higher-scoring replies. A KL penalty leashes it to the SFT model so it keeps improving without producing gibberish."),
            DLDiagramNode(
                id: "win",
                label: "Result",
                sublabel: "small beats big",
                panelTitle: "Alignment beats raw size",
                panelBody: "A 1.3B InstructGPT was preferred by labelers over the 175B GPT-3, a model a hundred times larger. It was also more truthful and slightly less toxic. How you tune mattered more than how big you built."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four stages of the InstructGPT recipe. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · SMALL BEAT BIG",
                titleSegments: [
                    .plain("Tuning beat "),
                    .highlight("raw scale")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "preferred vs 175B GPT-3 (%)",
                    primaryLabel: "Win rate",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "GPT-3", sublabel: "175B raw", primary: 50.0, secondary: nil,
                                   annotation: "The baseline. By definition it ties with itself, so this is the 50% line every other bar is measured against."),
                        DLBarPoint(label: "GPT-3+", sublabel: "175B prompted", primary: 57.0, secondary: nil,
                                   annotation: "Carefully prompting raw GPT-3 helps a little, but it still trails the tuned models by a wide margin."),
                        DLBarPoint(label: "Instruct", sublabel: "1.3B tuned", primary: 76.0, secondary: nil,
                                   annotation: "The headline result. A model one hundred times smaller, tuned with human feedback, was preferred over raw GPT-3 most of the time."),
                        DLBarPoint(label: "Instruct", sublabel: "175B tuned", primary: 85.0, secondary: nil,
                                   annotation: "Tuning the full-size model preferred even more often. Alignment compounds with scale, but the tuning is what does the work."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "1.3B tuned",
                    defaultInsight: "Tap any bar. A tuned 1.3B model beat the raw 175B GPT-3, so alignment, not size, drove the gain."
                )),
                caption: "Share of outputs labelers preferred over raw 175B GPT-3. Numbers are representative of the paper's reported results.",
                takeaway: "Past a point, how you align beats how big you build."
            ),
            DLVizCard(
                kicker: "CARD 06 · IT MADE FEWER THINGS UP",
                titleSegments: [
                    .plain("More helpful, "),
                    .highlight("more honest")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "makes things up (%)",
                    primaryLabel: "Hallucination",
                    secondaryLabel: nil,
                    yMax: 50,
                    yTickLabels: ["0", "25", "50"],
                    points: [
                        DLBarPoint(label: "GPT-3", sublabel: "175B raw", primary: 41.0, secondary: nil,
                                   annotation: "On closed-domain tasks, raw GPT-3 invents facts that were never in the source about 41% of the time."),
                        DLBarPoint(label: "Instruct", sublabel: "175B tuned", primary: 21.0, secondary: nil,
                                   annotation: "After alignment, the same size model fabricates roughly half as often. Following intent includes sticking to what is actually there."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "tuned",
                    defaultInsight: "Tap a bar. Lower is better here. Alignment roughly halved how often the model made things up."
                )),
                caption: "Hallucination rate on closed-domain tasks, lower is better. Numbers are representative of the paper's reported results.",
                takeaway: "Aligning to human intent also made it more truthful."
            ),
        ],

        completeTakeaway: "\"InstructGPT was not made smarter. It was tuned to do what people asked, and that made it far more useful.\"",
        completeNextTease: "Up next: the assistants this recipe unlocked.",
        paperTitle: "Training language models to follow instructions with human feedback",
        glossary: [
            "InstructGPT":   "A 2022 OpenAI model that fine-tuned GPT-3 with human feedback to follow instructions. The direct ancestor of ChatGPT.",
            "alignment":     "Making a model do what people actually want (helpful, honest, harmless), not just predict likely text.",
            "RLHF":          "Reinforcement learning from human feedback. Train a reward model from human rankings, then use reinforcement learning to push the model toward higher-scoring answers.",
            "SFT":           "Supervised fine-tuning. Fine-tune the model to imitate human-written ideal answers.",
            "supervised fine-tuning": "Fine-tuning the model on human-written example answers so it learns the basic shape of a helpful reply.",
            "reward model":  "A model trained from human rankings that scores how good any answer is, standing in for a human rater.",
            "PPO":           "Proximal Policy Optimization, the reinforcement learning algorithm used to nudge the model toward higher reward.",
            "human feedback": "People comparing and ranking model answers, the raw material the reward model learns from.",
            "comparison data": "Sets of answers to the same prompt, ranked by people, used to train the reward model.",
            "KL penalty":    "A leash that keeps the tuned model from drifting too far from the sensible SFT model while chasing reward.",
            "labeler":       "A person hired to write example answers and rank model outputs.",
            "hallucination": "When a model states something false or unsupported as if it were fact.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why a bigger model is not automatically more useful",
                gloss: "Raw models predict likely text, which is not the same as following your instruction."),
            DLObjective(
                text: "How ranking answers builds a reward model",
                gloss: "People rank instead of defining quality, and those rankings train a model that can score any answer."),
            DLObjective(
                text: "How RLHF nudges the model toward what people prefer",
                gloss: "Generate, score with the reward model, nudge, with a KL leash to stay sensible."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Feedback, "),
                .highlight("and it listened"),
            ],
            mini: .instructGPT,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · SHOW GOOD",
                    body: "First, labelers wrote ideal answers to real prompts and GPT-3 was fine-tuned to imitate them. This SFT step gave the model a starting sense of what a helpful, on-instruction answer looks like."),
                DLExplanationPara(
                    kicker: "P2 · RANK, THEN SCORE",
                    body: "Then people ranked several answers per prompt best to worst, which is far easier than writing a rule for quality. Those rankings trained a reward model that scores any answer the way people would."),
                DLExplanationPara(
                    kicker: "P3 · NUDGE",
                    body: "Finally, reinforcement learning pushed the model toward higher-scoring replies, with a KL leash to the SFT model. The aligned 1.3B model was preferred over the 175B GPT-3, and made things up less often."),
            ],
            takeaway: "InstructGPT was tuned with human feedback to do what people asked, and that beat raw size."
        ),
        paperURL: "https://arxiv.org/abs/2203.02155"
    )

    static let scratchpad = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("Give the model "),
            .highlight("a notepad")
        ],
        heroBody: "Forced to answer in one shot, a model fails long calculations because it has nowhere to put the working. Let it write intermediate steps on a scratchpad and it works the problem out, holding up even as the input grows.",
        sourceLine: "arXiv:2112.00114 · Google",

        hookSegments: [
            .plain("What if the model just needed "),
            .highlight("somewhere to write"),
            .plain("?")
        ],
        hookBody: "Try multiplying two three-digit numbers in your head. Hard, because the half-finished pieces slip away. On paper it is easy. A language model has the same bottleneck: asked for the answer in one shot, it has no room to compute intermediate values, so it guesses and misses on long, algorithmic problems. The fix is a scratchpad: train the model to emit the working step by step before the answer. It then solves long addition, evaluates polynomials, and even executes code by tracing each variable, and it keeps working as the inputs get longer.",

        coreIdeaSegments: [
            .plain("Three things the pad "),
            .highlight("unlocks")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Room to compute",
                detail: "Answering in one shot means holding the entire calculation in a single forward pass. The scratchpad lets the model write partial results and carries down, so no single step has to do everything at once."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Taught by example",
                detail: "The model does not reach for paper on its own. It is trained on examples that include the full working between question and answer, so it learns to lay out its own steps before answering."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "It holds up at length",
                detail: "Because a longer problem is just more of the same small steps, the scratchpad keeps near-perfect accuracy on inputs far longer than anything in training, where one-shot answers collapse."),
        ],

        eliAnalogyLabel: "ANALOGY · MENTAL MATH VS PAPER",
        eliHeadlineSegments: [
            .plain("Like doing long division "),
            .highlight("on paper"),
        ],
        eliBodyParts: [
            .plain("Nobody does long division in their head. You write each step down, "),
            .bold("digit by digit"),
            .plain(", so your memory only ever holds one small thing. The scratchpad gives a model the same paper: it stops trying to leap to the answer and instead "),
            .bold("works it out"),
            .plain(", one tiny step at a time."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [
            .plain("How the pad "),
            .highlight("does the work")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "oneshot",
                label: "One shot",
                sublabel: "no room",
                panelTitle: "One shot · no room",
                panelBody: "Asked for the answer directly, the model must compute everything in a single pass. For a long sum or a program there is nowhere to hold the partial results, so it produces a fluent guess that is usually wrong."),
            DLDiagramNode(
                id: "step1",
                label: "Step",
                sublabel: "write it down",
                panelTitle: "Write the first step",
                panelBody: "With a scratchpad, the model emits the first intermediate result: the units column of a sum, or the first variable of a program. Small, bounded work that one pass can do reliably."),
            DLDiagramNode(
                id: "step2",
                label: "Step",
                sublabel: "carry forward",
                panelTitle: "Carry it forward",
                panelBody: "Each new line reads the previous one and extends it, carrying digits or updating state. The model conditions on its own written work, never on memory alone, so nothing gets dropped."),
            DLDiagramNode(
                id: "answer",
                label: "Answer",
                sublabel: "read it off",
                panelTitle: "Read off the answer",
                panelBody: "After the working, the final answer is just the last line of the pad. Long addition, polynomial evaluation, and code execution all become reliable, and stay reliable as the input grows."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats of working on the pad. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · ROOM TO COMPUTE",
                titleSegments: [
                    .plain("Near zero, "),
                    .highlight("to near perfect")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "long-arithmetic accuracy (%)",
                    primaryLabel: "Accuracy",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "One shot", sublabel: "direct", primary: 9.0, secondary: nil,
                                   annotation: "Asked for the answer directly, the model has no room for the working and gets long sums wrong almost every time."),
                        DLBarPoint(label: "Scratchpad", sublabel: "with working", primary: 92.0, secondary: nil,
                                   annotation: "Allowed to write each step, the same model works the problem out and lands it. Nothing got smarter, it just got paper."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "+ pad",
                    defaultInsight: "Tap a bar. Same model, same problem. The only difference is whether it was allowed to write the working."
                )),
                caption: "Accuracy on long, multi-step arithmetic. Numbers are representative of the paper's reported results.",
                takeaway: "Room to compute, not extra intelligence, drove the jump."
            ),
            DLVizCard(
                kicker: "CARD 06 · IT HELD AT LENGTH",
                titleSegments: [
                    .plain("Stays high as inputs "),
                    .highlight("grow")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "input length →",
                    yAxisLabel: "accuracy →",
                    xTickLabels: ["1", "2", "3", "5", "8"],
                    yTickLabels: ["0", "", "100"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "One shot",
                            color: .rose,
                            dashed: true,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.99, milestone: "1 digit",
                                                     annotation: "On a one-digit sum even a one-shot answer is fine."),
                                DLTrainingCurvePoint(x: 0.4, y: 0.82, milestone: nil,
                                                     annotation: "Two digits, and one-shot accuracy already starts slipping."),
                                DLTrainingCurvePoint(x: 0.6, y: 0.47, milestone: nil,
                                                     annotation: "Three digits: about half wrong. Too much to juggle in one pass."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.02, milestone: "8 digits",
                                                     annotation: "By eight digits the one-shot answer is essentially never right."),
                            ]),
                        DLTrainingCurveSeries(
                            label: "Scratchpad",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.99, milestone: nil,
                                                     annotation: "The pad is just as good on the easy case."),
                                DLTrainingCurvePoint(x: 0.4, y: 0.98, milestone: nil,
                                                     annotation: "Two digits: barely moves. Each step is the same size as before."),
                                DLTrainingCurvePoint(x: 0.6, y: 0.97, milestone: nil,
                                                     annotation: "Three digits: still near perfect, because the work is just one more column."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.92, milestone: "8 digits",
                                                     annotation: "Eight digits, longer than its training examples, and the pad still holds. That is length generalisation."),
                            ])
                    ],
                    defaultInsight: "Tap a point. As inputs lengthen the one-shot line falls off a cliff while the scratchpad stays high."
                )),
                caption: "Accuracy against the length of the input. Sketched from the paper's length-generalisation results.",
                takeaway: "Small repeated steps make the pad barely care how long the input is."
            ),
        ],

        completeTakeaway: "\"The model was not made smarter. It was handed a notepad, and that was enough.\"",
        completeNextTease: "Up next: turning the notepad into a prompt anyone can use.",
        paperTitle: "Show Your Work: Scratchpads for Intermediate Computation with Language Models",
        glossary: [
            "scratchpad": "A place for the model to write intermediate steps before its final answer, acting like working memory for multi-step problems.",
            "intermediate steps": "The partial results, like a carry or a variable's value, written between the question and the final answer.",
            "execution trace": "The line-by-line record of a program's variables as it runs, which the model writes to the pad to predict the output.",
            "length generalisation": "Staying accurate on inputs longer than any seen in training, which scratchpads achieve by keeping each step small.",
            "one-shot answer": "Producing the final answer directly, with no written working, in a single pass.",
            "fine-tuning": "Further training a model on examples, here on examples that include the full working, so it learns to use the pad.",
            "algorithmic task": "A problem solved by a fixed procedure of steps, like long addition or running code, where scratchpads shine.",
            "forward pass": "One run of the model from input to output. Without a pad, all the computation must fit in this single pass.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why one-shot answers fail long problems",
                gloss: "There is no room to hold partial results, so the model has to guess the whole thing at once."),
            DLObjective(
                text: "How a scratchpad gives room to compute",
                gloss: "The model writes each step down and reads its own working, so no step has to do everything."),
            DLObjective(
                text: "Why it keeps working at length",
                gloss: "A longer input is just more of the same small steps, so accuracy barely drops."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It wrote the working, "),
                .highlight("and got it right"),
            ],
            mini: .scratchpad,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · NO ROOM",
                    body: "Asked for the answer in one shot, the model must compute everything in a single pass. For a long sum or a program there is nowhere to keep the partial work, so it produces a confident wrong guess."),
                DLExplanationPara(
                    kicker: "P2 · GIVE IT PAPER",
                    body: "A scratchpad lets the model emit the steps first: each column of a sum, each variable of a program. It conditions on its own written work, so nothing has to be held in memory alone."),
                DLExplanationPara(
                    kicker: "P3 · HOLDS AT LENGTH",
                    body: "Because every step stays small, the pad keeps near-perfect accuracy even on inputs far longer than its training, where one-shot answers fall to near zero."),
            ],
            takeaway: "The scratchpad gives a model room to compute, turning one impossible leap into many easy steps."
        ),
        paperURL: "https://arxiv.org/abs/2112.00114"
    )

    static let selfConsistency = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("Sample many, "),
            .highlight("then vote")
        ],
        heroBody: "A single chain of thought can take one wrong turn and confidently give a wrong answer. Sample many diverse chains and keep the answer the most of them reach, and reasoning accuracy jumps, with no new training.",
        sourceLine: "arXiv:2203.11171 · Google",

        hookSegments: [
            .plain("What if you just "),
            .highlight("asked the model again"),
            .plain("?")
        ],
        hookBody: "Chain of thought writes one line of reasoning, and if it slips on a single step the whole answer is wrong, while the model still sounds sure. Self-consistency fixes this without changing the model. Sample many chains with a little randomness so each takes a different route, then ignore the reasoning and tally the final answers. The right answer is usually reachable by many paths, while wrong answers scatter, so the majority vote is far more reliable. On grade-school maths this lifted accuracy by roughly 18 points over a single greedy chain.",

        coreIdeaSegments: [
            .plain("Three moves that "),
            .highlight("make the vote work")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Sample, don't settle",
                detail: "Instead of decoding the single most-likely chain, sample several with a little randomness so each follows its own route to an answer. Variety is the raw material the vote needs."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Marginalise over reasoning",
                detail: "Throw away how each chain got there and keep only where it landed. Tally the final answers like a ballot and take the majority. Different routes, one counted answer each."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Truth is reachable many ways",
                detail: "Correct answers tend to be reached by many distinct chains, while mistakes are scattered and rarely agree. So the most-voted answer is usually the right one, and a single slip gets outvoted."),
        ],

        eliAnalogyLabel: "ANALOGY · ASK THE ROOM",
        eliHeadlineSegments: [
            .plain("Like polling "),
            .highlight("a whole room"),
        ],
        eliBodyParts: [
            .plain("Ask one clever person and they might be wrong. Ask "),
            .bold("twenty people"),
            .plain(" who each work it out their own way, and the answer most of them reach is hard to beat. Self-consistency turns one model into that room: many independent attempts, then "),
            .bold("go with the crowd"),
            .plain("."),
        ],
        eliArt: .readers,

        diagramSegments: [
            .plain("How the vote "),
            .highlight("is taken")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "ask",
                label: "Ask once",
                sublabel: "one prompt",
                panelTitle: "One question",
                panelBody: "You start with a single problem and the same chain-of-thought prompt. Nothing about the model or the prompt changes; the only difference is how many times you ask and what you do with the answers."),
            DLDiagramNode(
                id: "sample",
                label: "Sample",
                sublabel: "many chains",
                panelTitle: "Sample many chains",
                panelBody: "Decode several reasoning chains with a little randomness so each takes a different route. Some reach the right answer, some take a wrong turn, but they are genuinely varied rather than copies."),
            DLDiagramNode(
                id: "tally",
                label: "Tally",
                sublabel: "count answers",
                panelTitle: "Tally the answers",
                panelBody: "Ignore the reasoning and look only at the final answers. Count how many chains reached each one, like collecting ballots. This is the sample-and-marginalise step."),
            DLDiagramNode(
                id: "majority",
                label: "Majority",
                sublabel: "most agreed",
                panelTitle: "Take the majority",
                panelBody: "The answer reached by the most chains wins. Because the right answer is usually reachable many ways while mistakes scatter, this beats trusting any single chain, even the most confident one."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats of sample-and-vote. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE VOTE WINS",
                titleSegments: [
                    .plain("One chain, "),
                    .highlight("then a vote")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "GSM8K maths (% correct)",
                    primaryLabel: "Accuracy",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Greedy", sublabel: "one chain", primary: 56.0, secondary: nil,
                                   annotation: "Taking the single most-likely chain of thought. One wrong turn and the answer is wrong, with no second opinion."),
                        DLBarPoint(label: "Vote", sublabel: "many chains", primary: 74.0, secondary: nil,
                                   annotation: "Sampling many chains and taking the majority answer. Same model, same prompt, roughly 18 points higher just from voting."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "+ vote",
                    defaultInsight: "Tap a bar. The only change is one chain versus a vote over many."
                )),
                caption: "Accuracy on GSM8K with one model. Numbers are representative of the paper's reported results.",
                takeaway: "Voting over many chains, not a better model, drove the gain."
            ),
            DLVizCard(
                kicker: "CARD 06 · MORE SAMPLES, MORE SURE",
                titleSegments: [
                    .plain("Accuracy climbs with "),
                    .highlight("the count")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "chains sampled →",
                    yAxisLabel: "accuracy →",
                    xTickLabels: ["1", "5", "10", "20", "40"],
                    yTickLabels: ["50", "", "80"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Self-consistency",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.10, milestone: "1",
                                                     annotation: "One chain is just plain chain of thought. No vote yet."),
                                DLTrainingCurvePoint(x: 0.3, y: 0.55, milestone: "5",
                                                     annotation: "A handful of samples already pulls the majority toward the right answer."),
                                DLTrainingCurvePoint(x: 0.55, y: 0.75, milestone: "10",
                                                     annotation: "Ten chains and the vote is markedly more reliable."),
                                DLTrainingCurvePoint(x: 0.78, y: 0.9, milestone: "20",
                                                     annotation: "Gains start to flatten. The majority is already stable."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.95, milestone: "40",
                                                     annotation: "More samples help less and less. You trade compute for reliability with diminishing returns."),
                            ])
                    ],
                    defaultInsight: "Tap a point. Accuracy rises fast with the first few samples, then plateaus."
                )),
                caption: "Accuracy against the number of sampled chains, normalised. Sketched from the paper's trend.",
                takeaway: "A few samples buy most of the gain; more bring diminishing returns."
            ),
        ],

        completeTakeaway: "\"The model did not get smarter. It got a second opinion, and a third, and then voted.\"",
        completeNextTease: "Up next: not just voting on chains, but searching a tree of them.",
        paperTitle: "Self-Consistency Improves Chain of Thought Reasoning in Language Models",
        glossary: [
            "self-consistency": "Sampling many chains of thought for one question and keeping the final answer the most of them agree on.",
            "sample and marginalise": "Generating several reasoning paths and summing over them by their answers, then taking the majority.",
            "majority vote": "Choosing the answer that the most sampled chains reached, like counting ballots.",
            "greedy decoding": "Always taking the single most-likely next token, producing one deterministic chain with no variety.",
            "temperature": "A knob on sampling randomness. Higher means more varied chains; too high turns them to noise.",
            "chain of thought": "A line of step-by-step reasoning the model writes before its answer. Self-consistency samples many of these.",
            "diversity": "How different the sampled chains are. Voting only helps when the chains genuinely vary.",
            "test-time compute": "Extra computation spent when answering rather than training. Sampling many chains is a way to spend it.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why one chain of thought is fragile",
                gloss: "A single wrong step ruins the answer, and the model still sounds confident."),
            DLObjective(
                text: "How voting recovers the right answer",
                gloss: "The truth is reachable by many routes while mistakes scatter, so the majority wins."),
            DLObjective(
                text: "Why diversity and sample count matter",
                gloss: "Identical samples cannot outvote a slip; more varied samples raise accuracy with diminishing returns."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("Many tries, "),
                .highlight("one answer"),
            ],
            mini: .selfConsistency,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · ONE IS FRAGILE",
                    body: "A single chain of thought can take one wrong turn and give a confident wrong answer. There is no second opinion to catch the slip."),
                DLExplanationPara(
                    kicker: "P2 · SAMPLE AND VOTE",
                    body: "Self-consistency samples many chains with a little randomness so they take different routes, then ignores the reasoning and tallies the final answers, keeping the majority."),
                DLExplanationPara(
                    kicker: "P3 · TRUTH AGREES",
                    body: "The right answer is usually reachable by many chains while mistakes scatter, so the vote is far more reliable. On grade-school maths it added about 18 points, with no new training."),
            ],
            takeaway: "Self-consistency trades a little extra compute for a vote, and the agreed answer beats any single chain."
        ),
        paperURL: "https://arxiv.org/abs/2203.11171"
    )

    static let treeOfThoughts = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("Reasoning as "),
            .highlight("a search")
        ],
        heroBody: "A chain of thought commits to one line of reasoning and cannot recover from a wrong turn. Tree of thoughts branches into many thoughts, judges each, prunes the dead ones, and backtracks, solving puzzles a single chain cannot.",
        sourceLine: "arXiv:2305.10601 · Princeton & DeepMind",

        hookSegments: [
            .plain("What if the model could "),
            .highlight("change its mind"),
            .plain("?")
        ],
        hookBody: "Solving a maze, you try a turn and walk back if it dead-ends. A chain of thought cannot do that: it picks one route and follows it off a cliff. Tree of thoughts lets the model explore instead. At each step it proposes several candidate thoughts, evaluates whether each can still reach the goal, prunes the hopeless branches, and backtracks when a path stalls. On the Game of 24, a model that solved about 4% of puzzles with one chain solved around 74% once it could search, with no retraining.",

        coreIdeaSegments: [
            .plain("Three parts of "),
            .highlight("the search")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Branch into thoughts",
                detail: "Instead of one next step, the model proposes several candidate thoughts from the current state. Each is a different partial path, the branches of the tree."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Judge each branch",
                detail: "The model evaluates its own partial progress, labelling a branch sure, maybe, or impossible based on whether the goal is still reachable. This is the new power a chain lacks."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Search and backtrack",
                detail: "A search keeps the promising branches, prunes the dead ones, and when a path stalls it backs up to the last good fork and tries another. A wrong move is no longer fatal."),
        ],

        eliAnalogyLabel: "ANALOGY · SOLVING A MAZE",
        eliHeadlineSegments: [
            .plain("Like backing out of "),
            .highlight("a dead end"),
        ],
        eliBodyParts: [
            .plain("Nobody solves a maze by picking one path and refusing to turn around. You try a corridor, hit a wall, "),
            .bold("walk back"),
            .plain(", and try the next. Tree of thoughts gives a model that same freedom: explore a branch, and if it dead-ends, "),
            .bold("back up and branch again"),
            .plain("."),
        ],
        eliArt: .map,

        diagramSegments: [
            .plain("How the tree "),
            .highlight("is searched")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "branch",
                label: "Branch",
                sublabel: "several thoughts",
                panelTitle: "Branch into thoughts",
                panelBody: "From the current state the model writes several candidate next thoughts instead of one. Each becomes a branch of the tree, a different partial attempt at the problem."),
            DLDiagramNode(
                id: "judge",
                label: "Judge",
                sublabel: "sure / maybe / no",
                panelTitle: "Judge each branch",
                panelBody: "The model evaluates its own partial progress on each branch, deciding whether the goal is still reachable. This self-evaluation is what a plain chain of thought never does."),
            DLDiagramNode(
                id: "prune",
                label: "Prune",
                sublabel: "drop dead ends",
                panelTitle: "Prune the dead ends",
                panelBody: "Branches judged impossible are abandoned, so no search effort is wasted on them. The frontier shrinks to only the paths where a solution might still live."),
            DLDiagramNode(
                id: "search",
                label: "Search",
                sublabel: "and backtrack",
                panelTitle: "Search and backtrack",
                panelBody: "The search keeps expanding promising branches, and when a path stalls it backtracks to the last good fork and tries another. A wrong early move can be undone, which is the whole advantage."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats of the tree search. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · SEARCH WINS",
                titleSegments: [
                    .plain("Game of 24, "),
                    .highlight("four ways")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Game of 24 solved (%)",
                    primaryLabel: "Success",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Direct", sublabel: "answer", primary: 7.0, secondary: nil,
                                   annotation: "Asking for the answer straight out. The puzzle needs several steps, so this almost never works."),
                        DLBarPoint(label: "Chain", sublabel: "one line", primary: 4.0, secondary: nil,
                                   annotation: "A single chain of thought. One wrong early move and the whole attempt is lost, with no way back."),
                        DLBarPoint(label: "Tree", sublabel: "narrow", primary: 45.0, secondary: nil,
                                   annotation: "A tree search that keeps just one branch at each step. Even a little exploration helps enormously."),
                        DLBarPoint(label: "Tree", sublabel: "wider", primary: 74.0, secondary: nil,
                                   annotation: "A wider tree that keeps several branches and backtracks. The headline result: from 4% to 74%."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "search",
                    defaultInsight: "Tap a bar. The jump comes from letting the model explore and back up, not from a bigger model."
                )),
                caption: "Share of Game of 24 puzzles solved by one model. Numbers are representative of the paper's reported results.",
                takeaway: "Turning reasoning into a search is what cracked the puzzle."
            ),
            DLVizCard(
                kicker: "CARD 06 · MORE EXPLORING, MORE SOLVED",
                titleSegments: [
                    .plain("Wider search, "),
                    .highlight("more wins")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "branches kept →",
                    yAxisLabel: "solved →",
                    xTickLabels: ["1", "2", "3", "5"],
                    yTickLabels: ["0", "", "80"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Tree of thoughts",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.05, milestone: "1",
                                                     annotation: "Keep one branch and it is close to a chain: little room to recover."),
                                DLTrainingCurvePoint(x: 0.35, y: 0.45, milestone: "2",
                                                     annotation: "Keep two and the search can already abandon a bad branch for a better one."),
                                DLTrainingCurvePoint(x: 0.65, y: 0.65, milestone: "3",
                                                     annotation: "Wider still: more of the tree explored, more puzzles cracked."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.74, milestone: "5",
                                                     annotation: "Keeping five branches reaches 74%, at the cost of more thinking per puzzle."),
                            ])
                    ],
                    defaultInsight: "Tap a point. Keeping more branches solves more, trading compute for success."
                )),
                caption: "Success against how many branches the search keeps. Sketched from the paper's results.",
                takeaway: "Width is a dial: more exploration buys more solutions, for more compute."
            ),
        ],

        completeTakeaway: "\"The model was not made smarter. It was allowed to explore, and to change its mind.\"",
        completeNextTease: "Up next: reasoning trained in, not just prompted.",
        paperTitle: "Tree of Thoughts: Deliberate Problem Solving with Large Language Models",
        glossary: [
            "tree of thoughts": "Reasoning shaped as a tree: at each step the model branches into several thoughts and a search explores them.",
            "thought": "One coherent intermediate step, like a single move in a puzzle, that forms a node in the tree.",
            "state evaluation": "The model judging a partial solution as sure, maybe, or impossible, to decide which branches to keep.",
            "pruning": "Abandoning branches judged hopeless so the search wastes no effort on them.",
            "backtracking": "Returning to an earlier fork after a path stalls, to try a different branch.",
            "search": "Systematically exploring the tree of possible thoughts, for example breadth-first or depth-first.",
            "branching factor": "How many candidate thoughts are kept at each step. Wider search solves more but costs more compute.",
            "Game of 24": "A puzzle: combine four numbers with + - times and divide to make 24. A benchmark for deliberate reasoning.",
            "deliberation": "Spending extra computation at answer time to weigh many possibilities before committing.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why a single chain can't recover",
                gloss: "It commits to one line of reasoning, so an early wrong turn is fatal."),
            DLObjective(
                text: "How self-evaluation guides a search",
                gloss: "The model labels branches sure, maybe, or impossible, so the search keeps only the live ones."),
            DLObjective(
                text: "Why backtracking unlocks hard puzzles",
                gloss: "Backing up to a good fork turns a wrong move into just one branch among many."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It explored, "),
                .highlight("then backed up"),
            ],
            mini: .treeOfThoughts,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · BRANCH",
                    body: "Instead of one next step, the model proposes several candidate thoughts from the current state, the branches of a tree of possible reasoning."),
                DLExplanationPara(
                    kicker: "P2 · JUDGE AND PRUNE",
                    body: "The model evaluates each branch as sure, maybe, or impossible based on whether the goal is still reachable, and the hopeless ones are pruned so no effort is wasted."),
                DLExplanationPara(
                    kicker: "P3 · SEARCH AND BACK UP",
                    body: "A search follows the promising branches and backtracks when a path stalls. A wrong early move is no longer fatal, which lifted Game of 24 from about 4% to 74%."),
            ],
            takeaway: "Tree of thoughts turns reasoning into a search the model can back out of, cracking puzzles a single chain cannot."
        ),
        paperURL: "https://arxiv.org/abs/2305.10601"
    )

    static let leastToMost = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("Easiest "),
            .highlight("step first")
        ],
        heroBody: "Don't solve the hard problem in one go. Break it into a list of simpler subquestions, ordered easiest first, then solve them in sequence so each answer feeds the next. This lets a model solve problems deeper than its examples.",
        sourceLine: "arXiv:2205.10625 · Google",

        hookSegments: [
            .plain("What if you "),
            .highlight("planned the steps"),
            .plain(" first?")
        ],
        hookBody: "Chain of thought reasons in one pass and tends to copy the difficulty of its examples, so it stumbles on problems harder than what it was shown. Least-to-most splits the job into two stages. First it decomposes the problem into simpler subquestions, ordered easiest to hardest. Then it solves them in sequence, feeding each answer into the next subquestion. Because the model only ever faces one small step, it generalises to problems far deeper than its examples, where chain of thought scores near zero.",

        coreIdeaSegments: [
            .plain("Two stages, "),
            .highlight("one big win")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Decompose first",
                detail: "Before solving anything, the model lists the simpler subquestions the problem breaks into, ordered easiest first. This plan is produced as an explicit step of its own."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Solve in sequence",
                detail: "It answers the subquestions one at a time, and the answer to each is substituted into the next subquestion. No single step is ever harder than one small hop."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Generalise past the examples",
                detail: "Because any problem reduces to a chain of one-step pieces, least-to-most solves cases longer and deeper than the examples in its prompt, which a single chain cannot."),
        ],

        eliAnalogyLabel: "ANALOGY · A RECIPE IN STEPS",
        eliHeadlineSegments: [
            .plain("Like following "),
            .highlight("a recipe"),
        ],
        eliBodyParts: [
            .plain("Nobody cooks a complicated dish in one motion. You "),
            .bold("break it into steps"),
            .plain(", do them in order, and each finished step sets up the next. Least-to-most gives a model that same recipe: list the small steps first, then "),
            .bold("work them in sequence"),
            .plain("."),
        ],
        eliArt: .kitchen,

        diagramSegments: [
            .plain("How it "),
            .highlight("breaks down")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "problem",
                label: "Problem",
                sublabel: "the hard one",
                panelTitle: "The hard problem",
                panelBody: "You start with a multi-step problem that a single chain of thought tends to fumble, especially if it is deeper than the examples the model was shown."),
            DLDiagramNode(
                id: "decompose",
                label: "Decompose",
                sublabel: "list subquestions",
                panelTitle: "Decompose into subquestions",
                panelBody: "Stage one. The model writes a plan: the simpler subquestions the problem breaks into, ordered easiest first. No answers yet, just the breakdown."),
            DLDiagramNode(
                id: "solve",
                label: "Solve",
                sublabel: "one at a time",
                panelTitle: "Solve in sequence",
                panelBody: "Stage two. It answers the easiest subquestion, then the next, working up the list. Each step is small enough that the model handles it reliably."),
            DLDiagramNode(
                id: "carry",
                label: "Carry",
                sublabel: "feed the next",
                panelTitle: "Carry answers forward",
                panelBody: "The answer to each subquestion is substituted into the next one before it is solved. The pieces fill in until the last subquestion is the whole problem, already worked out."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats of decompose-and-solve. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · COMPOSITION CRACKED",
                titleSegments: [
                    .plain("Where a chain "),
                    .highlight("gives up")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "compositional task solved (%)",
                    primaryLabel: "Accuracy",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "Chain", sublabel: "one pass", primary: 16.0, secondary: nil,
                                   annotation: "A single chain of thought imitates the depth of its examples and fails when the test problem is longer or deeper."),
                        DLBarPoint(label: "Least to most", sublabel: "decompose", primary: 99.0, secondary: nil,
                                   annotation: "Reducing the problem to one-step subquestions solves nearly all of them, however deep they go."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "decompose",
                    defaultInsight: "Tap a bar. On tasks built to test composition, decomposition is the difference between near-zero and near-perfect."
                )),
                caption: "Accuracy on a benchmark of problems deeper than the prompt examples. Representative of the paper's results.",
                takeaway: "Decomposing first is what unlocked the harder problems."
            ),
            DLVizCard(
                kicker: "CARD 06 · IT HELD AT DEPTH",
                titleSegments: [
                    .plain("Steady as problems "),
                    .highlight("deepen")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "problem depth →",
                    yAxisLabel: "accuracy →",
                    xTickLabels: ["2", "3", "5", "8"],
                    yTickLabels: ["0", "", "100"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Chain",
                            color: .rose,
                            dashed: true,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.90, milestone: "2",
                                                     annotation: "At the depth of the examples, a chain is fine."),
                                DLTrainingCurvePoint(x: 0.3, y: 0.60, milestone: "3",
                                                     annotation: "One step deeper than shown, and the chain starts to slip."),
                                DLTrainingCurvePoint(x: 0.65, y: 0.22, milestone: "5",
                                                     annotation: "Well beyond example depth: the chain mostly fails."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.04, milestone: "8",
                                                     annotation: "Far deeper than training, and a single chain collapses."),
                            ]),
                        DLTrainingCurveSeries(
                            label: "Least to most",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.95, milestone: nil,
                                                     annotation: "Just as strong on the shallow case."),
                                DLTrainingCurvePoint(x: 0.3, y: 0.93, milestone: nil,
                                                     annotation: "One step deeper is just one more subquestion."),
                                DLTrainingCurvePoint(x: 0.65, y: 0.90, milestone: nil,
                                                     annotation: "Still strong: each step stayed small."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.86, milestone: "8",
                                                     annotation: "Far past the example depth, decomposition still solves it."),
                            ])
                    ],
                    defaultInsight: "Tap a point. As problems deepen the chain falls off while decomposition holds."
                )),
                caption: "Accuracy against problem depth. Sketched from the paper's compositional-generalisation results.",
                takeaway: "Small one-step pieces make depth almost free."
            ),
        ],

        completeTakeaway: "\"The model did not get smarter. It was asked to break the problem down before it solved it.\"",
        completeNextTease: "Up next: reasoning that reaches out and acts on the world.",
        paperTitle: "Least-to-Most Prompting Enables Complex Reasoning in Large Language Models",
        glossary: [
            "least-to-most": "Prompting that decomposes a problem into easier subquestions, then solves them in order, each feeding the next.",
            "decomposition": "Breaking a hard problem into a list of simpler subproblems before solving any of them.",
            "subquestion": "One of the smaller questions a problem is broken into, ordered easiest first.",
            "compositional generalisation": "Solving problems that combine more steps than any example seen in training.",
            "substitution": "Slotting the answer of one subquestion into the next subquestion before solving it.",
            "chain of thought": "Step-by-step reasoning written in one pass. Least-to-most adds an explicit decomposition stage first.",
            "two-stage prompting": "First decompose the problem, then solve the subquestions in sequence.",
            "sequential solving": "Answering subproblems one at a time so each builds on the answers before it.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why a single chain stalls on deep problems",
                gloss: "It copies the depth of its examples and gives up when the problem is deeper."),
            DLObjective(
                text: "How decomposition makes steps easy",
                gloss: "Each subquestion is a small hop, and its answer feeds the next."),
            DLObjective(
                text: "Why it generalises past its examples",
                gloss: "Any problem reduces to one-step pieces, so depth barely matters."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It planned, "),
                .highlight("then solved"),
            ],
            mini: .leastToMost,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · DECOMPOSE",
                    body: "Stage one writes a plan: the simpler subquestions the problem breaks into, ordered easiest first, before any answering happens."),
                DLExplanationPara(
                    kicker: "P2 · SOLVE AND CARRY",
                    body: "Stage two answers the subquestions in sequence, substituting each answer into the next, so the model only ever faces one small step."),
                DLExplanationPara(
                    kicker: "P3 · GENERALISE",
                    body: "Because any problem reduces to one-step pieces, least-to-most solves cases far deeper than the examples, where a single chain scores near zero."),
            ],
            takeaway: "Least-to-most decomposes before it solves, turning a deep problem into a ladder of easy steps."
        ),
        paperURL: "https://arxiv.org/abs/2205.10625"
    )

    static let reAct = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("Think, "),
            .highlight("then look")
        ],
        heroBody: "A model that only reasons can talk itself into confident nonsense. ReAct interleaves a thought, an action such as a search, and an observation of the result, looping until done, so the reasoning stays anchored to real facts.",
        sourceLine: "arXiv:2210.03629 · Princeton & Google",

        hookSegments: [
            .plain("What if it could "),
            .highlight("check its work"),
            .plain("?")
        ],
        hookBody: "Chain of thought only reasons, and with nothing to check against it can reason its way to a confident wrong answer. ReAct adds the missing half. The model interleaves a thought with an action, calling a tool like a search box, then reads the observation that comes back before thinking again. The reasoning decides what to look up, and the observations feed real facts in, so the model hallucinates less and leaves a readable trail of exactly what it did and why.",

        coreIdeaSegments: [
            .plain("Three moves, "),
            .highlight("on a loop")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Thought",
                detail: "The model reasons about what it knows and what it still needs. This is where it decides the next action, rather than charging straight to an answer."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Action",
                detail: "It calls a tool, most often a search, written as text the environment runs. Acting fetches information the model could not reliably recall on its own."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Observation",
                detail: "The tool's result comes back and is fed into the next thought. This is the grounding step: a real fact that can overrule a plausible-sounding guess."),
        ],

        eliAnalogyLabel: "ANALOGY · LOOK IT UP",
        eliHeadlineSegments: [
            .plain("Like checking "),
            .highlight("the reference"),
        ],
        eliBodyParts: [
            .plain("A careful researcher does not just think harder until they feel sure. They "),
            .bold("look it up"),
            .plain(", read what they find, and adjust. ReAct gives a model that habit: reason about what is missing, "),
            .bold("go and fetch it"),
            .plain(", then reason again with the fact in hand."),
        ],
        eliArt: .librarian,

        diagramSegments: [
            .plain("How the loop "),
            .highlight("turns")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "thought",
                label: "Thought",
                sublabel: "what's missing?",
                panelTitle: "Thought",
                panelBody: "The model reasons about the question and what it still needs to answer it. Instead of guessing, it decides what action would actually help next."),
            DLDiagramNode(
                id: "action",
                label: "Action",
                sublabel: "use a tool",
                panelTitle: "Action",
                panelBody: "It writes a tool call, such as a search, as plain text. An external system runs it. This is how the model reaches beyond its own memory."),
            DLDiagramNode(
                id: "observation",
                label: "Observation",
                sublabel: "real result",
                panelTitle: "Observation",
                panelBody: "The result returns and is added to the context. A real fact now sits in front of the model, ready to correct or confirm its reasoning."),
            DLDiagramNode(
                id: "finish",
                label: "Finish",
                sublabel: "or loop again",
                panelTitle: "Finish, or loop",
                panelBody: "If the observation answers the question, the model finishes. If not, it thinks again and acts again. The loop repeats until grounded enough to commit."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats of the reason-act loop. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · GROUNDING WINS",
                titleSegments: [
                    .plain("Reasoning, "),
                    .highlight("plus acting")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "question answering (% correct)",
                    primaryLabel: "Accuracy",
                    secondaryLabel: nil,
                    yMax: 60,
                    yTickLabels: ["0", "30", "60"],
                    points: [
                        DLBarPoint(label: "Reason only", sublabel: "no tools", primary: 28.0, secondary: nil,
                                   annotation: "Chain of thought with no way to check facts. It reasons fluently but cannot catch its own mistakes."),
                        DLBarPoint(label: "Act only", sublabel: "no reasoning", primary: 25.0, secondary: nil,
                                   annotation: "Tool calls with no reasoning to guide them. It fetches things, but not always the right things."),
                        DLBarPoint(label: "ReAct", sublabel: "both", primary: 35.0, secondary: nil,
                                   annotation: "Reasoning chooses what to look up and observations keep it honest. The two together beat either alone."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "react",
                    defaultInsight: "Tap a bar. Reasoning and acting each help a little; together they help most."
                )),
                caption: "Accuracy on knowledge-intensive question answering. Representative of the paper's reported results.",
                takeaway: "The synergy of reasoning and acting is the point."
            ),
            DLVizCard(
                kicker: "CARD 06 · FEWER MADE-UP FACTS",
                titleSegments: [
                    .plain("Hallucination "),
                    .highlight("drops")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "answers with a made-up fact (%)",
                    primaryLabel: "Hallucination",
                    secondaryLabel: nil,
                    yMax: 80,
                    yTickLabels: ["0", "40", "80"],
                    points: [
                        DLBarPoint(label: "Reason only", sublabel: "from memory", primary: 56.0, secondary: nil,
                                   annotation: "With no observation to check against, more than half of failures invented a fact that sounded right."),
                        DLBarPoint(label: "ReAct", sublabel: "grounded", primary: 23.0, secondary: nil,
                                   annotation: "Because each claim could be checked against a real lookup, far fewer answers contained a made-up fact. Lower is better."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "grounded",
                    defaultInsight: "Tap a bar. Lower is better: grounding in observations roughly halves invented facts."
                )),
                caption: "Share of wrong answers that contained a hallucinated fact. Lower is better. Representative of the paper.",
                takeaway: "An observation can overrule a plausible but false memory."
            ),
        ],

        completeTakeaway: "\"Reasoning decided what to do. Acting told it whether it was right.\"",
        completeNextTease: "Up next: a model that teaches itself which tools to call.",
        paperTitle: "ReAct: Synergizing Reasoning and Acting in Language Models",
        glossary: [
            "react": "Prompting that interleaves reasoning (thoughts) with acting (tool calls) and observations, looping until the task is done.",
            "thought": "A reasoning step where the model decides what it knows, what it needs, and what action to take next.",
            "action": "A tool call the model writes as text, such as a search, run by an external system.",
            "observation": "The result returned by an action, fed back into the reasoning to keep it grounded.",
            "tool use": "Letting a model call external systems, like search or a calculator, instead of relying only on memory.",
            "hallucination": "A confident but false statement a model produces when it has nothing to check against.",
            "grounding": "Anchoring reasoning in real observations from tools or the environment.",
            "agent": "A model that loops between thinking and acting to carry out a multi-step task.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why pure reasoning can hallucinate",
                gloss: "It has nothing to check against, so it cannot catch its own mistakes."),
            DLObjective(
                text: "How the thought-act-observe loop works",
                gloss: "Reasoning picks an action, the tool returns a fact, reasoning continues."),
            DLObjective(
                text: "Why grounding cuts made-up facts",
                gloss: "A real observation can overrule a plausible but wrong memory."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It reasoned, "),
                .highlight("and checked"),
            ],
            mini: .reAct,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · REASON HAS LIMITS",
                    body: "A model that only reasons has no way to verify its claims, so it can produce a confident answer built on a wrong memory."),
                DLExplanationPara(
                    kicker: "P2 · ACT AND OBSERVE",
                    body: "ReAct interleaves a thought with an action, such as a search, then reads the observation. The reasoning chooses what to look up; the observation supplies a real fact."),
                DLExplanationPara(
                    kicker: "P3 · GROUNDED AND LEGIBLE",
                    body: "Checking each step against an observation cuts hallucination, and the thought-action-observation trail makes the model's behaviour easy to read and trust."),
            ],
            takeaway: "ReAct lets a model act on the world and react to what it finds, keeping its reasoning honest."
        ),
        paperURL: "https://arxiv.org/abs/2210.03629"
    )

    static let toolformer = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("It learns to "),
            .highlight("use tools")
        ],
        heroBody: "A language model is shaky at arithmetic, fresh facts, and dates. Toolformer teaches itself to insert API calls into its own text, keeping only the calls whose results make the next words easier to predict, with no human labels.",
        sourceLine: "arXiv:2302.04761 · Meta",

        hookSegments: [
            .plain("What if it "),
            .highlight("taught itself"),
            .plain(" to call tools?")
        ],
        hookBody: "Models are great at language but unreliable at sums, recent facts, and dates. The obvious fix is to let them call tools, but who labels where, in billions of words, a calculator or a search belongs? Toolformer's answer is self-supervision. The model samples candidate API calls in its own text, runs them, and keeps a call only if its result makes the following words easier to predict. It is then fine-tuned on that filtered data, so at inference it reaches for a calculator, a search, a calendar, or a translator on its own. A modest model trained this way beat far larger ones on tasks needing facts and arithmetic.",

        coreIdeaSegments: [
            .plain("Teach yourself "),
            .highlight("in three moves")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "A call is just text",
                detail: "An API call like [Calculator(400/1400)] is text the model writes. An external program runs it and pastes the result back, so writing words and writing tool calls are the same skill."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Keep only what helps",
                detail: "At each position the model tries candidate calls, executes them, and keeps a call only if its result lowers the loss on the next tokens. Useless calls are discarded. No human labels."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Then fine-tune",
                detail: "The model is trained on the text augmented with the calls that helped. Afterwards it inserts the right call, for the right tool, at the right place, all on its own."),
        ],

        eliAnalogyLabel: "ANALOGY · KNOW WHEN TO REACH",
        eliHeadlineSegments: [
            .plain("Like grabbing "),
            .highlight("a calculator"),
        ],
        eliBodyParts: [
            .plain("You don't do big sums in your head; you reach for a calculator, and you know "),
            .bold("when"),
            .plain(" to without being told. Toolformer is a model that learned the same instinct from its own writing: it noticed where a tool "),
            .bold("would have helped"),
            .plain(" and kept that habit."),
        ],
        eliArt: .exoskeleton,

        diagramSegments: [
            .plain("How it "),
            .highlight("teaches itself")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "sample",
                label: "Sample",
                sublabel: "try calls",
                panelTitle: "Sample candidate calls",
                panelBody: "In ordinary text the model proposes places a tool might help and writes candidate API calls there, for example a calculator call before a percentage."),
            DLDiagramNode(
                id: "execute",
                label: "Execute",
                sublabel: "run them",
                panelTitle: "Execute the calls",
                panelBody: "Each candidate call is actually run by the external tool, producing a real result that can be slotted back into the text where the call was."),
            DLDiagramNode(
                id: "filter",
                label: "Filter",
                sublabel: "does it help?",
                panelTitle: "Keep only what helps",
                panelBody: "The key test: does the result make the following words easier to predict? Calls that lower the loss are kept; calls that do not are thrown away. This is the self-supervision."),
            DLDiagramNode(
                id: "finetune",
                label: "Fine-tune",
                sublabel: "learn the habit",
                panelTitle: "Fine-tune on the keepers",
                panelBody: "The model is trained on text augmented with the helpful calls. Afterwards it writes the right call for the right tool by itself, with no prompting."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats of self-taught tool use. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · SMALL MODEL, BIG REACH",
                titleSegments: [
                    .plain("Tools beat "),
                    .highlight("raw size")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "math benchmark (% correct)",
                    primaryLabel: "Accuracy",
                    secondaryLabel: nil,
                    yMax: 60,
                    yTickLabels: ["0", "30", "60"],
                    points: [
                        DLBarPoint(label: "No tools", sublabel: "6B", primary: 7.0, secondary: nil,
                                   annotation: "The base model with no tools does arithmetic in its head and mostly gets it wrong."),
                        DLBarPoint(label: "Big model", sublabel: "175B", primary: 34.0, secondary: nil,
                                   annotation: "A model many times larger, still with no tools, does much better but not perfectly."),
                        DLBarPoint(label: "Toolformer", sublabel: "6B + tools", primary: 40.0, secondary: nil,
                                   annotation: "The small model that learned to call a calculator beats the giant, because it stops guessing and computes."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "tools",
                    defaultInsight: "Tap a bar. A 6B model with tools outscored a 175B model without them."
                )),
                caption: "Accuracy on a math-heavy benchmark. Numbers are representative of the paper's reported results.",
                takeaway: "Knowing when to call a tool beat sheer scale."
            ),
            DLVizCard(
                kicker: "CARD 06 · ONLY KEEP THE KEEPERS",
                titleSegments: [
                    .plain("Helpful calls "),
                    .highlight("survive")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "makes next words easier to predict",
                    primaryLabel: "Usefulness",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["low", "", "high"],
                    points: [
                        DLBarPoint(label: "No call", sublabel: "baseline", primary: 12.0, secondary: nil,
                                   annotation: "Without help the model must guess the number, so the next words stay hard to predict."),
                        DLBarPoint(label: "Wrong call", sublabel: "irrelevant", primary: 8.0, secondary: nil,
                                   annotation: "A valid but irrelevant call returns something unrelated, so it does not help prediction and is discarded."),
                        DLBarPoint(label: "Right call", sublabel: "relevant", primary: 88.0, secondary: nil,
                                   annotation: "The call whose result is exactly what the sentence needs makes the next words easy to predict, so it is kept."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "keep",
                    defaultInsight: "Tap a bar. A call is kept only when its result helps predict what comes next."
                )),
                caption: "How much each candidate call helped predict the following words, the filter that decides what to keep.",
                takeaway: "The training signal is prediction, not human labels."
            ),
        ],

        completeTakeaway: "\"Nobody told it where a tool helps. It tried, measured, and kept what worked.\"",
        completeNextTease: "You have finished the reasoning trunk of the foundations.",
        paperTitle: "Toolformer: Language Models Can Teach Themselves to Use Tools",
        glossary: [
            "toolformer": "A model that teaches itself to insert API calls into its text, keeping only the calls that help predict the next words.",
            "api call": "A tool request the model writes as text, such as [Calculator(2+2)], which an external program runs.",
            "self-supervised": "Learning without human labels, here by checking whether a tool's result improves next-word prediction.",
            "loss": "A measure of prediction error. A call is kept when its result lowers the loss on the following tokens.",
            "fine-tuning": "Further training the model, here on text augmented with the tool calls that proved helpful.",
            "tool use": "Calling external systems like a calculator, search, calendar, or translator instead of relying on memory.",
            "filtering": "Discarding candidate calls whose results do not make the next words easier to predict.",
            "function calling": "The modern descendant: models emitting structured calls to tools and APIs on their own.",
        ],
        learningObjectives: [
            DLObjective(
                text: "Why models need tools",
                gloss: "They are unreliable at arithmetic, fresh facts, and dates."),
            DLObjective(
                text: "How it learns without labels",
                gloss: "Keep a call only if its result helps predict the next words."),
            DLObjective(
                text: "Why self-taught tools beat scale",
                gloss: "A small model that computes outscored a much larger one that guessed."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It taught itself "),
                .highlight("when to call"),
            ],
            mini: .toolformer,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · A CALL IS TEXT",
                    body: "A tool call is just text the model writes, run by an external program, with the result pasted back. So writing words and writing calls are one skill."),
                DLExplanationPara(
                    kicker: "P2 · KEEP WHAT HELPS",
                    body: "The model samples candidate calls, runs them, and keeps only those whose results make the following words easier to predict. No human ever labels where tools belong."),
                DLExplanationPara(
                    kicker: "P3 · THEN FINE-TUNE",
                    body: "Trained on the calls that helped, the model learns to reach for the right tool unprompted. A small Toolformer beat much larger models on facts and arithmetic."),
            ],
            takeaway: "Toolformer turns tool use into a self-taught skill, learned from whether a call improves prediction."
        ),
        paperURL: "https://arxiv.org/abs/2302.04761"
    )

    static let grokking = DailyLoopContent(
        heroEyebrow: "FOUNDATIONS · REASONING",
        heroTitleSegments: [
            .plain("It clicks, "),
            .highlight("eventually")
        ],
        heroBody: "A small network memorises its training data, looks hopelessly overfit, then keeps training and suddenly generalises near perfectly. Generalisation arriving long after overfitting is called grokking, and weight decay is what drives it.",
        sourceLine: "arXiv:2201.02177 · OpenAI",

        hookSegments: [
            .plain("What if overfitting "),
            .highlight("wasn't the end"),
            .plain("?")
        ],
        hookBody: "Train a small model on a task like modular arithmetic and it memorises the training set fast: 100% training accuracy, validation stuck at chance. Textbook overfitting, the point where everyone stops. But keep training, tens of thousands of steps past that, and validation accuracy suddenly snaps to near 100%. The same network that looked hopelessly overfit has discovered the underlying rule. This delayed jump from memorising to generalising is grokking, and it only happens with enough weight decay, a gentle pressure toward simpler weights.",

        coreIdeaSegments: [
            .plain("Three beats of "),
            .highlight("a late leap")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Memorise fast",
                detail: "The network reaches perfect training accuracy almost immediately while validation sits at chance. It has become a lookup table: great on seen pairs, lost on new ones."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Generalise late",
                detail: "Long after the training loss flatlined, validation accuracy suddenly climbs to near 100%. The model has switched from memorising answers to computing the rule that produces them."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Weight decay drives it",
                detail: "The switch is not luck. Pressure toward simpler weights makes the compact rule a better deal than a giant lookup table. Remove that pressure and the model never groks."),
        ],

        eliAnalogyLabel: "ANALOGY · DRILLING A SKILL",
        eliHeadlineSegments: [
            .plain("Like practice that "),
            .highlight("finally clicks"),
        ],
        eliBodyParts: [
            .plain("You drill scales or vocabulary for ages, feeling like you've only "),
            .bold("memorised"),
            .plain(" them, getting nowhere. Then one day, far later than you expected, it just "),
            .bold("clicks"),
            .plain(" and you can improvise. Grokking is a network having that exact late breakthrough."),
        ],
        eliArt: .scratchPaper,

        diagramSegments: [
            .plain("How the leap "),
            .highlight("unfolds")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "memorise",
                label: "Memorise",
                sublabel: "train 100%",
                panelTitle: "Memorise the data",
                panelBody: "Early in training the network fits the training set perfectly. Validation accuracy stays at chance, because a memorised table has no entry for pairs it never saw."),
            DLDiagramNode(
                id: "plateau",
                label: "Plateau",
                sublabel: "looks overfit",
                panelTitle: "The overfit plateau",
                panelBody: "For a long stretch nothing seems to change. Training is perfect, validation is flat. This is exactly where conventional wisdom says to stop and call it overfit."),
            DLDiagramNode(
                id: "grok",
                label: "Grok",
                sublabel: "val leaps",
                panelTitle: "Generalisation kicks in",
                panelBody: "Then, far past the plateau, validation accuracy suddenly climbs to near 100%. The model has found the rule behind the data, not just stored the answers."),
            DLDiagramNode(
                id: "decay",
                label: "Why",
                sublabel: "weight decay",
                panelTitle: "What made it switch",
                panelBody: "Weight decay pressures the network toward simpler weights. The rule is simpler than a huge lookup table, so eventually it wins. Without weight decay the leap never comes."),
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four beats from memorising to grokking. Tap each to see what it does.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE LATE LEAP",
                titleSegments: [
                    .plain("Validation wakes up "),
                    .highlight("late")
                ],
                visualization: .trainingCurve(DLTrainingCurveSpec(
                    xAxisLabel: "training steps (log) →",
                    yAxisLabel: "accuracy →",
                    xTickLabels: ["1k", "10k", "100k", "1M"],
                    yTickLabels: ["0", "", "100"],
                    series: [
                        DLTrainingCurveSeries(
                            label: "Train",
                            color: .ink,
                            dashed: true,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 1.0, milestone: "1k",
                                                     annotation: "Training accuracy is already perfect: the model has memorised the data."),
                                DLTrainingCurvePoint(x: 0.33, y: 1.0, milestone: nil,
                                                     annotation: "Still perfect on training, and it stays that way the whole time."),
                                DLTrainingCurvePoint(x: 0.66, y: 1.0, milestone: nil,
                                                     annotation: "The training curve gives no hint that anything is about to change."),
                                DLTrainingCurvePoint(x: 1.0, y: 1.0, milestone: nil,
                                                     annotation: "Train accuracy was maxed out from the very start."),
                            ]),
                        DLTrainingCurveSeries(
                            label: "Validation",
                            color: .teal,
                            dashed: false,
                            points: [
                                DLTrainingCurvePoint(x: 0.0, y: 0.05, milestone: nil,
                                                     annotation: "Validation is at chance: the memorised table is useless on unseen pairs."),
                                DLTrainingCurvePoint(x: 0.33, y: 0.06, milestone: "10k",
                                                     annotation: "Tens of thousands of steps later, still flat. This is the overfit plateau."),
                                DLTrainingCurvePoint(x: 0.66, y: 0.72, milestone: "100k",
                                                     annotation: "Then it suddenly starts to climb. The model is grokking the rule."),
                                DLTrainingCurvePoint(x: 1.0, y: 0.99, milestone: "1M",
                                                     annotation: "It now generalises almost perfectly, long after it looked hopelessly overfit."),
                            ])
                    ],
                    defaultInsight: "Tap a point. Train is perfect throughout; validation does nothing for ages, then leaps."
                )),
                caption: "Accuracy against training steps on a log axis. Sketched from the paper's grokking curves.",
                takeaway: "Generalisation is a separate phase that can arrive much later than memorisation."
            ),
            DLVizCard(
                kicker: "CARD 06 · THE KNOB THAT DECIDES",
                titleSegments: [
                    .plain("Weight decay "),
                    .highlight("makes or breaks it")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "final validation accuracy (%)",
                    primaryLabel: "Validation",
                    secondaryLabel: nil,
                    yMax: 100,
                    yTickLabels: ["0", "50", "100"],
                    points: [
                        DLBarPoint(label: "None", sublabel: "no decay", primary: 5.0, secondary: nil,
                                   annotation: "With no pressure to simplify, the model stays a lookup table forever and never groks."),
                        DLBarPoint(label: "Tiny", sublabel: "a little", primary: 64.0, secondary: nil,
                                   annotation: "A little weight decay eventually nudges it toward the rule, but slowly and not as far."),
                        DLBarPoint(label: "Just right", sublabel: "sweet spot", primary: 99.0, secondary: nil,
                                   annotation: "Enough pressure tips the model off the memorising solution and onto the rule. It groks."),
                        DLBarPoint(label: "Too high", sublabel: "overdone", primary: 18.0, secondary: nil,
                                   annotation: "Crank it too far and the weights are punished so hard the model can't even fit the data."),
                    ],
                    cliffIndex: 2,
                    cliffLabel: "groks",
                    defaultInsight: "Tap a bar. Only the right amount of weight decay tips the model into generalising."
                )),
                caption: "Final validation accuracy by weight-decay strength. Representative of the paper's findings.",
                takeaway: "Grokking is driven by regularisation, not by more data."
            ),
        ],

        completeTakeaway: "\"The network did not get more data. It was pushed toward simpler weights until the rule beat the lookup table.\"",
        completeNextTease: "Up next: abilities that appear only once a model is big enough.",
        paperTitle: "Grokking: Generalization Beyond Overfitting on Small Algorithmic Datasets",
        glossary: [
            "grokking": "When a model generalises suddenly, long after it has memorised the training data and looks overfit.",
            "generalisation": "Performing well on unseen data, not just the examples seen in training.",
            "overfitting": "Fitting the training data perfectly while failing on new data. With grokking, it turns out not to be the end of learning.",
            "memorisation": "Storing training answers like a lookup table, with no rule that extends to unseen cases.",
            "weight decay": "A pull toward smaller, simpler weights during training. It is what drives the switch from memorising to generalising.",
            "regularisation": "Any pressure that favours simpler models, of which weight decay is one form.",
            "modular arithmetic": "Arithmetic that wraps around a modulus, the small algorithmic task used to study grokking.",
            "validation accuracy": "Accuracy on held-out data the model was not trained on, the true test of generalisation.",
            "double descent": "A related surprise where more training or capacity helps again after a dip, also breaking simple overfitting intuition.",
        ],
        learningObjectives: [
            DLObjective(
                text: "What grokking is",
                gloss: "Generalisation that arrives suddenly, long after a model looks overfit."),
            DLObjective(
                text: "Memorise vs generalise",
                gloss: "A lookup table fails on unseen pairs; a learned rule fills them in."),
            DLObjective(
                text: "Why weight decay matters",
                gloss: "Pressure toward simpler weights makes the rule beat the lookup table."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It memorised, "),
                .highlight("then grokked"),
            ],
            mini: .grokking,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · MEMORISE",
                    body: "The network fits the training data perfectly almost at once, while validation stays at chance. It is a lookup table with no rule for unseen pairs."),
                DLExplanationPara(
                    kicker: "P2 · THE LATE LEAP",
                    body: "Far past the overfit plateau, validation accuracy suddenly jumps to near 100%. The model switched from storing answers to computing the rule behind them."),
                DLExplanationPara(
                    kicker: "P3 · WHY",
                    body: "Weight decay pushes the network toward simpler weights, making the compact rule win over the giant table. Without it, the leap never happens."),
            ],
            takeaway: "Grokking shows generalisation can be a separate, later phase of training, driven by regularisation."
        ),
        paperURL: "https://arxiv.org/abs/2201.02177"
    )
}
