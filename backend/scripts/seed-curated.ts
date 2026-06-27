/**
 * Curated-content seed: inserts hand-edited DailyLoopBlueprints into Supabase
 * as real `papers` + `cards` rows. Bypasses the LLM pipeline entirely.
 *
 * Interactive loop ordering for the shipped iOS catalog is defined in
 * `data/curated-paper-catalog.json` (same file `CuratedPaperCatalog.swift` loads).
 *
 * Idempotent: each deck is upserted on `paper_id`. Re-running overwrites the
 * blueprint with the latest content here.
 *
 * Run: deno run --allow-net --allow-env --allow-read backend/scripts/seed-curated.ts
 *
 * Reads SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY from backend/.env.local.
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { CardDeck, DailyLoopBlueprint } from "../src/types.ts";

const CURATED_CATALOG_JSON = new URL("../../data/curated-paper-catalog.json", import.meta.url);

interface CuratedPaperCatalogFile {
  version: number;
  interactiveLoopPaperIds: string[];
}

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL              ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY  = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing env. Need SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

try {
  const raw = await Deno.readTextFile(CURATED_CATALOG_JSON);
  const cat = JSON.parse(raw) as CuratedPaperCatalogFile;
  console.log(
    `Shared curated-paper-catalog v${cat.version}: ${cat.interactiveLoopPaperIds.length} interactive loop ids`,
  );
} catch {
  console.warn("Could not read data/curated-paper-catalog.json (optional log)");
}

// ─── Curated decks ──────────────────────────────────────────────────────────

interface CuratedDeck {
  paper_id: string;
  title: string;
  source: string;
  url: string;
  pdf_url?: string;
  authors: string[];
  abstract: string;
  published_at: string;
  blueprint: DailyLoopBlueprint;
}

const perceptron: CuratedDeck = {
  paper_id: "perceptron",
  title: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
  source: "rss",
  url: "https://psycnet.apa.org/doiLanding?doi=10.1037/h0042519",
  authors: ["Frank Rosenblatt"],
  abstract: "We propose a hypothetical nervous system, called the perceptron, designed to illustrate fundamental properties of intelligent systems. The perceptron consists of input retina cells, association units that pool weighted signals through an adjustable threshold, and a response unit. A reinforcement rule updates the association weights from labelled examples. Under broad conditions, the perceptron is shown to be capable of learning to classify stimuli into categories.",
  published_at: "1958-11-01T00:00:00Z",
  blueprint: {
    heroEyebrow: "STARTER · PAPER 01 / 10",
    heroTitle: { text: "The first machine that could learn from examples", highlight: "learn from examples" },
    heroBody: "Rosenblatt built a single artificial neuron that takes weighted inputs, fires above a threshold, and nudges its own weights every time it gets an answer wrong. That tiny rule is the seed of every neural network alive today.",
    sourceLine: "Psychological Review, vol. 65, 1958 · Frank Rosenblatt",

    hookTitle: { text: "What if one neuron, one threshold, and one update rule were enough to learn?", highlight: "one update rule" },
    hookBody: "In 1958, before backprop, before GPUs, before the word \"deep\" meant anything in computing, Rosenblatt wired up a single artificial neuron, fed it labelled examples, and watched it teach itself to classify shapes. The whole field of machine learning lifts off from this paper.",

    coreIdeaTitle: { text: "Three ideas that still run modern AI", highlight: "still run modern AI" },
    coreFindings: [
      {
        title: "Weighted sum becomes a decision",
        detail: "Each input xᵢ gets multiplied by a weight wᵢ. Sum them all up. If the sum crosses a threshold, the neuron fires \"yes\", otherwise \"no\". That single line, wᵀx > θ, draws a hyperplane through input space and turns it into a binary classifier.",
      },
      {
        title: "Mistakes nudge the weights",
        detail: "On every wrong answer, apply w ← w + η(y − ŷ)x. The weights drift toward inputs of the right class and away from the wrong one. No gradients, no calculus. Just a simple feedback signal repeated until the neuron stops being wrong.",
      },
      {
        title: "Convergence is guaranteed, sometimes",
        detail: "If the two classes can be separated by any straight line, the perceptron is mathematically guaranteed to find one in finite steps. If they can't (XOR is the famous counter-example), it spins forever. That ceiling sparked the AI winter and motivated multilayer networks.",
      },
    ],

    eliAnalogyLabel: "ANALOGY · BOUNCER WITH A CLIPBOARD",
    eliHeadline: { text: "Imagine a bouncer learning who to let into a club.", highlight: "a bouncer" },
    eliBody: {
      text: "He scores each guest on a few things, outfit, ID, vibe, and adds the scores up. Above some line, you're in; below it, you're out. He starts with random weightings and gets it wrong a lot. Every time the manager corrects him, he tweaks how much he cares about each cue. Over a few hundred guests, he settles on a rule that works. That bouncer is a perceptron.",
      bold: "tweaks how much he cares",
    },

    diagramTitle: { text: "How one decision flows through one neuron", highlight: "one neuron" },
    timelineNodes: [
      {
        id: "in",
        label: "Inputs",
        sublabel: "x₁ … xₙ",
        panelTitle: "Inputs · the features",
        panelBody: "The neuron sees a vector of numbers, pixel intensities, sensor readings, or any measurements you choose. Each entry is one piece of evidence the neuron will weigh.",
      },
      {
        id: "w",
        label: "Weights",
        sublabel: "wᵢ × xᵢ",
        panelTitle: "Weights · how much each input matters",
        panelBody: "Every input is multiplied by a learned weight. Big positive weights amplify; big negative weights veto. The weights are the only thing that changes during learning, the architecture stays fixed.",
      },
      {
        id: "sum",
        label: "Sum",
        sublabel: "Σ wᵢxᵢ",
        panelTitle: "Sum · pooling the evidence",
        panelBody: "Add the weighted inputs together. The result is a single scalar score. Geometrically, it's the dot product wᵀx, the projection of the input onto the weight vector.",
      },
      {
        id: "out",
        label: "Threshold",
        sublabel: "fire if > θ",
        panelTitle: "Threshold · the decision",
        panelBody: "If the score crosses θ, output 1; otherwise 0. That step function is the neuron's verdict. The boundary {x : wᵀx = θ} is a hyperplane separating the two classes in input space.",
      },
    ],
    diagramCollapseText: "",
    diagramDefaultPanelBody: "Four stops along one perceptron decision. Tap each to see what the neuron does at that step.",

    vizCards: [
      {
        kicker: "CARD 05 · ONE NEURON, ONE LOOP",
        title: { text: "Forward to a guess; backward to a correction", highlight: "backward to a correction" },
        spec: {
          kind: "flow_rich",
          layout: "horizontal",
          defaultInsight: "Tap any node. The forward path (teal) takes inputs to a binary verdict. The backward path (amber, dashed) is the perceptron rule, every wrong answer nudges the weights toward the right one. Two passes, one neuron.",
          nodes: [
            {
              id: "x",
              label: "Inputs",
              sublabel: "x₁ … xₙ",
              role: "input",
              column: 0, row: 0,
              panelTitle: "Inputs · the features",
              panelBody: "A vector of numbers, pixel intensities, sensor readings, hand-engineered features. Each entry is one piece of evidence the neuron will weigh. The architecture is fixed; only the weights will change during learning.",
            },
            {
              id: "sum",
              label: "Σ wᵢxᵢ",
              sublabel: "weighted sum",
              role: "process",
              column: 1, row: 0,
              panelTitle: "Weighted sum · pooling the evidence",
              panelBody: "Multiply each input by its weight and add them all together. Geometrically this is the dot product wᵀx, the projection of the input onto the current weight vector. The single resulting scalar is the neuron's score.",
            },
            {
              id: "step",
              label: "Step",
              sublabel: "fire if > θ",
              role: "process",
              column: 2, row: 0,
              panelTitle: "Step function · the verdict",
              panelBody: "If the score crosses θ, output 1; otherwise 0. This non-differentiable jump is what makes the perceptron's update rule discrete instead of gradient-based. The boundary {x : wᵀx = θ} is a hyperplane separating the two classes.",
            },
            {
              id: "y",
              label: "Output",
              sublabel: "ŷ ∈ {0,1}",
              role: "output",
              column: 3, row: 0,
              panelTitle: "Output · the prediction",
              panelBody: "A single binary label. Compare it to the truth y. If they match, the weights stay. If they don't, the perceptron rule fires and pushes the weights toward the correct answer.",
            },
          ],
          edges: [
            { from: "x",   to: "sum",  label: "wᵀx",    kind: "forward" },
            { from: "sum", to: "step", label: "score",  kind: "forward" },
            { from: "step", to: "y",   label: "fire?",  kind: "forward" },
            { from: "y",   to: "sum",  label: "η(y−ŷ)x", kind: "backward" },
          ],
        },
        caption: "Same wires, two directions. Forward turns features into a verdict; backward turns mistakes into a weight nudge. Repeat until the boundary stops moving.",
        takeaway: "Forward = decide. Backward = correct.",
      },
      {
        kicker: "CARD 06 · DECISION BOUNDARY",
        title: { text: "From scattered points to a clean line", highlight: "a clean line" },
        spec: {
          kind: "scatter",
          beforeLabel: "Before training",
          afterLabel:  "After training",
          treatmentLabel: "Class A",
          controlLabel:   "Class B",
          treatmentBeforePattern: "spread",
          treatmentAfterPattern:  "cluster_right",
          controlBeforePattern:   "spread",
          controlAfterPattern:    "cluster_left",
          treatmentCount: 8,
          controlCount: 7,
          beforeCaption: "Before training the weights are random. Both classes scatter together; the neuron's decision line cuts through them with no relationship to the data.",
          afterCaption:  "After training the weights have rotated to align with the data. Class A clusters on one side of the line; Class B on the other.",
          xAxisLabel: "Feature 1 →",
          yAxisLabel: "Feature 2 ↑",
        },
        caption: "Drag to scrub. Each dot is one labelled example. The perceptron's only job is to rotate a single line until both classes sit on opposite sides.",
        takeaway: "Learning, in one line: rotate the boundary.",
      },
    ],

    completeQuote: "\"It can learn, it can make decisions, and it can translate language.\", Rosenblatt, 1958",
    completeTease: "Up next: how Rumelhart's chain rule cracked the multilayer wall.",

    paperTitle: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
    eliArt: "scratchPaper",
    diagramLayout: "flow",
    glossary: {
      "perceptron": "A single artificial neuron with adjustable input weights and a step-function output. The first machine-learning model that could update its own parameters from labelled examples.",
      "weight": "A learned coefficient that multiplies one input feature before it is summed into the neuron's score. Weights are the only thing the perceptron rule modifies during training.",
      "threshold": "The cut-off value θ that the weighted sum must exceed for the neuron to output 1. Geometrically it shifts the decision hyperplane along the weight vector.",
      "step function": "An activation that outputs 1 if its input is above zero and 0 otherwise. The non-differentiable jump is what makes the perceptron's update rule discrete rather than gradient-based.",
      "hyperplane": "A flat decision boundary in input space, a line in 2-D, a plane in 3-D, a (d−1)-dimensional surface in d dimensions.",
      "linearly separable": "A pair of classes is linearly separable when some hyperplane puts every example of class A on one side and every example of class B on the other.",
      "XOR": "Exclusive-OR: outputs 1 when exactly one input is 1. The classes (0,0) & (1,1) versus (0,1) & (1,0) cannot be split by any single line, so a perceptron cannot solve it.",
      "epoch": "One full pass through the training data. Convergence is usually measured in epochs.",
      "convergence theorem": "Rosenblatt's proof that, if the data is linearly separable, the perceptron rule will find a separating hyperplane in a finite number of updates.",
      "learning rate": "η, the scalar that controls how aggressively each mistake nudges the weights. Too high and updates overshoot; too low and learning crawls.",
      "dot product": "The sum Σ wᵢxᵢ. It measures alignment between two vectors and is the core operation inside every linear model and every layer of every neural network.",
      "feature": "One numeric input the model receives. Hand-engineered (\"is the pixel dark?\") in 1958, learned end-to-end in modern deep nets.",
    },
  },
};

const backprop: CuratedDeck = {
  paper_id: "backprop",
  title: "Learning Representations by Back-Propagating Errors",
  source: "rss",
  url: "https://www.nature.com/articles/323533a0",
  authors: ["David E. Rumelhart", "Geoffrey E. Hinton", "Ronald J. Williams"],
  abstract: "We describe a new learning procedure, back-propagation, for networks of neurone-like units. The procedure repeatedly adjusts the weights of the connections in the network so as to minimize a measure of the difference between the actual output vector of the net and the desired output vector. As a result of the weight adjustments, internal 'hidden' units which are not part of the input or output come to represent important features of the task domain, and the regularities in the task are captured by the interactions of these units.",
  published_at: "1986-10-09T00:00:00Z",
  blueprint: {
    heroEyebrow: "STARTER · PAPER 02 / 10",
    heroTitle: { text: "One algorithm cracked the multilayer wall", highlight: "multilayer wall" },
    heroBody: "Rumelhart, Hinton, and Williams showed you can compute the gradient of a loss with respect to every weight in a deep network by applying the chain rule once, layer by layer. Backprop made hidden layers trainable, and turned neural nets from a curiosity into a method.",
    sourceLine: "Nature, vol. 323, 1986 · Rumelhart, Hinton, Williams",

    hookTitle: { text: "How does a network blame each weight for the mistake it just made?", highlight: "blame each weight" },
    hookBody: "Before 1986, hidden layers were a black box. You could see the input and the wrong output, but you had no way to assign credit to the millions of weights in between. Backprop solved this with one trick: walk the chain rule backwards, layer by layer, multiplying gradients as you go.",

    coreIdeaTitle: { text: "Three pieces that make backprop work", highlight: "make backprop work" },
    coreFindings: [
      {
        title: "Forward pass produces a loss",
        detail: "Run the input through every layer in order. Each layer applies its weights and a non-linearity, producing a hidden activation. The last layer outputs a prediction. Compare it to the truth, that gap is the loss, a single scalar that tells you how wrong the network is right now.",
      },
      {
        title: "Backward pass walks the chain rule",
        detail: "Starting from the loss, compute ∂L/∂y. Then ∂L/∂h = ∂L/∂y · ∂y/∂h. Then ∂L/∂W₁ = ∂L/∂h · ∂h/∂W₁. Each step is one multiplication of local derivatives. Backprop is the chain rule, applied mechanically, from output back to input.",
      },
      {
        title: "Hidden layers learn features",
        detail: "Once every weight has a gradient, gradient descent can update them all together. The hidden units, freed from being hand-designed, settle into representations that capture the structure of the task, edges in vision, syntax in language, features the engineer never had to specify.",
      },
    ],

    eliAnalogyLabel: "ANALOGY · A KITCHEN BLAMING ITSELF",
    eliHeadline: { text: "Imagine a restaurant where one bad dish goes back to the kitchen.", highlight: "one bad dish" },
    eliBody: {
      text: "The waiter says \"too salty.\" That feedback has to travel back through the line cook, the prep cook, and the person who measured the salt. Each one figures out how much they contributed to the saltiness, and adjusts their habit slightly for next time. By tomorrow, the whole kitchen is a tiny bit better, without any single chef knowing the full recipe. That's backprop: a single complaint at the end, distributed across every cook in the chain.",
      bold: "distributed across every cook",
    },

    diagramTitle: { text: "How one example flows forward, then backward", highlight: "forward, then backward" },
    timelineNodes: [
      {
        id: "fwd",
        label: "Forward",
        sublabel: "x → ŷ",
        panelTitle: "Forward · run the input through every layer",
        panelBody: "Each layer multiplies the previous activation by its weights and applies a nonlinearity. By the time the signal reaches the output, the network has produced its current best guess.",
      },
      {
        id: "loss",
        label: "Loss",
        sublabel: "L(ŷ, y)",
        panelTitle: "Loss · measure how wrong the guess was",
        panelBody: "Compare the prediction ŷ to the true label y with a loss function, squared error, cross-entropy, etc. The result is a single number that the entire network is now trying to reduce.",
      },
      {
        id: "back",
        label: "Backward",
        sublabel: "∂L/∂W",
        panelTitle: "Backward · push the error back through every layer",
        panelBody: "Apply the chain rule from output to input. Each layer's gradient is the product of the next layer's gradient and its own local derivative. By the time you reach layer 1, every weight knows how it contributed to the loss.",
      },
      {
        id: "step",
        label: "Update",
        sublabel: "W ← W − η∇L",
        panelTitle: "Update · take one step downhill",
        panelBody: "Subtract a small fraction of each gradient from the corresponding weight. Repeat over millions of examples and the network slides toward a configuration that minimizes the loss across the whole dataset.",
      },
    ],
    diagramCollapseText: "",
    diagramDefaultPanelBody: "Four phases per training step. Tap each to see what the network is doing.",

    vizCards: [
      {
        kicker: "CARD 05 · THE UPDATE RULE",
        title: { text: "The single equation that trains everything", highlight: "trains everything" },
        spec: {
          kind: "equation_rich",
          promptText: "TAP ANY TERM",
          defaultInsight: "Every weight in every neural network is updated by this single equation. Tap each coloured symbol to see what it does.",
          terms: [
            { id: "w_new", display: "w", sup: "new", color: "teal",
              panelTitle: "Updated weight",
              panelBody: "The weight after one gradient step. This is what gets saved to memory, used in the next forward pass, and shared across every example in the next training batch." },
            { id: "eq", display: "=", color: "muted" },
            { id: "w_old", display: "w", sup: "old", color: "ink",
              panelTitle: "Current weight",
              panelBody: "The starting weight for this update step. Initialised randomly at the start of training; refined billions of times across the dataset until the loss stops dropping." },
            { id: "minus", display: "−", color: "muted" },
            { id: "lr", display: "η", color: "amber",
              panelTitle: "Learning rate",
              panelBody: "A small scalar (typically 1e−3 to 1e−4). Controls step size, too large and updates overshoot the minimum, too small and learning crawls. Decayed over time in most modern recipes." },
            { id: "dot", display: "·", color: "muted" },
            { id: "grad", display: "∂L/∂w", color: "rose",
              panelTitle: "Gradient",
              panelBody: "The slope of the loss with respect to this weight. Points uphill, toward higher loss, so we subtract it to step downhill. Backprop's whole job is to compute this number for every weight in one pass." },
          ],
        },
        caption: "Subtract a scaled gradient from the weight. Repeat for every weight, every example, every epoch. That's the entire training loop, in one line.",
        takeaway: "One equation, applied billions of times.",
      },
      {
        kicker: "CARD 06 · LEARNING CURVE",
        title: { text: "Loss falls; representations form", highlight: "representations form" },
        spec: {
          kind: "training_curve",
          xAxisLabel: "Training epoch →",
          yAxisLabel: "Loss",
          xTickLabels: ["1", "5", "10", "20", "40"],
          yTickLabels: ["0", "0.5", "1.0"],
          defaultInsight: "Backprop is the engine; gradient descent is the wheel. Tap a milestone, early epochs see fast loss reduction as the network finds gross structure; later epochs polish detail.",
          series: [
            {
              label: "Training loss",
              color: "teal",
              points: [
                { x: 1,  y: 0.95, milestone: "start", annotation: "Epoch 1, random weights. The network output is essentially noise; loss is at the upper bound." },
                { x: 5,  y: 0.62, milestone: "drop", annotation: "Epoch 5, the easy structure of the data is captured. Hidden units start to specialize." },
                { x: 10, y: 0.38 },
                { x: 20, y: 0.18, milestone: "fit", annotation: "Epoch 20, most signal is captured. Further gains come from refining decision boundaries on hard cases." },
                { x: 40, y: 0.07, milestone: "near", annotation: "Epoch 40, near-zero training loss. Generalization to held-out data is what we evaluate next." },
              ],
            },
          ],
        },
        caption: "Each epoch = one full pass over the training set. Backprop computes the gradients; SGD takes the step.",
        takeaway: "Backprop made the slope; SGD walks down it.",
      },
    ],

    completeQuote: "\"The procedure constructs internal representations as a side-effect of learning the input-output mapping.\", Rumelhart et al., 1986",
    completeTease: "Up next: how convolution let LeNet read handwritten digits.",

    paperTitle: "Learning Representations by Back-Propagating Errors",
    eliArt: "scratchPaper",
    diagramLayout: "flow",
    glossary: {
      "backpropagation": "An algorithm for computing the gradient of a loss with respect to every weight in a layered network by applying the chain rule from output to input.",
      "chain rule": "The calculus identity ∂L/∂a = ∂L/∂b · ∂b/∂a. Lets you decompose a derivative through any composed function, including a deep neural net.",
      "gradient": "A vector of partial derivatives. Tells you how a small change in each weight would change the loss.",
      "loss": "A scalar that measures the gap between prediction and truth. Training reduces it.",
      "hidden layer": "Any layer of the network that is neither input nor output. Backprop made hidden layers learnable.",
      "nonlinearity": "A function applied element-wise to a layer's output (sigmoid, tanh, ReLU). Without it, stacked linear layers collapse to one.",
      "gradient descent": "An optimizer that nudges each weight in the direction opposite its gradient, scaled by a learning rate.",
      "epoch": "One pass through the entire training dataset. Loss is usually plotted per epoch.",
    },
  },
};

const DECKS: CuratedDeck[] = [perceptron, backprop];

// ─── Upsert ─────────────────────────────────────────────────────────────────

console.log(`Target: ${SUPABASE_URL}`);
console.log(`Seeding ${DECKS.length} curated decks...`);

for (const d of DECKS) {
  console.log(`  ${d.paper_id}, ${d.title.slice(0, 60)}…`);

  // papers row
  {
    const { error } = await supabase.from("papers").upsert({
      paper_id:        d.paper_id,
      title:           d.title,
      authors:         d.authors,
      abstract:        d.abstract,
      source:          d.source,
      url:             d.url,
      pdf_url:         d.pdf_url ?? null,
      published_at:    d.published_at,
      score:           0.95,
      score_breakdown: { recency: 0.5, social: 1.0, keyword: 1.0, author: 0.95 },
      status:          "processed",
    }, { onConflict: "paper_id" });
    if (error) { console.error("  papers upsert:", error.message); Deno.exit(1); }
  }

  // cards row, blueprint is the rich curated payload; concepts/hook/summary
  // mirror the blueprint surface so legacy code paths still render.
  const cardDeck: Pick<CardDeck, "hook" | "summary" | "concepts"> = {
    hook:    d.blueprint.hookTitle.text,
    summary: d.blueprint.heroBody,
    concepts: d.blueprint.coreFindings.map((f) => ({
      title: f.title,
      body:  f.detail,
    })),
  };

  {
    const { error } = await supabase.from("cards").upsert({
      paper_id:  d.paper_id,
      title:     d.title,
      source:    d.source,
      url:       d.url,
      cards:     cardDeck,
      blueprint: d.blueprint,
    }, { onConflict: "paper_id" });
    if (error) { console.error("  cards upsert:", error.message); Deno.exit(1); }
  }
}

const { count: paperCount } = await supabase.from("papers").select("*", { count: "exact", head: true });
const { count: cardsCount } = await supabase.from("cards").select("*", { count: "exact", head: true });
console.log(`Done. papers=${paperCount}, cards=${cardsCount}`);
