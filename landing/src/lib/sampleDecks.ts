/**
 * Hand-curated AprecisDeck samples that exercise every premium diagram
 * renderer. Used by the Hero converter so the example chips show off the
 * full diagram DSL even before the new backend pipeline ships. Once
 * `add-paper` is redeployed and the old cache rows are purged, the live API
 * will return decks with the same shape.
 */

import type { AprecisDeck, Concept } from './types'

function deck(
  paperId: string,
  title: string,
  url: string,
  hook: string,
  summary: string,
  concepts: Concept[],
): AprecisDeck {
  return {
    deck: {
      paper_id: paperId,
      title,
      source: 'arxiv',
      url,
      hook,
      summary,
      concepts,
      score: 0.92,
    },
    blueprint: null,
  }
}

const attentionDeck = deck(
  'arxiv:1706.03762',
  'Attention Is All You Need',
  'https://arxiv.org/abs/1706.03762',
  'A model that learns by paying attention, not by reading in order.',
  'Vaswani et al. replace recurrence with attention. Every word in a sentence can directly inspect every other word, in parallel. The Transformer trains faster than RNNs and sets new translation records on WMT 2014.',
  [
    {
      title: 'Scaled dot-product attention',
      body:
        'Each word emits a query, a key, and a value vector. The query meets every key, the match scores are softmaxed into weights, and the output is a weighted blend of values. The √dₖ divisor keeps the gradient from collapsing as dimensions grow.',
      diagramSpec: {
        type: 'equation',
        caption: 'The one equation the entire paper hinges on.',
        formula: 'Attention(Q,K,V) = softmax(QKᵀ / √dₖ) V',
        terms: [
          { symbol: 'Q', meaning: 'Query — what each word is looking for.' },
          { symbol: 'K', meaning: 'Key — what each word advertises about itself.' },
          { symbol: 'V', meaning: 'Value — the payload each word will share if attended to.' },
          { symbol: 'QKᵀ', meaning: 'Pairwise match scores between every query and every key.' },
          { symbol: '√dₖ', meaning: 'Square root of the key dimension; rescales scores so softmax stays sharp.' },
          { symbol: 'softmax', meaning: 'Turns raw scores into a probability distribution that sums to 1.' },
        ],
      },
    },
    {
      title: 'Multi-head attention',
      body:
        'A single attention head only learns one relationship. The Transformer runs eight in parallel, each with its own projection of Q/K/V, so the model can simultaneously track syntax, coreference, position, and topic. The eight head outputs are concatenated and re-projected.',
      diagramSpec: {
        type: 'multi_head',
        caption: 'Different heads attend to different relationships.',
        tokens: ['The', 'cat', 'sat', 'on', 'the', 'mat'],
        heads: [
          { name: 'Syntax', color: '#1a8a8a', desc: 'Tracks subject–verb agreement.', weights: [0.05, 0.62, 0.18, 0.05, 0.04, 0.06] },
          { name: 'Coref',  color: '#e8a020', desc: 'Resolves "the" → its referent noun.', weights: [0.42, 0.08, 0.04, 0.06, 0.30, 0.10] },
          { name: 'Topic',  color: '#7c3aed', desc: 'Surfaces content words, ignores function words.', weights: [0.04, 0.30, 0.20, 0.04, 0.04, 0.38] },
        ],
      },
    },
    {
      title: 'Attention as a soft lookup',
      body:
        'You can read the weight matrix as "which past tokens does each current token care about?". In translation, the model learns to align "law" with "loi" and "EU" with "UE" without ever being told what alignment is.',
      diagramSpec: {
        type: 'attention_heatmap',
        caption: 'The matrix the model writes to itself while translating.',
        tokens: ['The', 'cat', 'sat', 'on', 'the', 'mat'],
        weights: [
          [0.62, 0.10, 0.08, 0.06, 0.10, 0.04],
          [0.18, 0.55, 0.14, 0.04, 0.05, 0.04],
          [0.10, 0.22, 0.48, 0.10, 0.05, 0.05],
          [0.05, 0.06, 0.18, 0.55, 0.10, 0.06],
          [0.34, 0.06, 0.04, 0.10, 0.42, 0.04],
          [0.06, 0.18, 0.06, 0.10, 0.10, 0.50],
        ],
      },
    },
    {
      title: 'Positional encoding',
      body:
        'Attention is permutation-invariant — without help it would treat "dog bites man" the same as "man bites dog". The Transformer adds sinusoids of geometrically-spaced frequencies to every token, so the network can read relative position straight from the embedding.',
      diagramSpec: {
        type: 'sine_waves',
        caption: 'Position injected as a stack of sinusoids at doubling frequencies.',
      },
    },
  ],
)

