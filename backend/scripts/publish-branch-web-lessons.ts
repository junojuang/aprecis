/**
 * Publish bespoke web-bundle lessons for the branch roadmap batch.
 *
 * These replace the old DailyLoopBlueprint reader at open time. The search
 * cards can still exist, but WebLessonRegistry will route these paper ids to
 * the hosted lesson bundles through paper_catalog.web_lesson_url.
 *
 * Run from `backend/`:
 *   deno run --allow-net --allow-env --allow-read --allow-write scripts/publish-branch-web-lessons.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const env = await load({ envPath: "./.env.local", export: true });
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const BUCKET = "web-lessons";

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

type Lesson = {
  loopId: string;
  slug: string;
  title: string;
  arxivId: string;
  topic: string;
  year: number;
  authors: string;
  eyebrow: string;
  cover: { a: string; b: string; c: string; stand: string };
  hook: { title: string; p1: string; p2: string };
  map: { title: string; p1: string; p2: string; caption: string; left: string; mid: string; right: string };
  toggle: { title: string; intro: string; off: string; on: string; offNote: string; onNote: string };
  mechanism: { title: string; p1: string; p2: string; lock: string; train: string; bridge: string };
  slider: { title: string; intro: string; low: string; mid: string; high: string; left: string; right: string };
  chooser: { title: string; intro: string; items: Array<[string, string]>; done: string };
  result: { title: string; p1: string; p2: string; bars: Array<[string, string, number]>; caption: string };
  payoff: { title: string; p1: string; p2: string };
  recap: Array<[string, string]>;
  quote: string;
};

const lessons: Lesson[] = [
  {
    loopId: "vit",
    slug: "vit",
    title: "An Image is Worth 16x16 Words: Transformers for Image Recognition at Scale",
    arxivId: "2010.11929",
    topic: "Vision",
    year: 2020,
    authors: "Dosovitskiy et al. · Google Research",
    eyebrow: "Aprecis · Vision",
    cover: {
      a: "A picture became",
      b: "a sentence",
      c: "of patches.",
      stand: "ViT asked a strange question: what if an image is just a list of visual words?",
    },
    hook: {
      title: "Stop scanning. Start reading.",
      p1: "Convolutional networks look locally first. They slide small filters across nearby pixels and build the scene from neighborhoods.",
      p2: "ViT cuts the image into fixed patches, turns each patch into a token, adds position, then lets a plain Transformer compare every patch with every other patch.",
    },
    map: {
      title: "Pixels become tokens before they become meaning",
      p1: "The paper's core move is packaging. A 224 by 224 image becomes a sequence of patch embeddings, often 16 by 16 pixels per patch.",
      p2: "After that, image recognition looks surprisingly like language modeling: a sequence enters attention, global relationships form, and one class token gathers the answer.",
      caption: "The model does not scan a picture. It reads a sequence made from the picture.",
      left: "image",
      mid: "patch tokens",
      right: "class token",
    },
    toggle: {
      title: "Choose the lens.",
      intro: "Switch between local scanning and global patch attention. The difference is not the goal, it is the path information takes.",
      off: "Convolution",
      on: "ViT",
      offNote: "A convolution sees nearby pixels first. Faraway pieces meet only after many layers.",
      onNote: "A ViT patch can compare with any other patch immediately, even across the image.",
    },
    mechanism: {
      title: "Position keeps the grid alive",
      p1: "Flattening patches would destroy where each tile came from, so ViT adds a learned position embedding to every patch token.",
      p2: "The Transformer sees a sentence of patches, but the position marks let it recover the two-dimensional scene.",
      lock: "patch",
      train: "position",
      bridge: "attention",
    },
    slider: {
      title: "Shrink the patch.",
      intro: "Patch size is the tradeoff. Smaller patches preserve more detail, but they make the sequence longer.",
      low: "Large patches are cheap, but details disappear inside each token.",
      mid: "A 16 by 16 patch is the paper's memorable compromise.",
      high: "Tiny patches keep detail but make attention expensive fast.",
      left: "cheap",
      right: "detailed",
    },
    chooser: {
      title: "Build the ViT recipe.",
      intro: "Pick the ingredients that make the paper work.",
      items: [["Patchify", "cut the picture into equal squares"], ["Linear projection", "turn each square into numbers"], ["Position", "remember where the square came from"], ["Class token", "collect the final decision"], ["Transformer", "let patches compare globally"], ["Pretraining", "use large datasets before transfer"]],
      done: "That is ViT: image patches treated as a Transformer sequence.",
    },
    result: {
      title: "Scale made the simple idea win",
      p1: "A plain Transformer was not automatically better on small data. It needed large-scale pretraining before the patch recipe paid off.",
      p2: "That was the lesson: remove image-specific bias, then buy performance back with data and scale.",
      bars: [["Small data", "not enough", 34], ["ImageNet-21k", "strong", 72], ["JFT-300M", "best", 94]],
      caption: "The less built-in vision knowledge you give the model, the more data it needs.",
    },
    payoff: {
      title: "Vision joined the sequence era",
      p1: "ViT did not make convolutions vanish. It proved that attention could be a first-class vision engine.",
      p2: "After that, images, text, video, and audio could be treated with one shared idea: tokenize the world, then let attention connect it.",
    },
    recap: [["Cut", "Split an image into patches."], ["Mark", "Add position so the grid survives."], ["Attend", "Let every patch compare globally."], ["Scale", "Use big pretraining to make the simple recipe work."]],
    quote: "ViT made a picture readable by a Transformer.",
  },
  {
    loopId: "ddpm",
    slug: "ddpm",
    title: "Denoising Diffusion Probabilistic Models",
    arxivId: "2006.11239",
    topic: "Vision",
    year: 2020,
    authors: "Ho, Jain, and Abbeel",
    eyebrow: "Aprecis · Diffusion",
    cover: {
      a: "Start with",
      b: "static",
      c: "and clean backward.",
      stand: "DDPM made image generation feel like restoring a picture one tiny denoising step at a time.",
    },
    hook: {
      title: "The model learns the undo button.",
      p1: "Training begins with real images. The forward process adds a little Gaussian noise, then more, until the image becomes pure static.",
      p2: "The neural network is trained on the reverse question: given a noisy image and a timestep, what noise should be removed?",
    },
    map: {
      title: "Generation is corruption played backward",
      p1: "The noising process is fixed and simple. The learned part is the reverse process, a long chain of small cleanup moves.",
      p2: "Sampling starts from random noise. Step by step, the model predicts and subtracts noise until structure appears.",
      caption: "Forward is easy to define. Reverse is what the model learns.",
      left: "clean image",
      mid: "known noise",
      right: "reverse sample",
    },
    toggle: {
      title: "Play the movie direction.",
      intro: "Switch directions. One path destroys information by design. The other tries to recover it.",
      off: "Forward",
      on: "Reverse",
      offNote: "Forward diffusion gradually hides the image under known noise.",
      onNote: "Reverse diffusion starts from static and applies learned cleanup steps.",
    },
    mechanism: {
      title: "Predict the noise, not the picture",
      p1: "The model does not directly paint the whole final image at every step. It predicts the noise component that was added.",
      p2: "That target turns generation into a repeated denoising problem, which is easier to learn and surprisingly stable.",
      lock: "noisy x",
      train: "epsilon",
      bridge: "subtract",
    },
    slider: {
      title: "Move through time.",
      intro: "Drag from clean image to pure static. The timestep tells the model how much noise it is facing.",
      low: "Early steps still show the image clearly.",
      mid: "Middle steps keep rough structure, but details are fading.",
      high: "Late steps are almost pure noise, which is where sampling begins.",
      left: "clean",
      right: "static",
    },
    chooser: {
      title: "Pick the diffusion pieces.",
      intro: "Diffusion works because each piece has a simple job.",
      items: [["Noise schedule", "decides how fast corruption grows"], ["Timestep", "tells the model where it is"], ["U-Net", "predicts noise from the noisy image"], ["Gaussian noise", "the known corruption source"], ["Reverse chain", "runs many cleanup steps"], ["Sampling", "starts with random static"]],
      done: "All pieces point to the same idea: learn the reverse of a known mess.",
    },
    result: {
      title: "Slow, steady, high quality",
      p1: "DDPM traded speed for stability. Many reverse steps made sampling slow, but the images were strong enough to reshape generative modeling.",
      p2: "The paper also connected denoising, likelihood, and score-based generation into one practical recipe.",
      bars: [["GAN speed", "fast", 88], ["DDPM quality", "strong", 86], ["DDPM steps", "many", 96]],
      caption: "Diffusion won trust by making generation gradual and controllable.",
    },
    payoff: {
      title: "Noise became a canvas",
      p1: "DDPM reframed generation as learning how data falls apart, then reversing that fall.",
      p2: "Stable Diffusion, text-to-image systems, and many modern generators inherit this cleanup-game foundation.",
    },
    recap: [["Corrupt", "Add noise in known steps."], ["Predict", "Train the model to identify the noise."], ["Reverse", "Sample by subtracting noise repeatedly."], ["Create", "Let structure appear from static."]],
    quote: "Diffusion makes images by learning how to undo noise.",
  },
  {
    loopId: "clip",
    slug: "clip",
    title: "Learning Transferable Visual Models From Natural Language Supervision",
    arxivId: "2103.00020",
    topic: "Vision",
    year: 2021,
    authors: "Radford et al. · OpenAI",
    eyebrow: "Aprecis · Vision",
    cover: {
      a: "Pictures and words",
      b: "met",
      c: "on one map.",
      stand: "CLIP learned from internet image-text pairs until search, labeling, and zero-shot recognition became the same move.",
    },
    hook: {
      title: "A caption can become a classifier.",
      p1: "Classic vision models train on fixed label sets. CLIP trains on image-caption pairs collected at web scale.",
      p2: "It learns two encoders: one for images, one for text. Matching image and text land close together, mismatches move apart.",
    },
    map: {
      title: "Two encoders share one space",
      p1: "The image encoder maps pixels into a vector. The text encoder maps a caption into the same vector space.",
      p2: "At inference, a label can be written as text, compared to the image, and used without training a new classifier.",
      caption: "The trick is not a new label head. It is a shared map.",
      left: "image",
      mid: "shared space",
      right: "text",
    },
    toggle: {
      title: "Use labels or language.",
      intro: "Switch the training signal. One teaches a fixed menu. The other teaches open-ended descriptions.",
      off: "Fixed labels",
      on: "Captions",
      offNote: "A fixed label set says this is class 337. Useful, but boxed in.",
      onNote: "Natural language gives richer supervision: objects, style, actions, context, and relationships.",
    },
    mechanism: {
      title: "One match, many decoys",
      p1: "In a batch, each image has one correct caption and many wrong captions. CLIP scores all pairings.",
      p2: "The real pair is pulled together. The decoys are pushed away. That contrast teaches visual meaning.",
      lock: "image",
      train: "caption",
      bridge: "contrast",
    },
    slider: {
      title: "Raise the batch pressure.",
      intro: "More examples in a batch means more wrong pairings for free.",
      low: "With few decoys, the matching task is easy and weak.",
      mid: "More decoys force sharper distinctions.",
      high: "Many decoys make the model learn fine-grained alignment.",
      left: "few decoys",
      right: "many decoys",
    },
    chooser: {
      title: "Assemble zero-shot recognition.",
      intro: "Pick what lets CLIP classify without a new classifier.",
      items: [["Image encoder", "turns the image into a vector"], ["Text encoder", "turns labels into vectors"], ["Prompt templates", "phrases labels as captions"], ["Cosine similarity", "compares image and text"], ["Contrastive loss", "aligns matching pairs"], ["Web data", "broadens what the model sees"]],
      done: "Zero-shot CLIP is just nearest text in the shared space.",
    },
    result: {
      title: "Transfer came from language",
      p1: "CLIP could classify datasets it was not trained on by comparing images to text prompts.",
      p2: "The paper made language supervision feel like a reusable interface for vision.",
      bars: [["Fixed head", "narrow", 42], ["CLIP zero-shot", "broad", 78], ["Prompting", "adaptable", 88]],
      caption: "The label space can change because labels are text.",
    },
    payoff: {
      title: "Search became semantic",
      p1: "CLIP is why typing ordinary words can retrieve images by meaning, not just tags.",
      p2: "It also became a steering component for image generation, including Stable Diffusion.",
    },
    recap: [["Pair", "Train on image-caption pairs."], ["Align", "Put pictures and text on one map."], ["Compare", "Score image-text similarity."], ["Transfer", "Use language as new labels."]],
    quote: "CLIP taught vision to answer in language space.",
  },
  {
    loopId: "stable-diffusion",
    slug: "stable-diffusion",
    title: "High-Resolution Image Synthesis with Latent Diffusion Models",
    arxivId: "2112.10752",
    topic: "Vision",
    year: 2021,
    authors: "Rombach et al.",
    eyebrow: "Aprecis · Diffusion",
    cover: {
      a: "Do the hard work",
      b: "small",
      c: "then decode.",
      stand: "Stable Diffusion made text-to-image practical by denoising compressed latents instead of full pixel grids.",
    },
    hook: {
      title: "Why clean every pixel?",
      p1: "Pixel diffusion works, but high-resolution images are expensive. Every denoising step touches a huge grid.",
      p2: "Latent diffusion compresses the image first. The model denoises the smaller representation, then decodes it back to pixels.",
    },
    map: {
      title: "The picture moves through three rooms",
      p1: "An autoencoder maps pixels into a compact latent space. A diffusion model works there. A decoder returns the final image.",
      p2: "Text conditioning steers the denoising process so the compact image plan follows the prompt.",
      caption: "The model spends most of its budget in the smaller latent room.",
      left: "pixels",
      mid: "latent",
      right: "pixels",
    },
    toggle: {
      title: "Choose the workspace.",
      intro: "Switch between denoising pixels directly and denoising a compressed latent.",
      off: "Pixels",
      on: "Latent",
      offNote: "Pixel diffusion works on the full image grid at every cleanup step.",
      onNote: "Latent diffusion works on a compressed map, then decodes the image at the end.",
    },
    mechanism: {
      title: "Compression keeps the meaning",
      p1: "The autoencoder is trained so the latent keeps perceptual structure while dropping unnecessary pixel detail.",
      p2: "That makes denoising cheaper without throwing away the shapes and textures the decoder needs.",
      lock: "encode",
      train: "denoise",
      bridge: "decode",
    },
    slider: {
      title: "Compress the canvas.",
      intro: "Drag toward latent space. The working grid shrinks, but the model still needs enough structure to reconstruct the image.",
      low: "Full pixels are faithful but expensive.",
      mid: "A compact latent keeps semantic structure.",
      high: "Too much compression would starve the decoder.",
      left: "pixels",
      right: "latent",
    },
    chooser: {
      title: "Build Stable Diffusion.",
      intro: "Pick the parts that make text-to-image practical.",
      items: [["Autoencoder", "compresses and reconstructs images"], ["Latent U-Net", "denoises the compact map"], ["Text encoder", "turns a prompt into conditioning"], ["Cross-attention", "injects words into image cleanup"], ["Decoder", "returns pixels"], ["Noise schedule", "sets the cleanup path"]],
      done: "The recipe is compression plus text-guided denoising.",
    },
    result: {
      title: "Fewer numbers, bigger images",
      p1: "Moving diffusion into latent space cut the cost enough to make high-resolution synthesis broadly usable.",
      p2: "The paper's impact was not just image quality. It changed where the compute was spent.",
      bars: [["Pixel grid", "large", 100], ["Latent map", "small", 18], ["Text control", "strong", 84]],
      caption: "The central win is doing repeated denoising on a smaller representation.",
    },
    payoff: {
      title: "Diffusion became shippable",
      p1: "Stable Diffusion is not a single trick. It is an engineering arrangement that made a powerful generator practical.",
      p2: "Once the work moved into latents, text-to-image could spread beyond the biggest labs.",
    },
    recap: [["Encode", "Compress pixels into latents."], ["Denoise", "Clean the compact map."], ["Condition", "Let text steer the cleanup."], ["Decode", "Return a full image."]],
    quote: "Stable Diffusion made diffusion small enough to leave the lab.",
  },
  {
    loopId: "sam",
    slug: "sam",
    title: "Segment Anything",
    arxivId: "2304.02643",
    topic: "Vision",
    year: 2023,
    authors: "Kirillov et al. · Meta AI",
    eyebrow: "Aprecis · Vision",
    cover: {
      a: "Point once.",
      b: "Cut out",
      c: "almost anything.",
      stand: "SAM turned segmentation into a promptable interface: click, box, or mask, then get object pixels back.",
    },
    hook: {
      title: "The magic wand learned to generalize.",
      p1: "Segmentation means marking exactly which pixels belong to an object. Old systems were usually trained for specific categories or datasets.",
      p2: "SAM changes the interface. The user gives a prompt, such as a point or box, and the model returns masks for the intended object.",
    },
    map: {
      title: "Image once, prompt many times",
      p1: "A heavy image encoder computes reusable image features. A prompt encoder represents points, boxes, or masks.",
      p2: "A lightweight mask decoder combines both, so the same image can be queried again and again.",
      caption: "SAM separates seeing the image from asking what to cut out.",
      left: "image",
      mid: "prompt",
      right: "mask",
    },
    toggle: {
      title: "Click or box the target.",
      intro: "Switch prompt styles. The model is built to accept different hints for the same segmentation task.",
      off: "Point",
      on: "Box",
      offNote: "A point is fast, but it can be ambiguous when objects overlap.",
      onNote: "A box narrows the region and gives the decoder a stronger hint.",
    },
    mechanism: {
      title: "Ambiguity is allowed",
      p1: "A single click can mean different objects. SAM can return multiple candidate masks with quality scores.",
      p2: "That matters because promptable segmentation is an interaction, not a one-shot classifier.",
      lock: "image",
      train: "prompt",
      bridge: "mask",
    },
    slider: {
      title: "Add a stronger hint.",
      intro: "Move from a tiny point to a richer mask prompt. More user intent usually means less ambiguity.",
      low: "A point is quick but vague.",
      mid: "A box tells the model where to look.",
      high: "A rough mask gives the clearest intent.",
      left: "vague",
      right: "specific",
    },
    chooser: {
      title: "Pick the SAM ingredients.",
      intro: "Promptable segmentation needs both model design and data.",
      items: [["Image encoder", "computes reusable features"], ["Prompt encoder", "represents clicks and boxes"], ["Mask decoder", "outputs candidate masks"], ["Quality score", "ranks mask guesses"], ["SA-1B data", "scales segmentation examples"], ["Interactive loop", "lets users refine intent"]],
      done: "SAM is a segmentation model designed as an interface.",
    },
    result: {
      title: "A dataset and a model together",
      p1: "The paper introduced SAM and the SA-1B dataset, a huge collection of segmentation masks.",
      p2: "The scale matters because the model is expected to segment objects beyond a fixed vocabulary.",
      bars: [["Old task", "fixed", 38], ["Promptable", "flexible", 84], ["SA-1B", "scale", 96]],
      caption: "General segmentation needed both a promptable model and broad mask data.",
    },
    payoff: {
      title: "Segmentation became a tool",
      p1: "SAM made object masks feel like an interface primitive for editing, labeling, robotics, and data collection.",
      p2: "The user no longer needs the model to know the class name. They can simply point.",
    },
    recap: [["Encode", "Read the image once."], ["Prompt", "Accept points, boxes, or masks."], ["Decode", "Generate candidate masks."], ["Refine", "Let the user clarify intent."]],
    quote: "SAM turned segmentation into pointing.",
  },
  {
    loopId: "t5",
    slug: "t5",
    title: "Exploring the Limits of Transfer Learning with a Unified Text-to-Text Transformer",
    arxivId: "1910.10683",
    topic: "Language",
    year: 2019,
    authors: "Raffel et al. · Google",
    eyebrow: "Aprecis · Language",
    cover: {
      a: "Every NLP task",
      b: "became",
      c: "text in, text out.",
      stand: "T5 made translation, summarization, classification, and question answering share one simple interface.",
    },
    hook: {
      title: "One answer box for every task.",
      p1: "Before T5, different language tasks often had different heads, losses, and output formats.",
      p2: "T5 asked what happens if every task is cast the same way: give the model text, ask it to generate text.",
    },
    map: {
      title: "A prefix turns text into a task",
      p1: "The input begins with a task prefix like translate, summarize, or answer question.",
      p2: "The same encoder-decoder Transformer reads the input and writes the output, whatever the task.",
      caption: "The interface is simple enough to reuse across the whole benchmark zoo.",
      left: "prefix",
      mid: "text",
      right: "text",
    },
    toggle: {
      title: "Use many heads or one interface.",
      intro: "Switch formats. T5's bet is that task variety should live in text, not custom output machinery.",
      off: "Task heads",
      on: "Text-to-text",
      offNote: "Separate tasks often need separate output heads and special handling.",
      onNote: "T5 writes every answer as text, even labels and classifications.",
    },
    mechanism: {
      title: "Pretraining by filling holes",
      p1: "T5 masks spans of text, replaces them with sentinel tokens, and trains the model to generate the missing spans.",
      p2: "That span-corruption objective teaches the model to read context and produce text in the same format it will use later.",
      lock: "prefix",
      train: "span",
      bridge: "output",
    },
    slider: {
      title: "Unify the task.",
      intro: "Move from special-purpose formats to one text-to-text channel.",
      low: "Many custom heads make transfer messy.",
      mid: "Task prefixes begin to standardize behavior.",
      high: "One output format lets tasks share the same model path.",
      left: "custom",
      right: "unified",
    },
    chooser: {
      title: "Build the T5 setup.",
      intro: "Pick the choices that make the unified recipe work.",
      items: [["Task prefix", "tells the model what to do"], ["Encoder", "reads the input text"], ["Decoder", "writes the answer"], ["Span corruption", "pretrains by filling missing chunks"], ["C4 corpus", "provides broad text"], ["Text labels", "turn classifications into generated words"]],
      done: "T5 is a model plus a disciplined text interface.",
    },
    result: {
      title: "The interface carried transfer",
      p1: "The paper was a systematic study of what works in transfer learning, but its durable idea was the unified format.",
      p2: "Once every task looks like text generation, multitask training and evaluation become much cleaner.",
      bars: [["Translate", "text", 92], ["Summarize", "text", 90], ["Classify", "label text", 82], ["QA", "answer text", 88]],
      caption: "Different jobs enter through the same door.",
    },
    payoff: {
      title: "Instructions became data",
      p1: "T5 helped normalize the idea that tasks can be represented as text prompts and text outputs.",
      p2: "That design line runs straight into instruction tuning and modern promptable models.",
    },
    recap: [["Prefix", "Name the task in text."], ["Read", "Use one encoder-decoder model."], ["Write", "Generate every answer as text."], ["Transfer", "Share one format across tasks."]],
    quote: "T5 turned NLP into one sentence-shaped interface.",
  },
  {
    loopId: "chinchilla",
    slug: "chinchilla",
    title: "Training Compute-Optimal Large Language Models",
    arxivId: "2203.15556",
    topic: "Language",
    year: 2022,
    authors: "Hoffmann et al. · DeepMind",
    eyebrow: "Aprecis · Scaling",
    cover: {
      a: "The giant model",
      b: "needed",
      c: "more homework.",
      stand: "Chinchilla showed that many large language models were too big for the amount of data they saw.",
    },
    hook: {
      title: "Bigger was not the whole answer.",
      p1: "Scaling language models costs compute. You can spend that compute on more parameters, more training tokens, or both.",
      p2: "Chinchilla found that many models were undertrained: too many parameters, too few tokens for the budget.",
    },
    map: {
      title: "Compute has two knobs",
      p1: "Parameters are capacity. Tokens are practice. The paper studies how to balance them under a fixed compute budget.",
      p2: "The surprising result: a smaller model trained on far more data can beat a much larger model trained too briefly.",
      caption: "The best model is not always the biggest model.",
      left: "compute",
      mid: "parameters",
      right: "tokens",
    },
    toggle: {
      title: "Spend on size or practice.",
      intro: "Switch the budget split. One side buys capacity. The other buys examples.",
      off: "More size",
      on: "More data",
      offNote: "A huge model has room, but without enough tokens the room stays underused.",
      onNote: "More data gives each parameter more practice, which can beat brute size.",
    },
    mechanism: {
      title: "The 70B model beat the 280B model",
      p1: "DeepMind compared Gopher at 280B parameters with Chinchilla at 70B parameters trained on many more tokens.",
      p2: "For the same broad compute story, the smaller, better-trained model won across many evaluations.",
      lock: "70B",
      train: "tokens",
      bridge: "win",
    },
    slider: {
      title: "Rebalance the budget.",
      intro: "Drag toward data. The optimum is not all model and not all tokens.",
      low: "Too few tokens leaves a large model undertrained.",
      mid: "Balanced scaling uses capacity and practice together.",
      high: "Too little capacity cannot absorb unlimited data.",
      left: "parameters",
      right: "tokens",
    },
    chooser: {
      title: "Name the scaling ingredients.",
      intro: "Chinchilla is about the budget, not one architecture trick.",
      items: [["Parameters", "learned numbers inside the model"], ["Tokens", "training examples seen by the model"], ["Compute", "the fixed training budget"], ["Loss curves", "measure how training improves"], ["Optimal frontier", "best split for a budget"], ["Evaluation", "tests whether the split worked"]],
      done: "The paper turns scaling into a budget allocation problem.",
    },
    result: {
      title: "Smaller, better trained",
      p1: "Chinchilla had 70B parameters, much smaller than Gopher's 280B, but it trained on far more tokens.",
      p2: "The lesson changed how labs thought about model size: do not just scale width, scale practice.",
      bars: [["Gopher", "280B", 76], ["Chinchilla", "70B", 90], ["Undertrained", "too brief", 48]],
      caption: "A model can be too large for its diet.",
    },
    payoff: {
      title: "The scaling recipe changed",
      p1: "Chinchilla made undertraining visible. It told builders that data quantity was not a detail.",
      p2: "Modern LLM recipes still carry this lesson: parameters and tokens have to grow together.",
    },
    recap: [["Budget", "Training compute is finite."], ["Capacity", "Parameters store patterns."], ["Practice", "Tokens teach those patterns."], ["Balance", "The best split beats brute size."]],
    quote: "A bigger brain still needs enough books.",
  },
  {
    loopId: "palm",
    slug: "palm",
    title: "PaLM: Scaling Language Modeling with Pathways",
    arxivId: "2204.02311",
    topic: "Language",
    year: 2022,
    authors: "Chowdhery et al. · Google",
    eyebrow: "Aprecis · Scaling",
    cover: {
      a: "At 540B parameters,",
      b: "new skills",
      c: "became visible.",
      stand: "PaLM showed what happens when model size, training systems, data, and evaluation scale together.",
    },
    hook: {
      title: "Some abilities show up late.",
      p1: "PaLM was a 540B-parameter dense Transformer trained with the Pathways system.",
      p2: "The paper became a scale landmark because reasoning, code, and multilingual behavior improved sharply at large size.",
    },
    map: {
      title: "Scale is a whole stack",
      p1: "The headline is model size, but the system also needed broad data, distributed training, and large evaluation suites.",
      p2: "PaLM is not just a model paper. It is a story about making a giant training run actually work.",
      caption: "Capability came from model, data, compute, and measurement together.",
      left: "data",
      mid: "540B model",
      right: "skills",
    },
    toggle: {
      title: "Look small or large.",
      intro: "Switch scale. Some tasks improve smoothly. Others look weak until the model crosses a size threshold.",
      off: "Smaller",
      on: "PaLM scale",
      offNote: "Smaller models can follow patterns, but many reasoning behaviors remain brittle.",
      onNote: "At PaLM scale, few-shot reasoning and code behaviors become much more visible.",
    },
    mechanism: {
      title: "Pathways moved the training load",
      p1: "Training a 540B dense model requires splitting work across many accelerator chips without drowning in communication.",
      p2: "The Pathways system is part of the paper's contribution because the model only exists if the training system can carry it.",
      lock: "data",
      train: "TPUs",
      bridge: "540B",
    },
    slider: {
      title: "Turn up scale.",
      intro: "Drag upward. Bigger models do not just memorize more, they can expose behaviors that were hard to see before.",
      low: "Small models show fragments of ability.",
      mid: "Mid-scale models improve across many tasks.",
      high: "At 540B, some behaviors become strikingly stronger.",
      left: "small",
      right: "540B",
    },
    chooser: {
      title: "Pick the PaLM stack.",
      intro: "Large capability needs more than one ingredient.",
      items: [["Dense Transformer", "all parameters active for each token"], ["540B parameters", "huge model capacity"], ["Pathways", "distributed training system"], ["Multilingual data", "broad language coverage"], ["Code data", "supports programming tasks"], ["Few-shot prompts", "test adaptation from examples"]],
      done: "PaLM is scale plus infrastructure plus evaluation.",
    },
    result: {
      title: "Scale widened the behavior menu",
      p1: "PaLM improved on many language, reasoning, code, and multilingual benchmarks.",
      p2: "The lasting lesson was not one benchmark number. It was the visibility of abilities that sharpen with scale.",
      bars: [["Language", "broad", 88], ["Reasoning", "late", 76], ["Code", "stronger", 72], ["Multilingual", "wide", 82]],
      caption: "The model became a testbed for what scale reveals.",
    },
    payoff: {
      title: "The system became the model",
      p1: "PaLM helped make it obvious that frontier language models are not just neural nets.",
      p2: "They are data pipelines, distributed systems, training recipes, and evaluation programs wrapped around a Transformer.",
    },
    recap: [["Scale", "Train a 540B dense model."], ["System", "Use Pathways to carry the run."], ["Evaluate", "Probe many tasks."], ["Reveal", "Watch abilities sharpen with size."]],
    quote: "PaLM made scale feel like a system-level capability.",
  },
  {
    loopId: "llama",
    slug: "llama",
    title: "LLaMA: Open and Efficient Foundation Language Models",
    arxivId: "2302.13971",
    topic: "Language",
    year: 2023,
    authors: "Touvron et al. · Meta AI",
    eyebrow: "Aprecis · Language",
    cover: {
      a: "Smaller models,",
      b: "trained harder,",
      c: "escaped the lab.",
      stand: "LLaMA showed that efficient training and open weights could make capable language models widely usable.",
    },
    hook: {
      title: "Not bigger. Better trained.",
      p1: "LLaMA focused on models from 7B to 65B parameters, trained on a large number of tokens.",
      p2: "The punchline was efficiency: smaller models could compete with much larger systems when trained carefully.",
    },
    map: {
      title: "Practice beats empty capacity",
      p1: "The recipe combines more tokens per parameter with modern Transformer details such as RMSNorm, SwiGLU, and rotary embeddings.",
      p2: "Then the weights were released for research, which let the community adapt, compress, and study them directly.",
      caption: "The paper mattered technically and socially.",
      left: "tokens",
      mid: "efficient model",
      right: "open weights",
    },
    toggle: {
      title: "Scale by size or training.",
      intro: "Switch the strategy. LLaMA leans into the Chinchilla lesson: smaller can be strong if it gets enough practice.",
      off: "Bigger only",
      on: "Trained harder",
      offNote: "A larger model without enough tokens wastes capacity.",
      onNote: "A smaller model trained on more data can punch above its size.",
    },
    mechanism: {
      title: "Modern details removed friction",
      p1: "RMSNorm stabilizes layers, SwiGLU improves feed-forward blocks, and rotary embeddings handle position.",
      p2: "None of those alone is the story. Together they make a clean, efficient Transformer recipe.",
      lock: "RMSNorm",
      train: "SwiGLU",
      bridge: "RoPE",
    },
    slider: {
      title: "Pick the model size.",
      intro: "Move from 7B toward 65B. The family matters because different sizes fit different hardware and use cases.",
      low: "7B is easier to run and adapt.",
      mid: "13B and 33B improve capability while staying practical.",
      high: "65B approaches much larger systems on several tasks.",
      left: "7B",
      right: "65B",
    },
    chooser: {
      title: "Build the LLaMA effect.",
      intro: "Pick the pieces that made the release matter.",
      items: [["More tokens", "train smaller models longer"], ["Efficient architecture", "use modern Transformer choices"], ["Model family", "offer several sizes"], ["Open weights", "let researchers run it"], ["Fine-tuning", "adapt to tasks"], ["Quantization", "make local use cheaper"]],
      done: "LLaMA became a platform because people could actually build on it.",
    },
    result: {
      title: "Capable and reachable",
      p1: "The 13B model competed with much larger models on several benchmarks, and the 65B model approached frontier behavior for its time.",
      p2: "The open-weight release accelerated a wave of local models and fine-tunes.",
      bars: [["7B", "compact", 58], ["13B", "punches up", 76], ["33B", "strong", 84], ["65B", "largest", 92]],
      caption: "The family made capability available at multiple sizes.",
    },
    payoff: {
      title: "The ecosystem changed",
      p1: "LLaMA did not just report a model. It gave researchers something concrete to run and modify.",
      p2: "That helped shift open language models from curiosity to fast-moving ecosystem.",
    },
    recap: [["Train", "Use many tokens per parameter."], ["Refine", "Apply efficient architecture details."], ["Release", "Share weights for research."], ["Adapt", "Let the community fine-tune and compress."]],
    quote: "LLaMA made strong models feel reachable.",
  },
  {
    loopId: "mixtral",
    slug: "mixtral",
    title: "Mixtral of Experts",
    arxivId: "2401.04088",
    topic: "Language",
    year: 2024,
    authors: "Jiang et al. · Mistral AI",
    eyebrow: "Aprecis · Language",
    cover: {
      a: "A big model",
      b: "where only two experts",
      c: "wake up.",
      stand: "Mixtral separated total capacity from active compute with sparse mixture-of-experts layers.",
    },
    hook: {
      title: "Do not ask the whole committee.",
      p1: "A dense model activates the same feed-forward machinery for every token.",
      p2: "Mixtral uses several expert networks and a router. For each token, only selected experts run.",
    },
    map: {
      title: "The router chooses specialists",
      p1: "Each token reaches a mixture-of-experts layer. A learned router scores the experts and sends the token to the top choices.",
      p2: "The outputs are weighted and combined, so the model has lots of total parameters but far fewer active parameters per token.",
      caption: "Capacity and compute are no longer the same number.",
      left: "token",
      mid: "router",
      right: "experts",
    },
    toggle: {
      title: "Wake everyone or route smartly.",
      intro: "Switch between dense compute and sparse expert routing.",
      off: "Dense",
      on: "Sparse",
      offNote: "A dense layer uses the same whole block for every token.",
      onNote: "A sparse expert layer activates only the chosen experts for that token.",
    },
    mechanism: {
      title: "Top-two routing keeps compute bounded",
      p1: "The router does not ask every expert. It picks the strongest few, commonly described as top-two routing.",
      p2: "That lets the model hold broad capacity while paying for a smaller active path.",
      lock: "router",
      train: "top 2",
      bridge: "combine",
    },
    slider: {
      title: "Choose active experts.",
      intro: "Move from one specialist to many. More active experts cost more compute.",
      low: "Too few experts can bottleneck a token.",
      mid: "Top-two routing balances specialization and cost.",
      high: "Using every expert becomes dense and expensive.",
      left: "one",
      right: "all",
    },
    chooser: {
      title: "Pick the MoE ingredients.",
      intro: "Sparse models need a routing system, not just more layers.",
      items: [["Experts", "specialist feed-forward networks"], ["Router", "scores experts for each token"], ["Top-k", "chooses a few experts"], ["Weighted sum", "combines expert outputs"], ["Load balance", "prevents one expert doing everything"], ["Active parameters", "the compute actually used"]],
      done: "Mixtral buys capacity without waking the whole model.",
    },
    result: {
      title: "Big capacity, smaller active path",
      p1: "Mixtral is often described as about 47B total parameters with roughly 13B active per token.",
      p2: "That made it a strong open model while keeping inference cheaper than activating everything.",
      bars: [["Total", "all experts", 94], ["Active", "per token", 32], ["Router", "selection", 72]],
      caption: "Sparse routing changes what model size means.",
    },
    payoff: {
      title: "The model became conditional compute",
      p1: "Mixtral makes each token choose its own route through the network.",
      p2: "That is the MoE promise: more stored knowledge, without paying the full dense cost every time.",
    },
    recap: [["Route", "Score experts for each token."], ["Select", "Activate only a few."], ["Combine", "Merge expert outputs."], ["Save", "Keep active compute lower than total capacity."]],
    quote: "Mixtral made model size conditional.",
  },
  {
    loopId: "reflexion",
    slug: "reflexion",
    title: "Reflexion: Language Agents with Verbal Reinforcement Learning",
    arxivId: "2303.11366",
    topic: "Reasoning",
    year: 2023,
    authors: "Shinn et al.",
    eyebrow: "Aprecis · Agents",
    cover: {
      a: "After failing,",
      b: "write down",
      c: "the lesson.",
      stand: "Reflexion lets an agent improve across attempts by storing natural-language reflections, not by changing weights.",
    },
    hook: {
      title: "A mistake becomes memory.",
      p1: "A normal prompted agent can fail, retry, and repeat the same mistake because nothing durable changed.",
      p2: "Reflexion adds a verbal memory: after an attempt, the model writes what went wrong and includes that note next time.",
    },
    map: {
      title: "Try, score, reflect, retry",
      p1: "The agent acts in an environment. A feedback signal says whether it succeeded. Then the model writes a reflection.",
      p2: "The next attempt receives that reflection in context, so the agent can avoid the previous failure.",
      caption: "The learning happens in language, not in the model weights.",
      left: "attempt",
      mid: "reflection",
      right: "retry",
    },
    toggle: {
      title: "Retry blind or retry with memory.",
      intro: "Switch the retry style. Same model, different context.",
      off: "No memory",
      on: "Reflexion",
      offNote: "Without a stored lesson, the next attempt can walk into the same trap.",
      onNote: "With a reflection, the model sees a compact note about what to avoid or try.",
    },
    mechanism: {
      title: "Verbal reinforcement replaces weight updates",
      p1: "Classic reinforcement learning updates parameters. Reflexion keeps the model fixed and updates the prompt memory.",
      p2: "That makes improvement cheap, interpretable, and tied to the agent's own attempt history.",
      lock: "act",
      train: "reflect",
      bridge: "memory",
    },
    slider: {
      title: "Improve across attempts.",
      intro: "Move from first try to later tries. The reflection becomes more useful only if it names the real failure.",
      low: "First attempts are often blind.",
      mid: "A decent note starts changing behavior.",
      high: "A precise reflection can prevent repeated errors.",
      left: "try 1",
      right: "retry",
    },
    chooser: {
      title: "Pick the Reflexion loop.",
      intro: "The agent needs a few roles to turn failure into signal.",
      items: [["Actor", "tries the task"], ["Evaluator", "judges success or failure"], ["Reflection", "writes the lesson"], ["Memory", "stores the note"], ["Retry", "uses the note next time"], ["Environment", "provides consequences"]],
      done: "The loop learns by changing context between attempts.",
    },
    result: {
      title: "Memory helped without retraining",
      p1: "The paper tests Reflexion on tasks such as coding, decision-making, and question answering.",
      p2: "Its key result is the pattern: feedback plus reflection can improve an agent without updating model weights.",
      bars: [["Blind retry", "repeat", 38], ["Reflection", "learn", 76], ["Bad note", "noise", 45]],
      caption: "Reflection only helps when the note captures the real failure.",
    },
    payoff: {
      title: "Agents gained a notebook",
      p1: "Reflexion made a simple point feel important: language can store lessons for future behavior.",
      p2: "That idea runs through modern agent systems that summarize mistakes, plans, and memories between attempts.",
    },
    recap: [["Act", "Try the task."], ["Judge", "Get a success signal."], ["Reflect", "Write what to change."], ["Reuse", "Put the note into the next attempt."]],
    quote: "Reflexion turns a failed attempt into usable memory.",
  },
];

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

const { data: buckets } = await supabase.storage.listBuckets();
if (!buckets?.some((bucket) => bucket.name === BUCKET)) {
  const { error } = await supabase.storage.createBucket(BUCKET, {
    public: true,
    fileSizeLimit: "10MB",
  });
  if (error) fail(`create bucket: ${error.message}`);
}

await Deno.mkdir("../prototypes/web-lesson/branch", { recursive: true });

for (const lesson of lessons) {
  const html = renderLesson(lesson);
  const localPath = `../prototypes/web-lesson/branch/${lesson.slug}.html`;
  await Deno.writeTextFile(localPath, html);

  const objectPath = `${lesson.slug}/index.html`;
  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(objectPath, new TextEncoder().encode(html), {
      contentType: "text/html; charset=utf-8",
      upsert: true,
    });
  if (uploadError) fail(`${lesson.slug} upload: ${uploadError.message}`);

  const publicUrl =
    `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${objectPath}?v=${Date.now()}`;

  const { error: catalogError } = await supabase
    .from("paper_catalog")
    .upsert({
      paper_id: lesson.loopId,
      canonical_key: `arxiv:${lesson.arxivId}`,
      title: lesson.title,
      source: "curated",
      origin: "curated",
      topic: lesson.topic,
      url: `https://arxiv.org/abs/${lesson.arxivId}`,
      arxiv_id: lesson.arxivId,
      year: lesson.year,
      published_at: `${lesson.year}-01-01T00:00:00Z`,
      web_lesson_url: publicUrl,
      updated_at: new Date().toISOString(),
    }, { onConflict: "paper_id" });
  if (catalogError) fail(`${lesson.slug} catalog: ${catalogError.message}`);

  console.log(`published ${lesson.loopId} -> ${lesson.title}`);
}

function renderLesson(lesson: Lesson): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<title>${escapeHtml(lesson.title)}</title>
<style>
:root{--paper:#f7f4ef;--ink:#11141a;--muted:#6b7078;--teal:#168383;--teal2:#27b2ae;--amber:#e2a33a;--line:rgba(17,20,26,.12);--serif:ui-serif,"New York",Georgia,"Times New Roman",serif;--sans:-apple-system,system-ui,"SF Pro Text",sans-serif;--mono:ui-monospace,Menlo,monospace}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}html,body{margin:0;height:100%;min-height:100dvh}body{max-width:430px;margin:0 auto;background:var(--paper);color:var(--ink);font-family:var(--sans);overflow:hidden;-webkit-font-smoothing:antialiased;display:flex;flex-direction:column}#bg{position:fixed;inset:0;z-index:-1;transition:background .35s}#bg.cover{background:radial-gradient(circle at 50% 28%,rgba(39,178,174,.27),transparent 58%),#10131a}#bg.paper{background:var(--paper)}#bg.focus{background:linear-gradient(to bottom,rgba(39,178,174,.12),rgba(247,244,239,0) 55%),var(--paper)}
.chrome{display:flex;align-items:center;gap:10px;padding:calc(8px + env(safe-area-inset-top,0px)) 18px 13px}.x{width:30px;height:30px;border:0;background:none;color:var(--ink);opacity:.7;font:600 15px var(--sans)}.rail{flex:1;display:flex;gap:4px}.seg{height:3px;flex:1;border-radius:3px;background:rgba(17,20,26,.16)}.seg.on{background:rgba(17,20,26,.85)}.count{width:38px;text-align:right;font:700 11px var(--mono);color:var(--muted)}
.stage{position:relative;flex:1;min-height:0;overflow:hidden}.card{position:absolute;inset:0;overflow-y:auto;-webkit-overflow-scrolling:touch;padding:0 22px 24px;opacity:0;transform:translateX(18px);pointer-events:none;transition:opacity .3s,transform .3s}.card.active{opacity:1;transform:none;pointer-events:auto}.card.back{transform:translateX(-18px)}.advance{padding:9px 22px calc(24px + env(safe-area-inset-bottom,0px));display:flex;flex-direction:column;gap:8px;flex:none}.hint{min-height:16px;text-align:center;font:italic 12px var(--serif);color:var(--muted)}.next{min-height:50px;border:0;border-radius:14px;background:var(--teal);color:white;font:700 15px var(--sans)}.next:disabled{background:rgba(17,20,26,.12);color:var(--muted)}
.stack{display:flex;flex-direction:column;gap:16px;align-items:flex-start}.sp{height:22px}.sp.sm{height:10px}.kicker{font:800 11px var(--sans);letter-spacing:2px;text-transform:uppercase;color:var(--teal)}h1{margin:0;font:600 28px/1.16 var(--serif);letter-spacing:0;color:var(--ink)}.prose{margin:0;font:16px/1.52 var(--serif);color:rgba(17,20,26,.82)}.hl{background:rgba(226,163,58,.28)}.b{font-weight:700;color:var(--ink)}.term{font-weight:700;color:var(--teal)}.panel{width:100%;border:1px solid var(--line);background:white;border-radius:16px;padding:14px}.caption{font:italic 12px var(--serif);color:var(--muted)}
.cover{min-height:100%;display:flex;flex-direction:column;text-align:center;align-items:center}.cover .eyebrow{padding-top:18px;color:var(--teal2);font:800 11px var(--sans);letter-spacing:2.3px;text-transform:uppercase}.cover h1{font-size:38px;line-height:1.05;color:#f4f1ea}.cover .amber{color:var(--amber)}.cover .stand{font:italic 15px/1.5 var(--serif);color:rgba(244,241,234,.64);padding:14px 8px 0}.grow{flex:1;min-height:16px}.hero{width:100%;height:210px;display:flex;align-items:center;justify-content:center}.appear{opacity:0;transform:scale(.94);transition:opacity .6s,transform .6s}.appear.in{opacity:1;transform:none}
.twocol{display:grid;grid-template-columns:1fr 1fr;gap:10px;width:100%}.mini{border:1px solid var(--line);border-radius:14px;background:white;padding:12px}.mini h2{margin:0 0 8px;font:800 10px var(--sans);letter-spacing:1.4px;text-transform:uppercase;color:var(--muted)}.mini p{margin:0;font:14px/1.35 var(--serif)}.switches{display:grid;grid-template-columns:1fr 1fr;gap:8px;width:100%}.sw{border:1px solid var(--line);border-radius:12px;background:white;padding:11px 8px;font:800 10px var(--sans);letter-spacing:1.1px;text-transform:uppercase;color:var(--muted)}.sw.on{background:var(--teal);border-color:var(--teal);color:white}.status{display:flex;gap:9px;align-items:flex-start}.dot{width:9px;height:9px;border-radius:50%;background:var(--amber);margin-top:5px;flex:none}.dot.ok{background:var(--teal)}.status .t{font:600 13px/1.4 var(--serif);color:rgba(17,20,26,.8)}
.bars{width:100%;display:flex;flex-direction:column;gap:12px}.barrow{display:grid;grid-template-columns:76px 1fr 46px;gap:10px;align-items:center}.lab{font:700 10px var(--mono);color:var(--muted)}.bar{height:16px;border-radius:999px;background:rgba(107,112,120,.13);overflow:hidden}.bar i{display:block;height:100%;width:0;background:var(--teal);border-radius:999px;transition:width .35s}.num{text-align:right;font:700 11px var(--mono)}input[type=range]{-webkit-appearance:none;appearance:none;width:100%;height:3px;border-radius:2px;background:rgba(22,131,131,.25);outline:none}input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:24px;height:24px;border-radius:50%;background:var(--teal);box-shadow:0 1px 4px rgba(0,0,0,.2)}
.choicegrid{display:grid;grid-template-columns:1fr 1fr;gap:8px;width:100%}.choice{border:1px solid var(--line);background:white;border-radius:14px;padding:12px;text-align:left}.choice b{display:block;font:700 13px var(--sans);margin-bottom:4px}.choice span{font:13px/1.35 var(--serif);color:var(--muted)}.choice.on{border-color:var(--teal);background:rgba(22,131,131,.08)}.quote{font:84px/0.6 var(--serif);color:rgba(22,131,131,.45);height:38px}.pquote{font:italic 22px/1.45 var(--serif)}.src{width:100%;display:flex;gap:10px;align-items:center;text-align:left;border:1px solid rgba(22,131,131,.35);background:white;border-radius:14px;padding:14px}.src small{display:block;color:var(--teal);font:800 9px var(--sans);letter-spacing:1.5px;text-transform:uppercase}.src b{font:600 14px var(--serif)}
</style>
</head>
<body>
<div id="bg" class="cover"></div>
<div class="chrome"><button class="x" id="close" aria-label="Close">x</button><div class="rail" id="rail"></div><div class="count" id="count">1/13</div></div>
<div class="stage" id="stage"></div>
<div class="advance"><div class="hint" id="hint"></div><button class="next" id="next">Start</button></div>
<script>
const LESSON=${JSON.stringify(lesson)};
const Aprecis={_s(n,b){const h=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers[n];h?h.postMessage(b||{}):console.log("[Aprecis]",n,b||"")},haptic(s){this._s("haptic",{style:s||"soft"})},select(){this.haptic("select")},success(){this.haptic("success")},markDone(){this._s("markDone")},finish(){this._s("finish")},close(){this._s("close")},openOriginal(u){this._s("openOriginal",{url:u})}};
function esc(s){return String(s).replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]))}
const P=(...x)=>'<p class="prose">'+x.join("")+'</p>', b=s=>'<span class="b">'+esc(s)+'</span>', hl=s=>'<span class="hl">'+esc(s)+'</span>', tm=s=>'<span class="term">'+esc(s)+'</span>';
function flowArt(a,b,c){return '<svg viewBox="0 0 320 170" width="100%" height="170" role="img"><rect x="12" y="22" width="296" height="126" rx="18" fill="#10131a"/><circle cx="74" cy="85" r="31" fill="rgba(226,163,58,.16)" stroke="rgba(226,163,58,.72)"/><circle cx="160" cy="85" r="31" fill="rgba(39,178,174,.16)" stroke="rgba(39,178,174,.72)"/><circle cx="246" cy="85" r="31" fill="rgba(244,241,234,.08)" stroke="rgba(244,241,234,.42)"/><path d="M108 85 H126 M194 85 H212" stroke="rgba(244,241,234,.55)" stroke-width="4" stroke-linecap="round"/><text x="74" y="89" text-anchor="middle" fill="#e2a33a" font-size="11" font-family="ui-monospace,Menlo,monospace">'+esc(a)+'</text><text x="160" y="89" text-anchor="middle" fill="#27b2ae" font-size="11" font-family="ui-monospace,Menlo,monospace">'+esc(b)+'</text><text x="246" y="89" text-anchor="middle" fill="rgba(244,241,234,.78)" font-size="11" font-family="ui-monospace,Menlo,monospace">'+esc(c)+'</text></svg>'}
function heroGlyph(){return flowArt(LESSON.map.left,LESSON.map.mid,LESSON.map.right)}
function prose(k,t,paras){return {theme:"paper",label:"Continue",html:'<div class="stack"><div class="sp"></div><div class="kicker">'+esc(k)+'</div><h1>'+esc(t)+'</h1>'+paras.join("")+'<div class="sp sm"></div></div>'}}
function illus(k,t,paras,art,cap){return {theme:"paper",label:"Continue",html:'<div class="stack"><div class="sp sm"></div><div class="panel">'+art+'</div><div class="caption">'+esc(cap)+'</div><div class="kicker">'+esc(k)+'</div><h1>'+esc(t)+'</h1>'+paras.join("")+'<div class="sp sm"></div></div>'}}
function cover(){return {theme:"cover",label:"Start",html:'<div class="cover"><div class="eyebrow">'+esc(LESSON.eyebrow)+'</div><div class="hero appear">'+heroGlyph()+'</div><div class="grow"></div><h1 class="appear">'+esc(LESSON.cover.a)+'<br><span class="amber">'+esc(LESSON.cover.b)+'</span><br>'+esc(LESSON.cover.c)+'</h1><div class="stand appear">'+esc(LESSON.cover.stand)+'</div><div class="grow"></div></div>',init(el){requestAnimationFrame(()=>el.querySelectorAll(".appear").forEach((a,i)=>setTimeout(()=>a.classList.add("in"),70+i*80)))}}}
function toggleStudio(){return {theme:"focus",label:"Continue",gated:true,html:'<div class="stack"><div class="sp sm"></div><div class="kicker">Try it</div><h1>'+esc(LESSON.toggle.title)+'</h1>'+P(esc(LESSON.toggle.intro))+'<div class="switches"><button class="sw on" id="off">'+esc(LESSON.toggle.off)+'</button><button class="sw" id="on">'+esc(LESSON.toggle.on)+'</button></div><div class="panel" id="toggleArt">'+flowArt(LESSON.map.left,LESSON.map.mid,LESSON.map.right)+'</div><div class="status"><span class="dot" id="td"></span><div class="t" id="tn">'+esc(LESSON.toggle.offNote)+'</div></div></div>',init(el,i){const off=el.querySelector("#off"),on=el.querySelector("#on"),d=el.querySelector("#td"),n=el.querySelector("#tn");function set(v){off.classList.toggle("on",!v);on.classList.toggle("on",v);d.classList.toggle("ok",v);n.textContent=v?LESSON.toggle.onNote:LESSON.toggle.offNote;if(v){explored.add(i);refresh();Aprecis.success()}else Aprecis.select()}off.onclick=()=>set(false);on.onclick=()=>set(true)}}}
function mechanismArt(){return '<svg viewBox="0 0 320 150" width="100%" height="150"><rect x="18" y="35" width="82" height="76" rx="16" fill="rgba(226,163,58,.12)" stroke="rgba(226,163,58,.45)"/><rect x="119" y="35" width="82" height="76" rx="16" fill="rgba(39,178,174,.12)" stroke="rgba(39,178,174,.55)"/><rect x="220" y="35" width="82" height="76" rx="16" fill="rgba(17,20,26,.04)" stroke="rgba(17,20,26,.18)"/><path d="M101 73 H118 M202 73 H219" stroke="#11141a" opacity=".25" stroke-width="4" stroke-linecap="round"/><text x="59" y="77" text-anchor="middle" fill="#b57814" font-size="11" font-weight="700">'+esc(LESSON.mechanism.lock)+'</text><text x="160" y="77" text-anchor="middle" fill="#168383" font-size="11" font-weight="700">'+esc(LESSON.mechanism.train)+'</text><text x="261" y="77" text-anchor="middle" fill="#6b7078" font-size="11" font-weight="700">'+esc(LESSON.mechanism.bridge)+'</text></svg>'}
function sliderStudio(){return {theme:"focus",label:"Continue",gated:true,html:'<div class="stack"><div class="sp sm"></div><div class="kicker">Try it</div><h1>'+esc(LESSON.slider.title)+'</h1>'+P(esc(LESSON.slider.intro))+'<input id="sl" type="range" min="0" max="100" value="0"><div class="bars"><div class="barrow"><div class="lab">'+esc(LESSON.slider.left)+'</div><div class="bar"><i id="leftbar"></i></div><div class="num" id="ln">100%</div></div><div class="barrow"><div class="lab">'+esc(LESSON.slider.right)+'</div><div class="bar"><i id="rightbar"></i></div><div class="num" id="rn">0%</div></div></div><div class="status"><span class="dot" id="sd"></span><div class="t" id="sn">'+esc(LESSON.slider.low)+'</div></div></div>',init(el,i){const sl=el.querySelector("#sl"),lb=el.querySelector("#leftbar"),rb=el.querySelector("#rightbar"),ln=el.querySelector("#ln"),rn=el.querySelector("#rn"),d=el.querySelector("#sd"),n=el.querySelector("#sn");function draw(){const v=Number(sl.value);lb.style.width=(100-v)+"%";rb.style.width=v+"%";ln.textContent=(100-v)+"%";rn.textContent=v+"%";n.textContent=v<34?LESSON.slider.low:v<67?LESSON.slider.mid:LESSON.slider.high;d.classList.toggle("ok",v>55);if(v>55){explored.add(i);refresh()}Aprecis.haptic("light")}sl.oninput=draw;draw()}}}
function chooserStudio(){return {theme:"focus",label:"Continue",gated:true,html:'<div class="stack"><div class="sp sm"></div><div class="kicker">Try it</div><h1>'+esc(LESSON.chooser.title)+'</h1>'+P(esc(LESSON.chooser.intro))+'<div class="choicegrid">'+LESSON.chooser.items.map((it,idx)=>'<button class="choice" data-i="'+idx+'"><b>'+esc(it[0])+'</b><span>'+esc(it[1])+'</span></button>').join("")+'</div><div class="status"><span class="dot" id="cd"></span><div class="t" id="ct">Pick at least three ingredients.</div></div></div>',init(el,i){const seen=new Set(),d=el.querySelector("#cd"),t=el.querySelector("#ct");el.querySelectorAll(".choice").forEach(btn=>btn.onclick=()=>{btn.classList.add("on");seen.add(btn.dataset.i);t.textContent=seen.size<3?seen.size+" selected. Keep going.":LESSON.chooser.done;d.classList.toggle("ok",seen.size>=3);if(seen.size>=3){explored.add(i);refresh();Aprecis.success()}else Aprecis.select()})}}}
function resultBars(){return '<div class="bars">'+LESSON.result.bars.map(b=>'<div class="barrow"><div class="lab">'+esc(b[0])+'</div><div class="bar"><i style="width:'+b[2]+'%"></i></div><div class="num">'+esc(b[1])+'</div></div>').join("")+'</div>'}
function recap(){return {theme:"paper",label:"Finish",html:'<div class="stack"><div class="sp"></div><div class="kicker">Recap</div><h1>'+esc(shortTitle())+', in four lines</h1><div class="twocol">'+LESSON.recap.map((r,i)=>'<div class="mini"><h2>'+(i+1)+' · '+esc(r[0])+'</h2><p>'+esc(r[1])+'</p></div>').join("")+'</div></div>'}}
function source(){return {theme:"paper",label:"Done",html:'<div class="stack"><div class="sp"></div><div class="quote">“</div><div class="pquote">'+esc(LESSON.quote)+'</div><div class="caption">'+esc(LESSON.authors)+' · '+LESSON.year+'</div><button class="src" id="src"><span><small>Original paper</small><b>'+esc(LESSON.title)+'</b></span></button></div>',init(el){el.querySelector("#src").onclick=()=>Aprecis.openOriginal("https://arxiv.org/abs/"+LESSON.arxivId)}}}
function shortTitle(){const names={vit:"ViT",ddpm:"DDPM",clip:"CLIP","stable-diffusion":"Stable Diffusion",sam:"SAM",t5:"T5",chinchilla:"Chinchilla",palm:"PaLM",llama:"LLaMA",mixtral:"Mixtral",reflexion:"Reflexion"};return names[LESSON.slug]||LESSON.slug.charAt(0).toUpperCase()+LESSON.slug.slice(1)}
const cards=[cover(),prose("Start here",LESSON.hook.title,[P(esc(LESSON.hook.p1)),P(esc(LESSON.hook.p2))]),illus("The map",LESSON.map.title,[P(esc(LESSON.map.p1)),P(esc(LESSON.map.p2))],flowArt(LESSON.map.left,LESSON.map.mid,LESSON.map.right),LESSON.map.caption),toggleStudio(),prose("One idea first",LESSON.mechanism.title,[P(esc(LESSON.mechanism.p1)),P(esc(LESSON.mechanism.p2))]),illus("The mechanism","Three pieces make the paper click",[P("The diagram is deliberately small: one input, one learned move, one output. The paper's trick is how those pieces are arranged.")],mechanismArt(),"Tap through the next cards to feel the tradeoff."),sliderStudio(),prose("Why it matters","The tradeoff is the invention",[P("The paper is not just a new name. It changes where information, compute, or supervision flows."),P("Once you see the tradeoff, the results become easier to remember.")]),chooserStudio(),illus("The result",LESSON.result.title,[P(esc(LESSON.result.p1)),P(esc(LESSON.result.p2))],resultBars(),LESSON.result.caption),prose("The payoff",LESSON.payoff.title,[P(esc(LESSON.payoff.p1)),P(esc(LESSON.payoff.p2))]),recap(),source()];
let idx=0;const explored=new Set();const stage=document.getElementById("stage"),rail=document.getElementById("rail"),bg=document.getElementById("bg"),count=document.getElementById("count"),next=document.getElementById("next"),hint=document.getElementById("hint");rail.innerHTML=cards.map(()=>'<span class="seg"></span>').join("");stage.innerHTML=cards.map((c,i)=>'<section class="card" data-i="'+i+'">'+c.html+'</section>').join("");
function refresh(){document.querySelectorAll(".seg").forEach((s,i)=>s.classList.toggle("on",i<=idx));document.querySelectorAll(".card").forEach((c,i)=>{c.classList.toggle("active",i===idx);c.classList.toggle("back",i<idx)});bg.className=cards[idx].theme;count.textContent=(idx+1)+"/"+cards.length;const gated=cards[idx].gated&&!explored.has(idx);next.disabled=gated;hint.textContent=gated?"Try the interaction to continue":"";next.textContent=idx===0?"Start":idx===cards.length-1?"Done":cards[idx].label||"Continue";if(cards[idx].init&&!cards[idx]._did){cards[idx]._did=true;cards[idx].init(stage.children[idx],idx)}}
function go(n){if(n<0||n>=cards.length)return;idx=n;refresh();Aprecis.select();if(idx===cards.length-1)Aprecis.markDone()}function previous(){go(idx-1)}function forward(){if(idx===cards.length-1){Aprecis.finish();return}if(!next.disabled)go(idx+1)}next.onclick=forward;document.getElementById("close").onclick=()=>Aprecis.close();let sx=0,sy=0,st=0;stage.addEventListener("touchstart",e=>{const t=e.touches[0];sx=t.clientX;sy=t.clientY;st=Date.now()},{passive:true});stage.addEventListener("touchend",e=>{const t=e.changedTouches[0],dx=t.clientX-sx,dy=t.clientY-sy;if(Math.abs(dx)>70&&Math.abs(dx)>Math.abs(dy)*1.4&&Date.now()-st<700){dx>0?previous():forward()}},{passive:true});refresh();
</script>
</body>
</html>`;
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[char]!));
}

function fail(message: string): never {
  console.error(message);
  Deno.exit(1);
}
