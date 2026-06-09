import Foundation

// MARK: - Foundational Bundle Glossaries
//
// Per-paper key terms and concise plain language definitions. Used by
// `GlossaryView` so readers can refresh on the jargon a paper assumes
// without bouncing out to the open web. Definitions deliberately avoid
// em or en dashes (project style), using commas, colons, and parens.

struct GlossaryTerm: Identifiable, Hashable {
    let term: String
    let definition: String
    var id: String { term }
}

enum FoundationalGlossaries {

    static func terms(for slug: String) -> [GlossaryTerm] {
        switch slug {
        case "perceptron": return perceptron
        case "backprop":   return backprop
        case "lenet":      return lenet
        case "alexnet":    return alexnet
        case "word2vec":   return word2vec
        case "seq2seq":    return seq2seq
        case "gans":       return gans
        case "resnet":     return resnet
        case "attention":  return transformer
        case "gpt3":       return gpt3
        default:           return []
        }
    }

    /// Builds the `[term: definition]` dictionary consumed by
    /// `DailyLoopContent.glossary`. Splits parenthetical aliases
    /// ("Filter (kernel)" -> "Filter" and "kernel") and adds a cheap
    /// English plural for single-word terms so plain body copy
    /// ("weights", "filters") still lights up.
    static func dict(for slug: String) -> [String: String] {
        var dict: [String: String] = [:]
        for t in terms(for: slug) {
            let base = t.term
            if let r = base.range(of: #"\s*\(([^)]+)\)\s*$"#, options: .regularExpression) {
                let main = String(base[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let inner = String(base[r]).trimmingCharacters(in: CharacterSet(charactersIn: " ()"))
                if !main.isEmpty  { addVariants(&dict, term: main,  def: t.definition) }
                if !inner.isEmpty { addVariants(&dict, term: inner, def: t.definition) }
            } else {
                addVariants(&dict, term: base, def: t.definition)
            }
        }
        return dict
    }

    private static func addVariants(_ dict: inout [String: String], term: String, def: String) {
        dict[term] = def
        let lower = term.lowercased()
        // Single-word, non-plural English nouns get a naive `s` plural.
        // Skip multi-word ("Linear separability" + s = nonsense) and
        // anything already ending in s, x, or y to avoid wrong forms.
        if !lower.contains(" "),
           !lower.hasSuffix("s"),
           !lower.hasSuffix("x"),
           !lower.hasSuffix("y") {
            dict[term + "s"] = def
        }
    }

    static let perceptron: [GlossaryTerm] = [
        .init(term: "Perceptron",
              definition: "Simplest neural unit. A weighted sum of inputs passed through a threshold to output 0 or 1."),
        .init(term: "Weight",
              definition: "Scalar coefficient on each input, learned during training to set how much that input matters."),
        .init(term: "Bias",
              definition: "Scalar added to the weighted sum. Shifts the decision threshold left or right."),
        .init(term: "Activation function",
              definition: "Nonlinear gate applied to the weighted sum. In Rosenblatt's perceptron it is a step function."),
        .init(term: "Linear separability",
              definition: "Property of a dataset whose classes can be split by a single straight line (or flat plane). A perceptron only solves linearly separable problems."),
        .init(term: "Learning rule",
              definition: "Rule that nudges weights toward the right answer on a wrong prediction. Rosenblatt's rule adds the input to the weight on misclassification."),
        .init(term: "Threshold",
              definition: "The cutoff the weighted sum must cross for the unit to fire. Below it the output is 0, above it the output is 1."),
        .init(term: "Hyperplane",
              definition: "The flat dividing surface a perceptron draws between two classes. A line in 2D, a plane in 3D, a flat slab in higher dimensions."),
        .init(term: "Step function",
              definition: "A function that outputs 0 below a cutoff and 1 above it, with nothing in between. The perceptron's all or nothing decision."),
        .init(term: "Decision boundary",
              definition: "The line or surface where a classifier switches from one predicted class to the other."),
        .init(term: "XOR",
              definition: "Exclusive or. A four point pattern that no single straight line can separate, so one perceptron can never solve it."),
        .init(term: "Epoch",
              definition: "One full pass over the entire training dataset."),
        .init(term: "Convergence",
              definition: "When training settles: the weights stop changing because the model has stopped making mistakes (or stopped improving)."),
        .init(term: "Supervised learning",
              definition: "Learning from examples that come with the correct answer attached, so every prediction can be marked right or wrong."),
        .init(term: "Classifier",
              definition: "A model that sorts an input into one of a fixed set of categories."),
    ]

    static let backprop: [GlossaryTerm] = [
        .init(term: "Backpropagation",
              definition: "Algorithm that computes the gradient of the loss with respect to every weight by applying the chain rule layer by layer."),
        .init(term: "Hidden layer",
              definition: "Layer between input and output. Hidden units let the network represent nonlinear features."),
        .init(term: "Gradient descent",
              definition: "Optimization that takes small steps opposite the gradient to minimize a loss function."),
        .init(term: "Chain rule",
              definition: "Calculus identity for differentiating composed functions. Used to propagate error from output back through every layer."),
        .init(term: "Loss function",
              definition: "Scalar measure of prediction error. Squared error and cross entropy are common choices."),
        .init(term: "Learning rate",
              definition: "Step size used in gradient descent. Too large diverges, too small trains slowly."),
        .init(term: "Gradient",
              definition: "The direction and steepness of a function's slope. It points the way the loss rises fastest, so training steps the opposite way."),
        .init(term: "Forward pass",
              definition: "Running an input through the network to produce a prediction."),
        .init(term: "Backward pass",
              definition: "Running the error back through the network to work out how much each weight contributed to it."),
        .init(term: "Derivative",
              definition: "How fast one quantity changes when another nudges. Backprop is built from derivatives of the loss."),
        .init(term: "Sigmoid",
              definition: "An S shaped activation function that squashes any number into the range 0 to 1."),
        .init(term: "Credit assignment",
              definition: "The problem of deciding which weight, buried deep in the network, deserves blame for an output error. Backprop solves it."),
        .init(term: "Local minimum",
              definition: "A dip in the loss landscape that is low nearby but not the lowest point overall. Gradient descent can get stuck in one."),
        .init(term: "Momentum",
              definition: "A tweak to gradient descent that keeps part of the previous step, so training rolls through small bumps instead of stalling."),
        .init(term: "Multilayer perceptron",
              definition: "A feedforward network of stacked layers of neurons. Backpropagation is what makes it trainable."),
    ]

    static let lenet: [GlossaryTerm] = [
        .init(term: "Convolution",
              definition: "Sliding window operation that applies the same small filter at every position to detect local patterns."),
        .init(term: "Filter (kernel)",
              definition: "Small learnable matrix slid over the input. One filter produces one feature map."),
        .init(term: "Feature map",
              definition: "2D activation grid output by one filter. Stacks of feature maps form a layer's output."),
        .init(term: "Pooling",
              definition: "Downsampling step that summarizes a region with one value (typically the max). Adds shift invariance."),
        .init(term: "Receptive field",
              definition: "Region of the input that influences a specific neuron's activation. Grows deeper in the network."),
        .init(term: "Parameter sharing",
              definition: "Same filter weights used at every spatial location. Drastically reduces parameter count versus a fully connected layer."),
        .init(term: "Convolutional neural network",
              definition: "A network built mainly from convolution layers, designed so the same pattern detectors work anywhere in an image."),
        .init(term: "Stride",
              definition: "How many pixels the filter jumps between positions. A larger stride shrinks the output and skips detail."),
        .init(term: "Padding",
              definition: "Extra border pixels added around an input so the filter can reach the edges and the output keeps its size."),
        .init(term: "Subsampling",
              definition: "Shrinking a feature map by combining nearby values. LeNet's term for what is now usually called pooling."),
        .init(term: "Translation invariance",
              definition: "Recognizing a pattern no matter where in the image it sits. Convolution and pooling build this in."),
        .init(term: "Fully connected layer",
              definition: "A layer where every input connects to every output. Used near the end of LeNet to combine features into a final class."),
        .init(term: "MNIST",
              definition: "A benchmark dataset of 70,000 handwritten digit images. LeNet was built to read it."),
        .init(term: "Parameter",
              definition: "A single number the network learns, such as one weight or one bias."),
    ]

    static let alexnet: [GlossaryTerm] = [
        .init(term: "ReLU",
              definition: "Rectified linear unit, max(0, x). Fast and non saturating, replaced slower sigmoid activations in deep nets."),
        .init(term: "Dropout",
              definition: "Training trick that randomly zeroes a fraction of activations each batch. Prevents co adaptation and overfitting."),
        .init(term: "GPU training",
              definition: "Running matrix operations on the GPU. Made deep convolutional nets practical to train at scale."),
        .init(term: "Data augmentation",
              definition: "Synthetic training images created via crops, flips, color jitter. Expands the effective dataset for free."),
        .init(term: "ImageNet",
              definition: "1.2 million image classification benchmark across 1,000 classes. AlexNet roughly halved the prior best error."),
        .init(term: "Top 5 error",
              definition: "Fraction of test images where the correct class is not in the model's five most confident guesses."),
        .init(term: "Overfitting",
              definition: "When a model memorizes its training data instead of learning the general pattern, so it does poorly on new examples."),
        .init(term: "Saturation",
              definition: "When an activation function flattens out, so its gradient is near zero and the neuron stops learning. ReLU avoids it."),
        .init(term: "Softmax",
              definition: "A function that turns a row of raw scores into probabilities that add up to 1, one per class."),
        .init(term: "Co-adaptation",
              definition: "When neurons learn to lean on each other's exact quirks rather than learning useful features alone. Dropout breaks it up."),
        .init(term: "Benchmark",
              definition: "A standard dataset and scoring rule everyone tests on, so competing models can be compared fairly."),
        .init(term: "Feature hierarchy",
              definition: "The way early layers learn simple parts (edges) and deeper layers combine them into complex ones (shapes, objects)."),
        .init(term: "Epoch",
              definition: "One full pass over the entire training dataset."),
        .init(term: "Generalization",
              definition: "How well a model performs on data it never saw during training."),
    ]

    static let word2vec: [GlossaryTerm] = [
        .init(term: "Word embedding",
              definition: "Dense vector representation of a word in a continuous space that captures semantic relationships."),
        .init(term: "Skip gram",
              definition: "Training setup that predicts surrounding context words from a given center word."),
        .init(term: "CBOW",
              definition: "Continuous bag of words. Predicts the center word from its surrounding context."),
        .init(term: "Negative sampling",
              definition: "Cheap approximation to a full softmax. Trains against a few random non context words instead of every vocabulary word."),
        .init(term: "Vector arithmetic",
              definition: "Embeddings support analogies via vector math. For example, king minus man plus woman lands near queen."),
        .init(term: "Cosine similarity",
              definition: "Cosine of the angle between two vectors. Higher means more semantically related."),
        .init(term: "Vector",
              definition: "An ordered list of numbers. Here it is a point in space whose direction encodes a word's meaning."),
        .init(term: "Embedding",
              definition: "A learned vector that stands in for a word, image, or item, placed so that similar things sit close together."),
        .init(term: "Vocabulary",
              definition: "The full set of distinct words a model knows and can represent."),
        .init(term: "Corpus",
              definition: "The large body of text a model is trained on."),
        .init(term: "Context window",
              definition: "The span of words around a target word that the model treats as its context."),
        .init(term: "One hot encoding",
              definition: "Representing a word as a long vector of zeros with a single 1 marking which word it is. The clumsy scheme embeddings replace."),
        .init(term: "Distributional hypothesis",
              definition: "The idea that words appearing in similar contexts tend to have similar meanings. The foundation Word2Vec is built on."),
        .init(term: "Softmax",
              definition: "A function that turns raw scores into probabilities that add up to 1, one per word in the vocabulary."),
        .init(term: "Token",
              definition: "One unit of text the model processes, usually a word or word piece."),
    ]

    static let seq2seq: [GlossaryTerm] = [
        .init(term: "Encoder",
              definition: "Recurrent network that consumes the input sequence and compresses it into a fixed length context vector."),
        .init(term: "Decoder",
              definition: "Recurrent network that emits the output sequence one token at a time, conditioned on the context vector."),
        .init(term: "LSTM",
              definition: "Long short term memory. A gated recurrent cell that mitigates the vanishing gradient problem in long sequences."),
        .init(term: "Teacher forcing",
              definition: "Training trick that feeds the ground truth previous token to the decoder instead of its own prediction."),
        .init(term: "BLEU",
              definition: "Bilingual evaluation understudy. Scores machine translation quality by matching n grams against reference translations."),
        .init(term: "Beam search",
              definition: "Decoding strategy that keeps the top k partial sequences at each step rather than greedily picking one."),
        .init(term: "Recurrent neural network",
              definition: "A network that processes a sequence one step at a time, carrying a memory of what it has seen so far."),
        .init(term: "Hidden state",
              definition: "The running memory a recurrent network carries from one step to the next."),
        .init(term: "Context vector",
              definition: "The single fixed length vector the encoder packs the whole input into and hands to the decoder."),
        .init(term: "Vanishing gradient",
              definition: "When the learning signal shrinks toward zero as it travels back across many steps, so early steps barely learn."),
        .init(term: "Gating",
              definition: "Learned valves inside an LSTM that decide what to keep, forget, and output at each step."),
        .init(term: "Greedy decoding",
              definition: "Building the output by always taking the single most likely next token, never looking back."),
        .init(term: "Machine translation",
              definition: "Automatically converting text from one language into another."),
        .init(term: "Token",
              definition: "One unit of a sequence the model reads or writes, usually a word or word piece."),
    ]

    static let gans: [GlossaryTerm] = [
        .init(term: "Generator",
              definition: "Network that maps random noise to synthetic samples meant to look real."),
        .init(term: "Discriminator",
              definition: "Classifier that learns to tell real samples from those produced by the generator."),
        .init(term: "Adversarial loss",
              definition: "Minimax game where the generator tries to fool the discriminator and the discriminator tries not to be fooled."),
        .init(term: "Mode collapse",
              definition: "Failure mode where the generator produces only a few distinct outputs and ignores most of the data distribution."),
        .init(term: "Latent space",
              definition: "Input noise distribution the generator samples from. Interpolating it produces smooth blends of outputs."),
        .init(term: "Nash equilibrium",
              definition: "Stable point where neither network can improve by changing its strategy alone. The training target for a GAN."),
        .init(term: "Minimax",
              definition: "A two player setup where one side tries to maximize a score and the other tries to minimize it. The GAN's core game."),
        .init(term: "Generative model",
              definition: "A model that learns to produce new data resembling its training set, rather than just labeling existing data."),
        .init(term: "Discriminative model",
              definition: "A model that learns to tell classes apart, such as real versus fake, rather than to generate data."),
        .init(term: "Noise vector",
              definition: "The random list of numbers fed into the generator. Different noise produces different synthetic outputs."),
        .init(term: "Interpolation",
              definition: "Sliding smoothly between two points in latent space, which morphs one generated output into another."),
        .init(term: "Sampling",
              definition: "Drawing a random example, here from the noise input or from the data distribution."),
        .init(term: "Distribution",
              definition: "The full pattern of how data is spread out. A GAN's goal is to match the real data's distribution."),
        .init(term: "Convergence",
              definition: "When training settles into a stable point and the networks stop improving against each other."),
    ]

    static let resnet: [GlossaryTerm] = [
        .init(term: "Residual connection",
              definition: "Shortcut that adds the input of a block directly to its output: y = F(x) + x."),
        .init(term: "Identity mapping",
              definition: "Shortcut that passes the input through unchanged. The simplest form of a residual connection."),
        .init(term: "Vanishing gradient",
              definition: "Classic problem where gradients shrink as they propagate through many layers, stalling deep network training."),
        .init(term: "Skip connection",
              definition: "Another name for a residual connection."),
        .init(term: "Bottleneck block",
              definition: "Three layer pattern of 1x1, then 3x3, then 1x1 convolutions. Reduces compute in deeper ResNets."),
        .init(term: "Depth",
              definition: "Number of stacked layers. ResNets pushed depth past 100 layers without degrading accuracy."),
        .init(term: "Degradation problem",
              definition: "The surprise that adding more layers to a plain deep network made it worse, even on training data. ResNet's residual blocks fix it."),
        .init(term: "Residual block",
              definition: "A small group of layers wrapped with a shortcut, so it only has to learn the change to add to its input."),
        .init(term: "Batch normalization",
              definition: "A layer that rescales activations to a steady range, which speeds up and stabilizes deep network training."),
        .init(term: "Gradient flow",
              definition: "How cleanly the learning signal travels back through the network. Skip connections give it a clear path."),
        .init(term: "Plain network",
              definition: "A deep network with no skip connections. ResNet's baseline, the one the degradation problem hits."),
        .init(term: "Convolution",
              definition: "Sliding a small learnable filter across an image to detect the same local pattern anywhere."),
        .init(term: "Optimization",
              definition: "The process of adjusting weights to drive the loss down. A network is easier to train when optimization is easier."),
    ]

    static let transformer: [GlossaryTerm] = [
        .init(term: "Self attention",
              definition: "Mechanism where every token in a sequence attends to every other token, weighted by learned compatibility."),
        .init(term: "Query, key, value",
              definition: "Three learned projections of each token. Attention weights come from query and key. The output is a weighted sum of values."),
        .init(term: "Multi head attention",
              definition: "Several attention computations run in parallel with different projections, then concatenated."),
        .init(term: "Positional encoding",
              definition: "Vector added to each token to inject information about its position in the sequence."),
        .init(term: "Feed forward layer",
              definition: "Per token multilayer perceptron applied after attention. Adds nonlinear capacity to each position."),
        .init(term: "Layer normalization",
              definition: "Normalizes activations across features for each token. Stabilizes training in deep transformers."),
        .init(term: "Attention",
              definition: "A mechanism that lets a model decide which other parts of the input to focus on when processing each part."),
        .init(term: "Transformer",
              definition: "The architecture built entirely on attention, with no recurrence, so a whole sequence is processed in parallel."),
        .init(term: "Token",
              definition: "One unit of a sequence the model reads, usually a word or word piece."),
        .init(term: "Recurrence",
              definition: "Processing a sequence step by step, each step depending on the last. The slow approach transformers replaced."),
        .init(term: "Embedding",
              definition: "A learned vector that represents a token, placed so similar tokens sit close together."),
        .init(term: "Softmax",
              definition: "A function that turns raw scores into weights that add up to 1. It sets how much attention each token gets."),
        .init(term: "Parallelization",
              definition: "Doing many computations at once instead of in sequence. Dropping recurrence let transformers train far faster."),
        .init(term: "Context",
              definition: "The surrounding tokens a model can look at when interpreting any one token."),
    ]

    static let gpt3: [GlossaryTerm] = [
        .init(term: "Few shot learning",
              definition: "Performing a new task from a handful of examples shown in the prompt, with no weight updates."),
        .init(term: "In context learning",
              definition: "Treating the prompt as the entire signal. The model completes patterns it sees in context."),
        .init(term: "Scaling laws",
              definition: "Empirical relationship that test loss falls predictably with more parameters, more data, and more compute."),
        .init(term: "Autoregressive",
              definition: "Generates one token at a time, conditioning each prediction on all previously generated tokens."),
        .init(term: "175 billion parameters",
              definition: "GPT 3's size at release, roughly ten times the largest prior language models."),
        .init(term: "Prompt engineering",
              definition: "Practice of wording the input to steer the model toward better outputs without changing weights."),
        .init(term: "Language model",
              definition: "A model trained to predict the next word, which in doing so learns grammar, facts, and reasoning patterns."),
        .init(term: "Parameter",
              definition: "One of the numbers a model learns. GPT 3 has 175 billion of them, and more parameters means more capacity."),
        .init(term: "Token",
              definition: "One unit of text the model reads or writes, usually a word or word piece."),
        .init(term: "Pretraining",
              definition: "The first, expensive training stage where a model learns general patterns from a huge pile of text."),
        .init(term: "Fine tuning",
              definition: "Further training a pretrained model on a specific task by updating its weights. GPT 3 showed this is often unnecessary."),
        .init(term: "Zero shot learning",
              definition: "Doing a task from only a plain instruction, with no worked examples in the prompt."),
        .init(term: "Emergent ability",
              definition: "A skill that smaller models simply lack and that appears only once a model is scaled up large enough."),
        .init(term: "Prompt",
              definition: "The text fed into the model. With GPT 3, the prompt alone can specify an entire task."),
        .init(term: "Self supervised learning",
              definition: "Learning from raw data with no human labels by predicting hidden parts of it, such as the next word."),
    ]
}