const gpt3Deck = deck(
  'arxiv:2005.14165',
  'Language Models are Few-Shot Learners',
  'https://arxiv.org/abs/2005.14165',
  'Make the model big enough and it stops needing fine-tuning.',
  "Brown et al. train a 175B-parameter language model and find that simply prepending a few examples in the prompt is enough to coax it into solving new tasks — translation, arithmetic, code, trivia — with no gradient updates at all.",
  [
    {
      title: '175 billion parameters',
      body:
        'GPT-3 is two orders of magnitude larger than GPT-2. The jump in scale is the single biggest design decision in the paper.',
      diagramSpec: {
        type: 'number_box',
        caption: 'The headline number that defines the paper.',
        value: '175B',
        valueLabel: 'parameters',
        valueSublabel: '116× larger than GPT-2',
      },
    },
    {
      title: 'In-context learning',
      body:
        'Instead of fine-tuning on a labelled set, you write a few worked examples into the prompt. The model treats the prompt itself as the program. Zero examples is "zero-shot"; a handful is "few-shot".',
      diagramSpec: {
        type: 'flow',
        caption: 'A new task is delivered as text, not as gradient updates.',
        nodes: [
          { id: '1', label: 'Task description', sublabel: '"Translate English to French"' },
          { id: '2', label: 'k worked examples', sublabel: 'sea → mer; house → maison' },
          { id: '3', label: 'Query', sublabel: 'cat → ?' },
          { id: '4', label: 'Model completion', sublabel: 'chat' },
        ],
        edges: [
          { from: '1', to: '2' },
          { from: '2', to: '3' },
          { from: '3', to: '4', label: 'no fine-tune' },
        ],
      },
    },
    {
      title: 'Few-shot beats fine-tuned at scale',
      body:
        "At small model sizes few-shot prompting is a parlour trick. At GPT-3's scale it overtakes fine-tuned task-specific baselines on many benchmarks. The gain is emergent — there is no smooth curve, accuracy jumps once the model is big enough.",
      diagramSpec: {
        type: 'bar_chart',
        caption: 'Accuracy on the LAMBADA cloze task across four model sizes.',
        yLabel: 'Accuracy (%)',
        bars: [
          { label: '125M', value: 42, note: "Below threshold — model can't follow the prompt format reliably." },
          { label: '1.3B', value: 63, note: 'Pattern starts to register; few-shot beats zero-shot.' },
          { label: '13B',  value: 79, note: 'Emergence kicks in — gains accelerate with scale.' },
          { label: '175B', value: 86, note: 'GPT-3 — outscores the prior fine-tuned SOTA without any gradient updates.', color: '#e8a020' },
        ],
      },
    },
    {
      title: 'Fine-tune vs. prompt',
      body:
        "The new recipe replaces a per-task model with one general model plus a small prompt. The cost surface flips: training is enormous and one-shot, but every downstream task is now a few sentences of natural language.",
      diagramSpec: {
        type: 'comparison',
        caption: 'How shipping a task changes with a sufficiently large model.',
        leftLabel: 'Fine-tune era',
        rightLabel: 'Prompt era',
        items: [
          { aspect: 'Per-task training', before: 'Hours to days of GPUs', after: 'Zero — re-use the same weights' },
          { aspect: 'Labelled data',     before: '1,000 to 100,000 examples',     after: '0 to 32 examples in the prompt' },
          { aspect: 'Ship a new task',   before: 'Train, tune, deploy a model', after: 'Write a prompt, hit the API' },
          { aspect: 'Storage per task',  before: 'A full model checkpoint',     after: 'A text string' },
        ],
      },
    },
  ],
)

const diffusionDeck = deck(
  'arxiv:2006.11239',
  'Denoising Diffusion Probabilistic Models',
  'https://arxiv.org/abs/2006.11239',
  'Generate images by learning to undo noise, one tiny step at a time.',
  'Ho et al. show that a model can learn to reverse a fixed gaussian noising process. Sampling becomes T iterations of denoising from pure noise back to a coherent image, matching GAN-quality samples without GAN instability.',
  [
    {
      title: 'Iterative denoising loop',
      body:
        'Start with pure gaussian noise. At each step the model predicts the noise that was added and subtracts a small fraction of it. After T steps the image emerges. The loop is the model.',
      diagramSpec: {
        type: 'cycle',
        caption: 'One reverse step. The loop runs T = 1000 times.',
        steps: [
          { label: 'Predict noise', sublabel: 'εθ(xₜ, t)' },
          { label: 'Subtract',      sublabel: 'xₜ₋₁ ≈ xₜ − αₜ εθ' },
          { label: 'Add jitter',    sublabel: 'σₜ z, z ~ N(0,1)' },
          { label: 'Step t → t−1',  sublabel: 'repeat until t = 0' },
        ],
      },
    },
    {
      title: 'Training objective',
      body:
        'The model is trained to predict the noise added at a random timestep. The loss is a simple MSE — no adversary, no log-likelihood gymnastics. Stability comes for free.',
      diagramSpec: {
        type: 'equation',
        caption: "The paper's working loss — surprisingly plain.",
        formula: 'L = E [ ‖ ε − εθ(xₜ, t) ‖² ]',
        terms: [
          { symbol: 'ε',  meaning: 'The noise actually added at step t.' },
          { symbol: 'εθ', meaning: 'The neural net trying to predict ε.' },
          { symbol: 'xₜ', meaning: 'The noised image at timestep t.' },
          { symbol: 't',  meaning: 'A random timestep, drawn uniformly from 1..T.' },
        ],
      },
    },
  ],
)

export const SAMPLE_DECKS: Record<string, AprecisDeck> = {
  '1706.03762': attentionDeck,
  '2005.14165': gpt3Deck,
  '2006.11239': diffusionDeck,
}
