/**
 * Seed branch roadmap papers as server-visible DailyLoopBlueprint decks.
 *
 * This is the App Store bridge for native branch loops: installed binaries do
 * not contain newly-added Swift content, but they can render `cards.blueprint`
 * through the generic DailyLoopView adapter.
 *
 * Run from `backend/`:
 *   deno run --allow-net --allow-env --allow-read scripts/seed-branch-blueprints.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { CardDeck, DailyLoopBlueprint } from "../src/types.ts";

interface BranchSeed {
  loopId: string;
  arxivId: string;
  topic: string;
  heroEyebrow: string;
  heroTitle: string;
  heroHighlight: string;
  heroBody: string;
  hookTitle: string;
  hookHighlight: string;
  hookBody: string;
  coreTitle: string;
  coreHighlight: string;
  coreFindings: Array<{ title: string; detail: string }>;
  analogyLabel: string;
  analogyTitle: string;
  analogyHighlight: string;
  analogyBody: string;
  analogyBold: string;
  diagramTitle: string;
  diagramHighlight: string;
  diagramNodes: Array<{ id: string; label: string; sublabel: string; panelTitle: string; panelBody: string }>;
  vizBars: Array<{ label: string; sublabel: string; primary: number; annotation: string }>;
  vizTitle: string;
  vizHighlight: string;
  vizCaption: string;
  vizTakeaway: string;
  completeQuote: string;
  completeTease: string;
  glossary: Record<string, string>;
}

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

const seeds: BranchSeed[] = [
  {
    loopId: "vit",
    arxivId: "2010.11929",
    topic: "Vision",
    heroEyebrow: "VISION · TRANSFORMERS",
    heroTitle: "An image becomes a sentence of patches",
    heroHighlight: "sentence of patches",
    heroBody: "ViT showed that a plain Transformer could understand images if you chop the picture into patches and treat those patches like tokens.",
    hookTitle: "What if a photo could be read like text?",
    hookHighlight: "read",
    hookBody: "Older image models scanned nearby pixels with sliding filters. ViT cut the image into a grid of small patches, lined them up like words, and let attention decide which patches should talk.",
    coreTitle: "Three moves turn pixels into tokens",
    coreHighlight: "tokens",
    coreFindings: [
      { title: "Cut the image into patches", detail: "A picture becomes a grid of square patch tokens, each flattened into numbers." },
      { title: "Add position so order survives", detail: "Position embeddings tell each patch where it came from in the original image." },
      { title: "Let attention connect the scene", detail: "Self-attention lets any patch compare itself with any other patch, even far across the image." },
    ],
    analogyLabel: "ANALOGY · A MOSAIC ON A TABLE",
    analogyTitle: "Like solving a picture tile by tile",
    analogyHighlight: "tile by tile",
    analogyBody: "Imagine cutting a poster into square tiles. A normal vision model studies nearby tiles first. ViT lets every tile ask every other tile what it contains.",
    analogyBold: "every tile ask every other tile",
    diagramTitle: "How ViT reads an image",
    diagramHighlight: "reads an image",
    diagramNodes: [
      node("image", "Image", "pixels", "Raw picture", "The input is ordinary pixels. ViT changes how the picture is packaged."),
      node("patches", "Patches", "16 x 16", "Visual tokens", "The picture is split into equal squares. Each square becomes one token."),
      node("position", "Position", "where", "Grid memory", "Position embeddings put the grid back after flattening."),
      node("attention", "Attention", "global", "Whole scene", "Every patch can compare with every other patch."),
    ],
    vizBars: [
      bar("32px", "coarse", 25, "Large patches are cheap but hide detail."),
      bar("16px", "ViT-B", 65, "A common setting balances detail and sequence length."),
      bar("8px", "fine", 95, "Small patches preserve detail but make attention expensive."),
    ],
    vizTitle: "Smaller patches, more tokens",
    vizHighlight: "more tokens",
    vizCaption: "Patch size decides how long the image sequence gets.",
    vizTakeaway: "The image is tokenised before it is understood.",
    completeQuote: "\"A picture can become a sequence, and attention can learn the scene.\"",
    completeTease: "Next: diffusion makes images by reversing noise.",
    glossary: {
      patch: "A square chunk of an image treated like one token.",
      "position embedding": "A learned marker that tells the model where a token came from.",
      "self-attention": "A mechanism where every token compares itself with other tokens.",
    },
  },
  {
    loopId: "ddpm",
    arxivId: "2006.11239",
    topic: "Vision",
    heroEyebrow: "VISION · DIFFUSION",
    heroTitle: "Make an image by removing noise",
    heroHighlight: "removing noise",
    heroBody: "DDPM taught image generation as a cleanup game: add noise until pictures vanish, then learn to reverse the mess one tiny step at a time.",
    hookTitle: "Can you recover a picture from static?",
    hookHighlight: "static",
    hookBody: "DDPM starts with a real image, adds a little noise, then more and more until only static remains. The model learns the reverse move.",
    coreTitle: "Diffusion is reverse corruption",
    coreHighlight: "reverse corruption",
    coreFindings: [
      { title: "Add noise in known steps", detail: "The forward process slowly corrupts a real image with Gaussian noise." },
      { title: "Predict the noise", detail: "The model sees a noisy image and timestep, then predicts what noise was added." },
      { title: "Denoise from pure static", detail: "Generation starts with random noise and repeatedly subtracts predicted noise." },
    ],
    analogyLabel: "ANALOGY · RESTORING A SMUDGED DRAWING",
    analogyTitle: "Like cleaning a sketch one smudge at a time",
    analogyHighlight: "one smudge at a time",
    analogyBody: "A diffusion model starts with a page covered in smudges and learns tiny cleanup moves that make the hidden picture sharper.",
    analogyBold: "tiny cleanup moves",
    diagramTitle: "How DDPM runs backward",
    diagramHighlight: "runs backward",
    diagramNodes: [
      node("clean", "Clean", "x0", "Clean image", "Training starts with a real image."),
      node("noise", "Noise", "q step", "Forward noising", "A known process adds noise until the image becomes static."),
      node("predict", "Predict", "epsilon", "Predict noise", "The neural network learns to identify the noise component."),
      node("sample", "Sample", "reverse", "Reverse process", "Sampling applies the learned cleanup step again and again."),
    ],
    vizBars: [
      bar("t0", "clean", 0, "The image starts clean."),
      bar("t250", "fuzzy", 35, "Noise softens the image but structure remains."),
      bar("t750", "hidden", 75, "Only faint structure remains."),
      bar("t1000", "static", 100, "The image is basically pure noise."),
    ],
    vizTitle: "Noise rises, image fades",
    vizHighlight: "image fades",
    vizCaption: "The forward process is simple. The learned model is the reverse process.",
    vizTakeaway: "Generation is the noising movie played backward.",
    completeQuote: "\"Diffusion makes images by learning how to undo noise.\"",
    completeTease: "Next: Stable Diffusion moves this process into a smaller latent space.",
    glossary: {
      diffusion: "A generation method that learns to reverse a gradual noising process.",
      "Gaussian noise": "Random noise shaped like a normal distribution.",
      timestep: "The position on the noise schedule.",
    },
  },
  {
    loopId: "clip",
    arxivId: "2103.00020",
    topic: "Vision",
    heroEyebrow: "VISION · LANGUAGE",
    heroTitle: "Images and words meet on one map",
    heroHighlight: "one map",
    heroBody: "CLIP learned from internet image-caption pairs until pictures and text landed in the same embedding space.",
    hookTitle: "How do you search photos with ordinary words?",
    hookHighlight: "ordinary words",
    hookBody: "CLIP made search like \"a dog wearing sunglasses\" work by learning that an image and a sentence can point to the same idea.",
    coreTitle: "The trick is matching pairs",
    coreHighlight: "matching pairs",
    coreFindings: [
      { title: "Encode the image", detail: "An image encoder turns a picture into a vector." },
      { title: "Encode the text", detail: "A text encoder turns the caption into a vector on the same map." },
      { title: "Pull matches together", detail: "The real image-caption pair moves close, and mismatches move apart." },
    ],
    analogyLabel: "ANALOGY · A TWO-LANGUAGE ATLAS",
    analogyTitle: "Like a map where photos and captions share streets",
    analogyHighlight: "share streets",
    analogyBody: "If red bicycle and the actual bike photo land on the same corner, search becomes nearest-neighbor lookup.",
    analogyBold: "same corner",
    diagramTitle: "How CLIP aligns two worlds",
    diagramHighlight: "aligns two worlds",
    diagramNodes: [
      node("image", "Image", "encoder", "Image encoder", "Pixels become a vector."),
      node("text", "Text", "encoder", "Text encoder", "Captions become vectors in the same space."),
      node("contrast", "Contrast", "match", "Contrastive loss", "Correct pairs are pulled together and wrong pairs pushed apart."),
      node("map", "Shared map", "zero-shot", "Shared map", "New labels can work without a new classifier."),
    ],
    vizBars: [
      bar("Dog", "correct", 92, "The real caption should score highest."),
      bar("Car", "decoy", 18, "A mismatched caption is pushed away."),
      bar("Soup", "decoy", 9, "Another mismatch teaches what does not match."),
      bar("Beach", "decoy", 14, "The batch creates many wrong pairings for free."),
    ],
    vizTitle: "One match, many decoys",
    vizHighlight: "many decoys",
    vizCaption: "A single batch creates many negative examples for free.",
    vizTakeaway: "CLIP learns meaning by contrast.",
    completeQuote: "\"CLIP learned a bridge between seeing and naming.\"",
    completeTease: "Next: Stable Diffusion uses language to steer generation.",
    glossary: {
      "embedding space": "A map of vectors where nearby points mean similar things.",
      "contrastive loss": "A training objective that pulls matches together and pushes mismatches apart.",
      "zero-shot": "Doing a task without training specifically on that task.",
    },
  },
  {
    loopId: "stable-diffusion",
    arxivId: "2112.10752",
    topic: "Vision",
    heroEyebrow: "VISION · LATENT DIFFUSION",
    heroTitle: "Diffusion gets small enough to ship",
    heroHighlight: "small enough to ship",
    heroBody: "Stable Diffusion made image generation practical by denoising compressed latent images instead of full pixel grids.",
    hookTitle: "Why clean every pixel when you can clean the sketch?",
    hookHighlight: "the sketch",
    hookBody: "Pixel diffusion is expensive because every step touches every pixel. Stable Diffusion compresses the image, denoises the smaller latent, then decodes back to pixels.",
    coreTitle: "Stable Diffusion has three rooms",
    coreHighlight: "three rooms",
    coreFindings: [
      { title: "Compress the image", detail: "An autoencoder turns pixels into a compact latent map." },
      { title: "Denoise the latent", detail: "The diffusion model works in the smaller space, so each step costs less." },
      { title: "Guide it with text", detail: "A text encoder conditions denoising so the image follows the prompt." },
    ],
    analogyLabel: "ANALOGY · RENOVATING THE BLUEPRINT",
    analogyTitle: "Edit the blueprint, then build the house",
    analogyHighlight: "blueprint",
    analogyBody: "Instead of repainting a whole building brick by brick, Stable Diffusion works on the compact plan, then renders the finished building.",
    analogyBold: "compact plan",
    diagramTitle: "How Stable Diffusion saves work",
    diagramHighlight: "saves work",
    diagramNodes: [
      node("prompt", "Prompt", "text", "Prompt", "Text supplies the direction."),
      node("latent", "Latent", "small map", "Latent space", "The image lives as a compressed feature map."),
      node("denoise", "Denoise", "U-Net", "Latent denoising", "A U-Net removes noise while listening to the text condition."),
      node("decode", "Decode", "pixels", "Decode to pixels", "The cleaned latent becomes a full image."),
    ],
    vizBars: [
      bar("Pixels", "full image", 100, "Pixel diffusion works on the full image grid."),
      bar("Latent", "compressed", 6, "Latent diffusion works on a much smaller representation."),
    ],
    vizTitle: "Denoise fewer numbers",
    vizHighlight: "fewer numbers",
    vizCaption: "The model spends most of its time in the compact latent map.",
    vizTakeaway: "Compression made diffusion practical.",
    completeQuote: "\"Stable Diffusion made diffusion small enough to run outside the biggest labs.\"",
    completeTease: "Next: ControlNet adds a steering wheel.",
    glossary: {
      latent: "A compressed representation that keeps important structure while using fewer numbers.",
      autoencoder: "A model that compresses data and then reconstructs it.",
      conditioning: "Extra information, such as text, that guides generation.",
    },
  },
  {
    loopId: "controlnet",
    arxivId: "2302.05543",
    topic: "Vision",
    heroEyebrow: "VISION · CONTROL",
    heroTitle: "Tell diffusion where things go",
    heroHighlight: "where things go",
    heroBody: "ControlNet adds a trainable side network that lets sketches, poses, edges, and depth maps steer a frozen diffusion model.",
    hookTitle: "A prompt says what. A sketch says where.",
    hookHighlight: "where",
    hookBody: "Text-to-image models are good at subject and style, but weak at exact layout. ControlNet gives diffusion a structure input like a pose skeleton or edge map.",
    coreTitle: "ControlNet adds a steering copy",
    coreHighlight: "steering copy",
    coreFindings: [
      { title: "Keep the base model frozen", detail: "The original diffusion model keeps its image knowledge." },
      { title: "Train a control branch", detail: "A copied branch learns to read edges, depth, poses, or scribbles." },
      { title: "Inject control safely", detail: "Zero-initialized connections let control grow without breaking the base model." },
    ],
    analogyLabel: "ANALOGY · COLORING INSIDE A STENCIL",
    analogyTitle: "The model paints, the stencil holds shape",
    analogyHighlight: "stencil holds shape",
    analogyBody: "A prompt is asking for a dancer. ControlNet is handing the model a stencil of the dancer's pose.",
    analogyBold: "stencil",
    diagramTitle: "How ControlNet steers diffusion",
    diagramHighlight: "steers diffusion",
    diagramNodes: [
      node("control", "Control", "pose or edge", "Control input", "A structure image provides layout information."),
      node("frozen", "Frozen", "base", "Frozen diffusion model", "The pretrained model keeps broad image skill."),
      node("branch", "Branch", "trainable", "Control branch", "A parallel branch learns how structure should influence layers."),
      node("image", "Image", "guided", "Guided image", "The result follows prompt and structure."),
    ],
    vizBars: [
      bar("Pose", "body", 92, "A skeleton can lock character posture."),
      bar("Edges", "outline", 86, "An edge map preserves boundaries."),
      bar("Depth", "space", 78, "Depth guides foreground and background."),
      bar("Scribble", "rough", 62, "A rough sketch still helps."),
    ],
    vizTitle: "Different maps, different control",
    vizHighlight: "different control",
    vizCaption: "ControlNet turns prompt-only guessing into structure-guided creation.",
    vizTakeaway: "The control image anchors layout.",
    completeQuote: "\"ControlNet gives diffusion a steering wheel for structure.\"",
    completeTease: "Next: SAM makes segmentation promptable.",
    glossary: {
      "control signal": "An extra input, such as a pose or edge map, that guides image generation.",
      "frozen model": "A model whose weights are kept unchanged during training.",
      "zero convolution": "A connection initialized to output zero so it starts with no effect.",
    },
  },
  {
    loopId: "sam",
    arxivId: "2304.02643",
    topic: "Vision",
    heroEyebrow: "VISION · SEGMENTATION",
    heroTitle: "Click anything, cut it out",
    heroHighlight: "cut it out",
    heroBody: "SAM made image segmentation promptable: click, box, or mask an object, and the model returns a clean segment.",
    hookTitle: "What if the magic wand worked on almost anything?",
    hookHighlight: "almost anything",
    hookBody: "Segmentation means marking the exact pixels of an object. SAM turns that into a promptable task with points, boxes, and masks.",
    coreTitle: "SAM separates image understanding from prompting",
    coreHighlight: "prompting",
    coreFindings: [
      { title: "Encode the image once", detail: "A large vision encoder turns the image into reusable features." },
      { title: "Encode the prompt", detail: "A point, box, or mask tells the model what object the user means." },
      { title: "Decode possible masks", detail: "A lightweight decoder outputs candidate masks and quality scores." },
    ],
    analogyLabel: "ANALOGY · POINTING AT A SHOP WINDOW",
    analogyTitle: "You point, it understands the object",
    analogyHighlight: "understands the object",
    analogyBody: "If you point at a jacket in a crowded window, a person knows you mean the jacket. SAM gives a model that pointing interface.",
    analogyBold: "pointing interface",
    diagramTitle: "How SAM answers a click",
    diagramHighlight: "answers a click",
    diagramNodes: [
      node("image", "Image", "encoder", "Image encoder", "The model computes visual features for the full image."),
      node("prompt", "Prompt", "point or box", "Prompt encoder", "The user prompt tells the model what matters."),
      node("decoder", "Decoder", "mask", "Mask decoder", "Image and prompt features combine into masks."),
      node("score", "Score", "quality", "Mask score", "SAM can return multiple masks when the prompt is ambiguous."),
    ],
    vizBars: [
      bar("Point", "quick", 45, "A single click is fast but sometimes ambiguous."),
      bar("Box", "bounded", 75, "A box narrows the object region."),
      bar("Mask", "rough", 92, "A rough mask gives the strongest hint."),
    ],
    vizTitle: "Different hints, same task",
    vizHighlight: "same task",
    vizCaption: "Promptable segmentation serves many editing and annotation workflows.",
    vizTakeaway: "The user supplies intent with a tiny prompt.",
    completeQuote: "\"SAM turned segmentation into a promptable interface.\"",
    completeTease: "Next: language scaling makes new abilities appear.",
    glossary: {
      segmentation: "Marking exactly which pixels belong to an object or region.",
      mask: "A pixel-level selection of an object.",
      promptable: "Able to respond to user hints like points, boxes, or masks.",
    },
  },
  {
    loopId: "t5",
    arxivId: "1910.10683",
    topic: "Language",
    heroEyebrow: "LANGUAGE · TEXT-TO-TEXT",
    heroTitle: "Every language task becomes text in, text out",
    heroHighlight: "text in, text out",
    heroBody: "T5 unified translation, summarization, classification, and question answering by casting every task as text-to-text.",
    hookTitle: "What if every homework question used one answer box?",
    hookHighlight: "one answer box",
    hookBody: "Before T5, different NLP tasks used different heads and formats. T5 flattened the mess into one interface: prefix the task, input text, output text.",
    coreTitle: "One format, many tasks",
    coreHighlight: "many tasks",
    coreFindings: [
      { title: "Prefix the task", detail: "Inputs start with instructions like translate, summarize, or answer question." },
      { title: "Use one encoder-decoder model", detail: "The encoder reads the input and the decoder writes output text." },
      { title: "Pretrain by filling spans", detail: "T5 removes chunks of text and learns to generate the missing spans." },
    ],
    analogyLabel: "ANALOGY · ONE UNIVERSAL WORKSHEET",
    analogyTitle: "Same worksheet, different prompts",
    analogyHighlight: "different prompts",
    analogyBody: "The top line says translate, summarize, or classify. The student writes the answer in the same box every time.",
    analogyBold: "same box",
    diagramTitle: "How T5 standardises NLP",
    diagramHighlight: "standardises NLP",
    diagramNodes: [
      node("prefix", "Prefix", "task", "Task prefix", "A short phrase tells the model what job to do."),
      node("input", "Input", "text", "Input text", "The sentence, document, or question comes after the prefix."),
      node("model", "T5", "encoder-decoder", "Text-to-text Transformer", "One model handles all tasks through the same interface."),
      node("output", "Output", "text", "Output text", "The answer is always generated text."),
    ],
    vizBars: [
      bar("Translate", "text", 92, "Translation fits text-to-text naturally."),
      bar("Summarize", "text", 90, "Summaries are output strings."),
      bar("Classify", "label", 85, "Even labels can be written as text."),
      bar("QA", "answer", 88, "Question answering becomes generating the answer."),
    ],
    vizTitle: "Different tasks, same doorway",
    vizHighlight: "same doorway",
    vizCaption: "T5 made one clean API for NLP.",
    vizTakeaway: "Text-to-text simplified transfer learning.",
    completeQuote: "\"T5 turned NLP into one sentence-shaped interface.\"",
    completeTease: "Next: Chinchilla fixes the scaling budget.",
    glossary: {
      "text-to-text": "A setup where both input and output are text strings.",
      "task prefix": "Instruction text placed before the input.",
      "span corruption": "A pretraining task where chunks of text are removed and regenerated.",
    },
  },
  {
    loopId: "chinchilla",
    arxivId: "2203.15556",
    topic: "Language",
    heroEyebrow: "LANGUAGE · SCALING",
    heroTitle: "Bigger models needed more words",
    heroHighlight: "more words",
    heroBody: "Chinchilla showed many large language models were undertrained: too many parameters, too little data for the compute being spent.",
    hookTitle: "If you buy a bigger brain, should you also buy more books?",
    hookHighlight: "more books",
    hookBody: "Chinchilla reframed scale as a budget split between model size and training tokens.",
    coreTitle: "The compute budget has two knobs",
    coreHighlight: "two knobs",
    coreFindings: [
      { title: "Parameters are capacity", detail: "More parameters give the model room to store patterns." },
      { title: "Tokens are practice", detail: "More training tokens give the model more examples." },
      { title: "Balance beats brute size", detail: "For the same compute, a smaller model trained on more data can win." },
    ],
    analogyLabel: "ANALOGY · A STUDENT AND A LIBRARY",
    analogyTitle: "A genius still needs homework",
    analogyHighlight: "homework",
    analogyBody: "One student has a huge notebook but reads a few pages. Another has a smaller notebook and works through the library. Practice wins.",
    analogyBold: "Practice wins",
    diagramTitle: "How Chinchilla spends compute",
    diagramHighlight: "spends compute",
    diagramNodes: [
      node("compute", "Compute", "fixed", "Compute budget", "Training spend is limited."),
      node("params", "Params", "capacity", "Parameters", "A larger model can represent more patterns."),
      node("tokens", "Tokens", "practice", "Training tokens", "Tokens are practice problems."),
      node("balance", "Balance", "optimal", "Chinchilla point", "Best performance balances parameters and tokens."),
    ],
    vizBars: [
      bar("Gopher", "280B", 78, "Very large, but comparatively undertrained."),
      bar("Chinchilla", "70B", 88, "Smaller, trained on far more tokens."),
      bar("Too small", "limited", 64, "Too little capacity cannot absorb all the data."),
    ],
    vizTitle: "Smaller, better trained",
    vizHighlight: "better trained",
    vizCaption: "A 70B model trained properly beat a 280B model trained too briefly.",
    vizTakeaway: "Undertrained giant models were wasting compute.",
    completeQuote: "\"The smartest model has enough parameters and enough practice.\"",
    completeTease: "Next: PaLM scales the whole stack.",
    glossary: {
      parameter: "A learned number inside a model.",
      token: "A chunk of text the model trains on.",
      "scaling law": "A rule predicting how performance changes with size, data, and compute.",
    },
  },
  {
    loopId: "palm",
    arxivId: "2204.02311",
    topic: "Language",
    heroEyebrow: "LANGUAGE · SCALE",
    heroTitle: "Scale made abilities show up",
    heroHighlight: "show up",
    heroBody: "PaLM scaled a dense Transformer to 540B parameters and highlighted abilities that appeared more clearly at large scale.",
    hookTitle: "Some skills only appear after enough practice.",
    hookHighlight: "enough practice",
    hookBody: "PaLM studied how reasoning, code, and multilingual transfer became much stronger as model size and training grew.",
    coreTitle: "PaLM is about large-scale capability",
    coreHighlight: "large-scale capability",
    coreFindings: [
      { title: "A very large dense model", detail: "PaLM used 540 billion parameters in one dense Transformer." },
      { title: "Pathways made training possible", detail: "The training system coordinated work across thousands of accelerator chips." },
      { title: "Emergent behaviors became visible", detail: "Some tasks improved sharply only at larger sizes." },
    ],
    analogyLabel: "ANALOGY · A CITY GETS PUBLIC TRANSIT",
    analogyTitle: "At city size, new patterns appear",
    analogyHighlight: "new patterns appear",
    analogyBody: "A tiny town has streets. A giant city needs subways, stations, and rush hour patterns. Scaling changes behavior.",
    analogyBold: "Scaling changes behavior",
    diagramTitle: "What PaLM scaled",
    diagramHighlight: "scaled",
    diagramNodes: [
      node("data", "Data", "broad", "Broad data", "The model trained on broad multilingual text and code."),
      node("params", "Params", "540B", "Model size", "A huge dense Transformer gave the model capacity."),
      node("system", "Pathways", "TPUs", "Training system", "Distributed training made the run possible."),
      node("skills", "Skills", "emerge", "Capabilities", "Reasoning, code, and multilingual behavior strengthened."),
    ],
    vizBars: [
      bar("Data", "corpus", 82, "Large models need broad data."),
      bar("Params", "capacity", 100, "PaLM's headline number was 540B parameters."),
      bar("Compute", "TPUs", 96, "Training required distributed compute."),
      bar("Eval", "tasks", 75, "Many tasks showed where scale helped."),
    ],
    vizTitle: "Not just model size, the whole stack",
    vizHighlight: "whole stack",
    vizCaption: "Large language models are systems papers as much as model papers.",
    vizTakeaway: "Capability came from scaling data, model, compute, and evaluation together.",
    completeQuote: "\"PaLM made the scale story impossible to ignore.\"",
    completeTease: "Next: LLaMA makes strong models more accessible.",
    glossary: {
      "dense model": "A model where all parameters are active for each token.",
      "emergent ability": "A capability that appears or improves sharply at larger scale.",
      Pathways: "Google's distributed training system used for PaLM.",
    },
  },
  {
    loopId: "llama",
    arxivId: "2302.13971",
    topic: "Language",
    heroEyebrow: "LANGUAGE · OPEN WEIGHTS",
    heroTitle: "Smaller models, trained harder",
    heroHighlight: "trained harder",
    heroBody: "LLaMA showed that carefully trained open-weight models could punch far above their parameter count.",
    hookTitle: "What if the secret was not bigger, but better trained?",
    hookHighlight: "better trained",
    hookBody: "LLaMA trained smaller models on many more tokens, used strong data and modern Transformer details, then released weights to researchers.",
    coreTitle: "LLaMA's recipe is efficient scale",
    coreHighlight: "efficient scale",
    coreFindings: [
      { title: "More tokens per parameter", detail: "The models were trained on far more text than older similarly sized models." },
      { title: "Modern Transformer details", detail: "RMSNorm, SwiGLU, and rotary embeddings made the model cleaner and stronger." },
      { title: "Open weights changed the ecosystem", detail: "Researchers could fine tune, inspect, compress, and run capable models locally." },
    ],
    analogyLabel: "ANALOGY · A COMPACT ATHLETE",
    analogyTitle: "Not the biggest body, the best training camp",
    analogyHighlight: "best training camp",
    analogyBody: "LLaMA is like a smaller athlete with excellent coaching and endless drills. It beats larger rivals that did not get enough practice.",
    analogyBold: "excellent coaching",
    diagramTitle: "How LLaMA punches up",
    diagramHighlight: "punches up",
    diagramNodes: [
      node("data", "Data", "tokens", "More training tokens", "Each parameter gets more practice."),
      node("arch", "Architecture", "modern", "Modern tweaks", "Small choices improve stability and efficiency."),
      node("weights", "Weights", "released", "Released weights", "The community could build directly on the model."),
      node("adapt", "Adapt", "fine tune", "Adaptation wave", "Fine-tuned descendants spread quickly."),
    ],
    vizBars: [
      bar("13B", "well trained", 72, "A smaller model could compete with much larger older models."),
      bar("33B", "strong", 84, "More size plus efficient training improved results."),
      bar("65B", "frontier-ish", 92, "The largest model approached bigger closed systems."),
    ],
    vizTitle: "Fewer parameters, more practice",
    vizHighlight: "more practice",
    vizCaption: "LLaMA models competed above their weight class.",
    vizTakeaway: "Efficient training made smaller models matter again.",
    completeQuote: "\"LLaMA made capable language models feel reachable.\"",
    completeTease: "Next: Mixtral wakes only the experts it needs.",
    glossary: {
      "open weights": "Model parameters released so others can run and adapt the model.",
      "fine tune": "Continue training a model on task-specific data.",
      quantization: "Compressing weights into fewer bits so inference is cheaper.",
    },
  },
  {
    loopId: "mixtral",
    arxivId: "2401.04088",
    topic: "Language",
    heroEyebrow: "LANGUAGE · EXPERTS",
    heroTitle: "A big model where only some experts wake up",
    heroHighlight: "some experts wake up",
    heroBody: "Mixtral uses a sparse mixture of experts so each token activates only a small part of a much larger model.",
    hookTitle: "Why ask the whole committee when two specialists will do?",
    hookHighlight: "two specialists",
    hookBody: "Mixtral has multiple expert feed-forward networks and a router. For each token, the router chooses the top experts.",
    coreTitle: "Mixtral is sparse expertise",
    coreHighlight: "sparse expertise",
    coreFindings: [
      { title: "Many experts exist", detail: "Each layer has several expert networks that can specialize in different patterns." },
      { title: "A router picks a few", detail: "For each token, a learned router sends the token to the most relevant experts." },
      { title: "Compute stays lower", detail: "Only selected experts run, so active parameters are much smaller than total parameters." },
    ],
    analogyLabel: "ANALOGY · A HELP DESK WITH SPECIALISTS",
    analogyTitle: "Route each question to the right desks",
    analogyHighlight: "right desks",
    analogyBody: "A help desk has billing, hardware, travel, and security specialists. You do not ask everyone every question.",
    analogyBold: "do not ask everyone",
    diagramTitle: "How Mixtral routes tokens",
    diagramHighlight: "routes tokens",
    diagramNodes: [
      node("token", "Token", "input", "Incoming token", "Each token reaches a mixture-of-experts layer."),
      node("router", "Router", "top 2", "Router", "A learned gate picks the best experts."),
      node("experts", "Experts", "sparse", "Selected experts", "Only chosen experts process the token."),
      node("combine", "Combine", "output", "Combine outputs", "Expert outputs are weighted and merged."),
    ],
    vizBars: [
      bar("Total", "all experts", 47, "Mixtral has roughly 47B total parameters."),
      bar("Active", "per token", 13, "Only around 13B parameters are active per token."),
    ],
    vizTitle: "Lots of parameters, fewer active",
    vizHighlight: "fewer active",
    vizCaption: "Big capacity without paying full dense-model cost on every token.",
    vizTakeaway: "Sparse routing buys capacity with lower active compute.",
    completeQuote: "\"Mixtral separates model capacity from active compute.\"",
    completeTease: "Next: agents learn to remember their mistakes.",
    glossary: {
      "mixture of experts": "A layer with several specialist networks and a router that picks which ones run.",
      router: "A learned gate that sends each token to selected experts.",
      sparse: "Only part of the model activates for each input.",
    },
  },
  {
    loopId: "reflexion",
    arxivId: "2303.11366",
    topic: "Reasoning",
    heroEyebrow: "REASONING · AGENTS",
    heroTitle: "After failing, write the lesson down",
    heroHighlight: "write the lesson down",
    heroBody: "Reflexion gives an agent a verbal memory of what went wrong, so the next attempt starts wiser.",
    hookTitle: "What do you do after bombing a test? You review the mistake.",
    hookHighlight: "review the mistake",
    hookBody: "Reflexion adds a simple habit: after each attempt, the agent writes a short reflection and stores it in memory.",
    coreTitle: "Reflexion adds verbal memory",
    coreHighlight: "verbal memory",
    coreFindings: [
      { title: "Act in the world", detail: "The agent tries a task, such as coding, web navigation, or question answering." },
      { title: "Evaluate the attempt", detail: "An external signal says whether the attempt worked or failed." },
      { title: "Reflect before retrying", detail: "The model writes a natural-language lesson and includes that memory in the next prompt." },
    ],
    analogyLabel: "ANALOGY · A NOTEBOOK OF MISTAKES",
    analogyTitle: "Like keeping a mistake journal",
    analogyHighlight: "mistake journal",
    analogyBody: "After a bad chess game, you might write: stop moving the queen out early. Next game, that note changes your choices.",
    analogyBold: "that note changes your choices",
    diagramTitle: "How Reflexion learns without weight updates",
    diagramHighlight: "without weight updates",
    diagramNodes: [
      node("try", "Try", "act", "Try the task", "The agent produces actions or an answer."),
      node("score", "Score", "feedback", "Score the result", "A test or evaluator marks success or failure."),
      node("reflect", "Reflect", "lesson", "Write a reflection", "The model turns failure into a note."),
      node("memory", "Memory", "next try", "Use memory", "The next prompt includes the reflection."),
    ],
    vizBars: [
      bar("No note", "repeat", 35, "Without memory, the agent may repeat the mistake."),
      bar("Reflection", "learn", 68, "A useful note changes the next attempt."),
      bar("Bad note", "noise", 42, "Reflection only helps if the note captures the real failure."),
    ],
    vizTitle: "Memory turns failure into signal",
    vizHighlight: "signal",
    vizCaption: "The key move is converting outcome feedback into a reusable instruction.",
    vizTakeaway: "Reflection is memory, not magic.",
    completeQuote: "\"Reflexion turns a failed attempt into a note the next attempt can use.\"",
    completeTease: "Next: agents that plan, search, and use tools.",
    glossary: {
      agent: "A model-driven system that can act, observe results, and continue.",
      reflection: "A natural-language note about what went wrong or what to try next.",
      memory: "Stored context from earlier attempts that can be added to a future prompt.",
    },
  },
];

console.log(`Target: ${SUPABASE_URL}`);
console.log(`Seeding ${seeds.length} branch blueprint decks...`);

for (const seed of seeds) {
  const meta = await fetchArxivMeta(seed.arxivId);
  const title = displayTitle(seed, meta.title || seed.heroTitle);
  const blueprint = makeBlueprint(seed, title);
  console.log(`  ${seed.loopId} -> ${title.slice(0, 70)}...`);

  const { error: paperErr } = await supabase.from("papers").upsert({
    paper_id: seed.loopId,
    title,
    authors: meta.authors,
    abstract: meta.abstract,
    source: "arxiv",
    url: `https://arxiv.org/abs/${seed.arxivId}`,
    pdf_url: null,
    arxiv_category: meta.arxiv_category,
    published_at: meta.published_at,
    score: 0.97,
    score_breakdown: { recency: 0.8, social: 1.0, keyword: 1.0, author: 0.95 },
    status: "processed",
  }, { onConflict: "paper_id" });
  if (paperErr) fail("papers upsert", paperErr.message);

  const { error: canonicalPaperErr } = await supabase.from("papers").upsert({
    paper_id: `arxiv:${seed.arxivId}`,
    title: meta.title || title,
    authors: meta.authors,
    abstract: meta.abstract,
    source: "arxiv",
    url: `https://arxiv.org/abs/${seed.arxivId}`,
    pdf_url: null,
    arxiv_category: meta.arxiv_category,
    published_at: meta.published_at,
    score: 0.9,
    score_breakdown: { recency: 0.8, social: 0.9, keyword: 1.0, author: 0.9 },
    status: "processed",
  }, { onConflict: "paper_id" });
  if (canonicalPaperErr) fail("canonical papers upsert", canonicalPaperErr.message);

  const cards: Pick<CardDeck, "hook" | "summary" | "concepts"> = {
    hook: seed.hookTitle,
    summary: seed.heroBody,
    concepts: [
      { title: searchLabel(seed), body: seed.heroBody },
      ...seed.coreFindings.map((finding) => ({ title: finding.title, body: finding.detail })),
    ],
  };

  const { error: cardErr } = await supabase.from("cards").upsert({
    paper_id: seed.loopId,
    title,
    source: "curated",
    url: `https://arxiv.org/abs/${seed.arxivId}`,
    cards,
    blueprint,
  }, { onConflict: "paper_id" });
  if (cardErr) fail("cards upsert", cardErr.message);

  const { error: catalogErr } = await supabase.from("paper_catalog").upsert({
    paper_id: seed.loopId,
    canonical_key: `arxiv:${seed.arxivId}`,
    title,
    authors: meta.authors,
    published_at: meta.published_at,
    year: new Date(meta.published_at).getUTCFullYear(),
    source: "curated",
    origin: "curated",
    topic: seed.topic,
    url: `https://arxiv.org/abs/${seed.arxivId}`,
    arxiv_id: seed.arxivId,
    updated_at: new Date().toISOString(),
  }, { onConflict: "paper_id" });
  if (catalogErr) fail("paper_catalog upsert", catalogErr.message);
}

console.log("Done.");

function makeBlueprint(seed: BranchSeed, paperTitle: string): DailyLoopBlueprint {
  return {
    heroEyebrow: seed.heroEyebrow,
    heroTitle: hi(seed.heroTitle, seed.heroHighlight),
    heroBody: seed.heroBody,
    sourceLine: `arXiv:${seed.arxivId} · ${seed.topic}`,
    hookTitle: hi(seed.hookTitle, seed.hookHighlight),
    hookBody: seed.hookBody,
    coreIdeaTitle: hi(seed.coreTitle, seed.coreHighlight),
    coreFindings: seed.coreFindings,
    eliAnalogyLabel: seed.analogyLabel,
    eliHeadline: hi(seed.analogyTitle, seed.analogyHighlight),
    eliBody: { text: seed.analogyBody, bold: seed.analogyBold },
    diagramTitle: hi(seed.diagramTitle, seed.diagramHighlight),
    timelineNodes: seed.diagramNodes,
    diagramCollapseText: "",
    diagramDefaultPanelBody: "Tap each checkpoint to build the mental model one piece at a time.",
    vizCards: [
      {
        kicker: "CARD 05 · THE MECHANISM",
        title: hi(seed.vizTitle, seed.vizHighlight),
        spec: {
          kind: "bar",
          yAxisLabel: "relative importance",
          primaryLabel: "Signal",
          secondaryLabel: "Reference",
          yTickLabels: ["0", "0.5", "1.0"],
          points: seed.vizBars.map((point) => ({
            ...point,
            primary: point.primary / 100,
            secondary: 0,
          })),
          defaultInsight: "Tap a bar. Each one shows a different part of the paper's central tradeoff.",
        },
        caption: seed.vizCaption,
        takeaway: seed.vizTakeaway,
      },
    ],
    completeQuote: seed.completeQuote,
    completeTease: seed.completeTease,
    paperTitle,
    glossary: seed.glossary,
    diagramLayout: "flow",
  };
}

function displayTitle(seed: BranchSeed, title: string): string {
  return title;
}

function searchLabel(seed: BranchSeed): string {
  const labels: Record<string, string> = {
    "vit": "ViT",
    "ddpm": "DDPM",
    "clip": "CLIP",
    "stable-diffusion": "Stable Diffusion",
    "controlnet": "ControlNet",
    "sam": "SAM",
    "t5": "T5",
    "chinchilla": "Chinchilla",
    "palm": "PaLM",
    "llama": "LLaMA",
    "mixtral": "Mixtral",
    "reflexion": "Reflexion",
  };
  return labels[seed.loopId] ?? seed.heroTitle;
}

function hi(text: string, highlight: string) {
  return { text, highlight };
}

function node(id: string, label: string, sublabel: string, panelTitle: string, panelBody: string) {
  return { id, label, sublabel, panelTitle, panelBody };
}

function bar(label: string, sublabel: string, primary: number, annotation: string) {
  return { label, sublabel, primary, annotation };
}

function fail(label: string, message: string): never {
  console.error(`${label}: ${message}`);
  Deno.exit(1);
}

async function fetchArxivMeta(arxivId: string) {
  const res = await fetch(`https://export.arxiv.org/api/query?id_list=${arxivId}&max_results=1`);
  if (!res.ok) throw new Error(`arXiv ${res.status} for ${arxivId}`);
  const xml = await res.text();
  const entry = xml.match(/<entry>([\s\S]*?)<\/entry>/)?.[1];
  if (!entry) throw new Error(`arXiv entry missing for ${arxivId}`);
  const tag = (t: string) =>
    entry.match(new RegExp(`<${t}[^>]*>([\\s\\S]*?)</${t}>`))?.[1]
      ?.replace(/\s+/g, " ")
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .trim();
  const title = tag("title") ?? "";
  const abstract = tag("summary") ?? "";
  const published = entry.match(/<published>([\s\S]*?)<\/published>/)?.[1]?.trim();
  const category =
    entry.match(/<arxiv:primary_category[^>]*\bterm="([^"]+)"/)?.[1] ??
    entry.match(/<category[^>]*\bterm="([^"]+)"/)?.[1] ??
    null;
  const authors = Array.from(entry.matchAll(/<author>\s*<name>([\s\S]*?)<\/name>\s*<\/author>/g))
    .map((m) => m[1].replace(/\s+/g, " ").trim());
  if (!title || !abstract) throw new Error(`arXiv metadata incomplete for ${arxivId}`);
  return {
    title,
    abstract,
    authors,
    arxiv_category: category,
    published_at: published ?? new Date().toISOString(),
  };
}
