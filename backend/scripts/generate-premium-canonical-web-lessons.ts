/**
 * Generate and optionally publish a premium canonical web-lesson batch.
 *
 * Run from backend/:
 *   deno run --allow-net --allow-env --allow-read --allow-write scripts/generate-premium-canonical-web-lessons.ts
 *
 * Publish to Supabase Storage + paper_catalog:
 *   deno run --allow-net --allow-env --allow-read --allow-write scripts/generate-premium-canonical-web-lessons.ts --publish
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type CanonicalPaper = {
  slug: string;
  arxivId: string;
  topic: string;
  difficulty: "Beginner" | "Intermediate" | "Advanced";
  why: string;
};

type ArxivMeta = {
  title: string;
  abstract: string;
  authors: string[];
  year: number;
  published_at: string;
  url: string;
  arxiv_category?: string;
};

type LessonCard = {
  kind: "cover" | "story" | "map" | "compare" | "slider" | "chooser" | "results" | "recap" | "source";
  kicker: string;
  title: string;
  body: string[];
  caption?: string;
  left?: string;
  middle?: string;
  right?: string;
  offLabel?: string;
  onLabel?: string;
  offNote?: string;
  onNote?: string;
  low?: string;
  mid?: string;
  high?: string;
  lowLabel?: string;
  highLabel?: string;
  choices?: Array<{ label: string; note: string }>;
  bars?: Array<{ label: string; note: string; value: number }>;
  recap?: Array<{ label: string; note: string }>;
};

type PremiumLesson = {
  paper_id: string;
  short_name: string;
  title: string;
  authors: string;
  year: number;
  topic: string;
  difficulty: string;
  url: string;
  arxiv_id: string;
  hook: string;
  promise: string;
  prerequisite_note: string;
  glossary: Array<{ term: string; plain: string }>;
  related_slugs: string[];
  cards: LessonCard[];
};

type ManifestEntry = {
  paper_id: string;
  title: string;
  arxiv_id: string;
  topic: string;
  year: number;
  url: string;
  local_html: string;
  local_json: string;
  web_lesson_url?: string;
};

const ROOT = new URL("../../", import.meta.url).pathname.replace(/\/backend\/$/, "");
const CACHE_DIR = `${ROOT}/data/generated/canonical-50`;
const HTML_DIR = `${ROOT}/prototypes/web-lesson/canonical-50`;
const BUCKET = "web-lessons";
const MODEL = "gpt-4.1";
const BUDGET_USD = 100;
const INPUT_PER_M = 2.00;
const OUTPUT_PER_M = 8.00;

const PAPERS: CanonicalPaper[] = [
  { slug: "vae", arxivId: "1312.6114", topic: "Generative Models", difficulty: "Intermediate", why: "The reparameterization trick made neural generative modeling trainable end to end." },
  { slug: "dqn", arxivId: "1312.5602", topic: "Reinforcement Learning", difficulty: "Intermediate", why: "Deep Q-learning showed neural networks could learn useful policies from pixels." },
  { slug: "neural-turing-machines", arxivId: "1410.5401", topic: "Memory", difficulty: "Advanced", why: "It made differentiable external memory feel like a trainable computer." },
  { slug: "memory-networks", arxivId: "1410.3916", topic: "Memory", difficulty: "Intermediate", why: "It framed question answering as retrieving and reasoning over stored facts." },
  { slug: "bahdanau-attention", arxivId: "1409.0473", topic: "Language", difficulty: "Intermediate", why: "Attention let translation models look back at the right source words." },
  { slug: "batchnorm", arxivId: "1502.03167", topic: "Optimization", difficulty: "Intermediate", why: "Batch normalization made deep networks easier and faster to train." },
  { slug: "neural-style", arxivId: "1508.06576", topic: "Vision", difficulty: "Beginner", why: "It separated content and style in CNN features and made neural image editing tangible." },
  { slug: "pointer-networks", arxivId: "1506.03134", topic: "Architecture", difficulty: "Advanced", why: "Pointer networks let sequence models output positions instead of fixed vocabulary tokens." },
  { slug: "unet", arxivId: "1505.04597", topic: "Vision", difficulty: "Intermediate", why: "U-Net made precise image segmentation practical with skip connections and few labels." },
  { slug: "faster-rcnn", arxivId: "1506.01497", topic: "Vision", difficulty: "Intermediate", why: "Region proposal networks made object detection a single trainable system." },
  { slug: "yolo", arxivId: "1506.02640", topic: "Vision", difficulty: "Beginner", why: "YOLO turned object detection into one fast grid prediction pass." },
  { slug: "mask-rcnn", arxivId: "1703.06870", topic: "Vision", difficulty: "Intermediate", why: "Mask R-CNN added precise object masks to detection with a simple branch." },
  { slug: "alphazero", arxivId: "1712.01815", topic: "Reinforcement Learning", difficulty: "Advanced", why: "AlphaZero learned superhuman board play from self-play and search, without human games." },
  { slug: "elmo", arxivId: "1802.05365", topic: "Language", difficulty: "Intermediate", why: "ELMo made word meaning depend on surrounding context before Transformers took over." },
  { slug: "transformer-xl", arxivId: "1901.02860", topic: "Language", difficulty: "Advanced", why: "Transformer-XL introduced recurrence so attention could remember beyond a fixed window." },
  { slug: "xlnet", arxivId: "1906.08237", topic: "Language", difficulty: "Advanced", why: "XLNet tried to keep bidirectional context while avoiding BERT's masking mismatch." },
  { slug: "roberta", arxivId: "1907.11692", topic: "Language", difficulty: "Intermediate", why: "RoBERTa showed that BERT had been undertrained and that recipe details mattered." },
  { slug: "bart", arxivId: "1910.13461", topic: "Language", difficulty: "Intermediate", why: "BART unified denoising pretraining for generation and comprehension tasks." },
  { slug: "electra", arxivId: "2003.10555", topic: "Language", difficulty: "Intermediate", why: "ELECTRA trained by detecting replaced tokens, making pretraining far more sample-efficient." },
  { slug: "dpr", arxivId: "2004.04906", topic: "Retrieval", difficulty: "Intermediate", why: "Dense passage retrieval moved open-domain QA from keyword match to learned semantic search." },
  { slug: "rag", arxivId: "2005.11401", topic: "Retrieval", difficulty: "Intermediate", why: "RAG connected retrieval with generation so models could answer from external documents." },
  { slug: "gshard", arxivId: "2006.16668", topic: "Systems", difficulty: "Advanced", why: "GShard showed sparse expert models could scale multilingual translation dramatically." },
  { slug: "scaling-laws", arxivId: "2001.08361", topic: "Scaling", difficulty: "Intermediate", why: "Scaling laws made model performance feel predictable from compute, data, and size." },
  { slug: "nerf", arxivId: "2003.08934", topic: "Vision", difficulty: "Advanced", why: "NeRF represented 3D scenes inside a neural network and rendered new camera views." },
  { slug: "dall-e", arxivId: "2102.12092", topic: "Multimodal", difficulty: "Intermediate", why: "DALL-E showed text could steer image generation through discrete visual tokens." },
  { slug: "prefix-tuning", arxivId: "2101.00190", topic: "Adaptation", difficulty: "Intermediate", why: "Prefix-tuning adapted generation by learning small prompt-like vectors instead of full models." },
  { slug: "prompt-tuning", arxivId: "2104.08691", topic: "Adaptation", difficulty: "Intermediate", why: "Prompt tuning showed large frozen models could be steered with tiny learned prompts." },
  { slug: "lora", arxivId: "2106.09685", topic: "Adaptation", difficulty: "Intermediate", why: "LoRA made fine-tuning cheaper by learning low-rank updates instead of changing every weight." },
  { slug: "decision-transformer", arxivId: "2106.01345", topic: "Reinforcement Learning", difficulty: "Advanced", why: "It recast reinforcement learning as sequence modeling over desired returns and actions." },
  { slug: "glide", arxivId: "2112.10741", topic: "Diffusion", difficulty: "Intermediate", why: "GLIDE showed classifier-free guidance could make text-guided diffusion more faithful." },
  { slug: "retro", arxivId: "2112.04426", topic: "Retrieval", difficulty: "Advanced", why: "RETRO used retrieval during language modeling to trade stored text for parameters." },
  { slug: "webgpt", arxivId: "2112.09332", topic: "Agents", difficulty: "Intermediate", why: "WebGPT connected language models to browsing, citations, and human preference training." },
  { slug: "lamda", arxivId: "2201.08239", topic: "Dialogue", difficulty: "Intermediate", why: "LaMDA made open-ended dialogue quality, safety, and factuality explicit training targets." },
  { slug: "minerva", arxivId: "2206.14858", topic: "Reasoning", difficulty: "Advanced", why: "Minerva showed language models could solve math by training on technical text." },
  { slug: "gato", arxivId: "2205.06175", topic: "Agents", difficulty: "Intermediate", why: "Gato framed many control and language tasks as one generalist sequence problem." },
  { slug: "flamingo", arxivId: "2204.14198", topic: "Multimodal", difficulty: "Advanced", why: "Flamingo connected frozen vision and language models for few-shot multimodal learning." },
  { slug: "imagen", arxivId: "2205.11487", topic: "Diffusion", difficulty: "Intermediate", why: "Imagen showed very strong text encoders could drive photorealistic diffusion." },
  { slug: "dreambooth", arxivId: "2208.12242", topic: "Diffusion", difficulty: "Intermediate", why: "DreamBooth personalized text-to-image models from a handful of subject images." },
  { slug: "sparrow", arxivId: "2209.14375", topic: "Alignment", difficulty: "Intermediate", why: "Sparrow explored dialogue agents that follow rules and cite evidence." },
  { slug: "constitutional-ai", arxivId: "2212.08073", topic: "Alignment", difficulty: "Intermediate", why: "Constitutional AI used written principles to reduce reliance on human labels." },
  { slug: "instructpix2pix", arxivId: "2211.09800", topic: "Diffusion", difficulty: "Intermediate", why: "It turned image editing into following natural-language edit instructions." },
  { slug: "blip2", arxivId: "2301.12597", topic: "Multimodal", difficulty: "Intermediate", why: "BLIP-2 bridged frozen vision encoders and frozen LLMs with a lightweight query transformer." },
  { slug: "generative-agents", arxivId: "2304.03442", topic: "Agents", difficulty: "Beginner", why: "Generative Agents showed believable simulated people built from memory, reflection, and planning." },
  { slug: "qlora", arxivId: "2305.14314", topic: "Adaptation", difficulty: "Intermediate", why: "QLoRA made high-quality LLM fine-tuning possible on much smaller hardware." },
  { slug: "dpo", arxivId: "2305.18290", topic: "Alignment", difficulty: "Advanced", why: "DPO simplified preference optimization by removing the separate reward model." },
  { slug: "voyager", arxivId: "2305.16291", topic: "Agents", difficulty: "Intermediate", why: "Voyager showed an agent improving in Minecraft by writing and reusing skills." },
  { slug: "mamba", arxivId: "2312.00752", topic: "Architecture", difficulty: "Advanced", why: "Mamba made selective state spaces a serious alternative to attention for long sequences." },
  { slug: "sora-report", arxivId: "2402.17177", topic: "Video", difficulty: "Intermediate", why: "Video generation became a scaling story over spacetime patches and world simulation." },
  { slug: "llama-2", arxivId: "2307.09288", topic: "Language", difficulty: "Intermediate", why: "Llama 2 packaged open foundation and chat models with a detailed safety-tuning recipe." },
  { slug: "phi-2", arxivId: "2312.13103", topic: "Small Models", difficulty: "Intermediate", why: "Phi-2 argued that careful data could make small language models surprisingly capable." },
];

const TITLE_HINTS: Record<string, { title: string; year: number; authors?: string[] }> = {
  "2106.01345": { title: "Decision Transformer: Reinforcement Learning via Sequence Modeling", year: 2021 },
  "2112.10741": { title: "GLIDE: Towards Photorealistic Image Generation and Editing with Text-Guided Diffusion Models", year: 2021 },
  "2112.04426": { title: "Improving language models by retrieving from trillions of tokens", year: 2021 },
  "2112.09332": { title: "WebGPT: Browser-assisted question-answering with human feedback", year: 2021 },
  "2201.08239": { title: "LaMDA: Language Models for Dialog Applications", year: 2022 },
  "2206.14858": { title: "Solving Quantitative Reasoning Problems with Language Models", year: 2022 },
  "2205.06175": { title: "A Generalist Agent", year: 2022 },
  "2204.14198": { title: "Flamingo: a Visual Language Model for Few-Shot Learning", year: 2022 },
  "2205.11487": { title: "Photorealistic Text-to-Image Diffusion Models with Deep Language Understanding", year: 2022 },
  "2208.12242": { title: "DreamBooth: Fine Tuning Text-to-Image Diffusion Models for Subject-Driven Generation", year: 2022 },
  "2209.14375": { title: "Improving alignment of dialogue agents via targeted human judgements", year: 2022 },
  "2212.08073": { title: "Constitutional AI: Harmlessness from AI Feedback", year: 2022 },
  "2211.09800": { title: "InstructPix2Pix: Learning to Follow Image Editing Instructions", year: 2022 },
  "2301.12597": { title: "BLIP-2: Bootstrapping Language-Image Pre-training with Frozen Image Encoders and Large Language Models", year: 2023 },
  "2304.03442": { title: "Generative Agents: Interactive Simulacra of Human Behavior", year: 2023 },
  "2305.14314": { title: "QLoRA: Efficient Finetuning of Quantized LLMs", year: 2023 },
  "2305.18290": { title: "Direct Preference Optimization: Your Language Model is Secretly a Reward Model", year: 2023 },
  "2305.16291": { title: "Voyager: An Open-Ended Embodied Agent with Large Language Models", year: 2023 },
  "2312.00752": { title: "Mamba: Linear-Time Sequence Modeling with Selective State Spaces", year: 2023 },
  "2402.17177": { title: "Video generation models as world simulators", year: 2024 },
  "2307.09288": { title: "Llama 2: Open Foundation and Fine-Tuned Chat Models", year: 2023 },
  "2312.13103": { title: "Phi-2: The surprising power of small language models", year: 2023 },
};

const env = await load({ envPath: "./.env.local", export: true });
const OPENAI_API_KEY = env.OPENAI_API_KEY ?? Deno.env.get("OPENAI_API_KEY");
const SUPABASE_URL = env.SUPABASE_URL ?? Deno.env.get("SUPABASE_URL");
const SERVICE_KEY = env.SUPABASE_SERVICE_ROLE_KEY ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const publish = Deno.args.includes("--publish");
const force = Deno.args.includes("--force");
const metadataOnly = Deno.args.includes("--metadata-only");
const limitArg = Deno.args.find((arg) => arg.startsWith("--limit="));
const limit = limitArg ? Number(limitArg.split("=")[1]) : PAPERS.length;

if (!OPENAI_API_KEY && !metadataOnly) {
  console.error("Missing OPENAI_API_KEY");
  Deno.exit(1);
}
if (publish && (!SUPABASE_URL || !SERVICE_KEY)) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

await Deno.mkdir(CACHE_DIR, { recursive: true });
await Deno.mkdir(HTML_DIR, { recursive: true });

const manifest: ManifestEntry[] = [];
let estimatedCost = 0;
let generated = 0;
let reused = 0;
let published = 0;

const supabase = publish ? createClient(SUPABASE_URL!, SERVICE_KEY!) : null;
if (supabase) await ensureBucket(supabase);

for (let i = 0; i < Math.min(limit, PAPERS.length); i++) {
  const paper = PAPERS[i];
  const jsonPath = `${CACHE_DIR}/${paper.slug}.json`;
  const htmlPath = `${HTML_DIR}/${paper.slug}.html`;
  console.log(`\n[${i + 1}/${PAPERS.length}] ${paper.slug}`);

  const meta = await fetchArxivMeta(paper.arxivId);
  await delay(3100);

  let lesson: PremiumLesson | null = null;
  if (!force) lesson = await readJsonIfExists<PremiumLesson>(jsonPath);
  if (lesson) {
    reused++;
    console.log(`  reused ${jsonPath}`);
  } else {
    if (metadataOnly) continue;
    if (estimatedCost > BUDGET_USD * 0.92) {
      throw new Error(`Stopping before budget cap. Estimated spend is $${estimatedCost.toFixed(2)}.`);
    }
    lesson = await generateLesson(paper, meta);
    validateLesson(lesson);
    await Deno.writeTextFile(jsonPath, JSON.stringify(lesson, null, 2) + "\n");
    generated++;
    console.log(`  generated ${jsonPath}`);
  }

  const html = renderHtml(lesson);
  validateHtml(html, paper.slug);
  await Deno.writeTextFile(htmlPath, html);
  console.log(`  wrote ${htmlPath}`);

  let publicUrl: string | undefined;
  if (supabase) {
    publicUrl = await publishHtml(supabase, paper.slug, html, lesson);
    published++;
    console.log(`  published ${publicUrl}`);
  }

  manifest.push({
    paper_id: lesson.paper_id,
    title: lesson.title,
    arxiv_id: lesson.arxiv_id,
    topic: lesson.topic,
    year: lesson.year,
    url: lesson.url,
    local_html: htmlPath,
    local_json: jsonPath,
    web_lesson_url: publicUrl,
  });
  await Deno.writeTextFile(`${CACHE_DIR}/manifest.json`, JSON.stringify(manifest, null, 2) + "\n");
}

console.log("\nDone");
console.log(`generated=${generated} reused=${reused} published=${published}`);
console.log(`estimated_openai_cost=$${estimatedCost.toFixed(2)} budget=$${BUDGET_USD.toFixed(2)}`);
console.log(`manifest=${CACHE_DIR}/manifest.json`);

async function generateLesson(paper: CanonicalPaper, meta: ArxivMeta): Promise<PremiumLesson> {
  const prompt = lessonPrompt(paper, meta);
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: "system", content: systemPrompt() },
        { role: "user", content: prompt },
      ],
      response_format: { type: "json_object" },
      temperature: 0.55,
      max_tokens: 6500,
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message ?? `OpenAI error ${res.status}`);
  const usage = data.usage;
  if (usage) {
    const cost = ((usage.prompt_tokens ?? 0) / 1_000_000) * INPUT_PER_M +
      ((usage.completion_tokens ?? 0) / 1_000_000) * OUTPUT_PER_M;
    estimatedCost += cost;
    console.log(`  tokens in=${usage.prompt_tokens ?? 0} out=${usage.completion_tokens ?? 0} cost=$${cost.toFixed(4)} total=$${estimatedCost.toFixed(2)}`);
  }
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI returned no content");
  const lesson = JSON.parse(content) as PremiumLesson;
  lesson.paper_id = paper.slug;
  lesson.title = meta.title;
  lesson.year = meta.year;
  lesson.url = meta.url;
  lesson.arxiv_id = paper.arxivId;
  lesson.topic = paper.topic;
  lesson.difficulty = paper.difficulty;
  lesson.authors = meta.authors.slice(0, 4).join(", ") + (meta.authors.length > 4 ? " et al." : "");
  lesson.related_slugs = lesson.related_slugs?.filter((s) => s !== paper.slug).slice(0, 6) ?? [];
  return scrubDashesDeep(lesson);
}

function systemPrompt(): string {
  return `You are the senior curriculum designer for Aprecis, an app that teaches AI papers as premium, swipeable web lessons.

Write for a curious beginner, but do not flatten the actual idea. Build intuition first, then introduce terms.
Each paper needs a bespoke learning arc, not a generic summary.
Never use em dashes or en dashes anywhere. Use commas, colons, periods, parentheses, or the middle dot instead.
Return only valid JSON.`;
}

function lessonPrompt(paper: CanonicalPaper, meta: ArxivMeta): string {
  return `Create a premium Aprecis web lesson JSON for this canonical AI paper.

paper_id: ${paper.slug}
topic: ${paper.topic}
difficulty: ${paper.difficulty}
curator reason: ${paper.why}
title: ${meta.title}
authors: ${meta.authors.slice(0, 8).join(", ")}
year: ${meta.year}
arxiv_id: ${paper.arxivId}
abstract: ${meta.abstract}

Return this exact JSON shape:
{
  "paper_id": "${paper.slug}",
  "short_name": "2 to 4 word common name",
  "title": "${jsonEscape(meta.title)}",
  "authors": "short author string",
  "year": ${meta.year},
  "topic": "${paper.topic}",
  "difficulty": "${paper.difficulty}",
  "url": "${meta.url}",
  "arxiv_id": "${paper.arxivId}",
  "hook": "one vivid sentence, 9 to 15 words",
  "promise": "what the learner will understand by the end, one sentence",
  "prerequisite_note": "one sentence that names the needed intuition without requiring prior expertise",
  "glossary": [
    {"term": "specific term from the paper", "plain": "plain explanation"}
  ],
  "related_slugs": ["up to six readable slugs from related AI papers if obvious"],
  "cards": [
    {
      "kind": "cover",
      "kicker": "Aprecis · topic",
      "title": "short emotional title",
      "body": ["one sentence promise"]
    },
    {
      "kind": "story",
      "kicker": "Start here",
      "title": "beginner-friendly entry point",
      "body": ["paragraph 1", "paragraph 2"]
    },
    {
      "kind": "map",
      "kicker": "The map",
      "title": "how the mechanism flows",
      "body": ["paragraph 1", "paragraph 2"],
      "left": "first piece",
      "middle": "central move",
      "right": "outcome",
      "caption": "one sentence"
    },
    {
      "kind": "compare",
      "kicker": "Try it",
      "title": "interactive comparison title",
      "body": ["setup sentence"],
      "offLabel": "old way",
      "onLabel": "paper's way",
      "offNote": "what fails or costs more",
      "onNote": "what changes in the paper"
    },
    {
      "kind": "story",
      "kicker": "Core idea",
      "title": "the paper's central trick",
      "body": ["paragraph 1", "paragraph 2"]
    },
    {
      "kind": "slider",
      "kicker": "Feel the tradeoff",
      "title": "interactive slider title",
      "body": ["setup sentence"],
      "lowLabel": "left label",
      "highLabel": "right label",
      "low": "low setting explanation",
      "mid": "middle setting explanation",
      "high": "high setting explanation"
    },
    {
      "kind": "chooser",
      "kicker": "Build it",
      "title": "choose the ingredients",
      "body": ["one sentence"],
      "choices": [
        {"label": "ingredient", "note": "what it does"}
      ]
    },
    {
      "kind": "results",
      "kicker": "Why it mattered",
      "title": "result or impact title",
      "body": ["paragraph 1", "paragraph 2"],
      "bars": [
        {"label": "metric or comparison", "note": "short note", "value": 0 to 100}
      ],
      "caption": "one sentence"
    },
    {
      "kind": "story",
      "kicker": "Takeaway",
      "title": "why this paper belongs in the canon",
      "body": ["paragraph 1", "paragraph 2"]
    },
    {
      "kind": "recap",
      "kicker": "Recap",
      "title": "four-line mental model",
      "body": [],
      "recap": [
        {"label": "verb", "note": "short line"}
      ]
    },
    {
      "kind": "source",
      "kicker": "Original paper",
      "title": "paper title",
      "body": ["one closing sentence"]
    }
  ]
}

Rules:
- Exactly 11 cards in the order above.
- Body paragraphs should be 12 to 28 words each.
- The compare, slider, chooser, and results cards must feel specific to this paper.
- The chooser must have exactly 6 choices.
- The results card must have 3 to 5 bars with values from 10 to 100.
- The recap must have exactly 4 items.
- Glossary must have 4 to 7 terms.
- No markdown.
- No em dash or en dash characters.`;
}

async function fetchArxivMeta(arxivId: string): Promise<ArxivMeta> {
  const cachePath = `${CACHE_DIR}/${arxivId.replace("/", "_")}.arxiv.json`;
  const cached = await readJsonIfExists<ArxivMeta>(cachePath);
  if (cached) return cached;
  const immediateHint = TITLE_HINTS[arxivId];
  if (immediateHint) {
    const paper = PAPERS.find((p) => p.arxivId === arxivId);
    const fallback = {
      title: immediateHint.title,
      abstract: `${immediateHint.title}. ${paper?.why ?? "A canonical AI paper selected for the Aprecis learning map."}`,
      authors: immediateHint.authors ?? [],
      year: immediateHint.year,
      published_at: `${immediateHint.year}-01-01T00:00:00Z`,
      url: `https://arxiv.org/abs/${arxivId}`,
    };
    await Deno.writeTextFile(cachePath, JSON.stringify(fallback, null, 2) + "\n");
    return fallback;
  }
  let res: Response | null = null;
  for (let attempt = 0; attempt < 5; attempt++) {
    res = await fetch(`https://export.arxiv.org/api/query?id_list=${arxivId}&max_results=1`);
    if (res.ok) break;
    if (res.status !== 429 && res.status < 500) break;
    const waitMs = 5000 * (attempt + 1);
    console.warn(`  arXiv ${res.status} for ${arxivId}; waiting ${waitMs}ms`);
    await delay(waitMs);
  }
  if (!res) throw new Error(`arXiv request missing for ${arxivId}`);
  if (!res.ok) {
    const fallback = await fetchSemanticScholarMeta(arxivId);
    if (fallback) {
      await Deno.writeTextFile(cachePath, JSON.stringify(fallback, null, 2) + "\n");
      return fallback;
    }
    const hint = TITLE_HINTS[arxivId];
    if (hint) {
      console.warn(`  using curated metadata fallback for ${arxivId}`);
      const paper = PAPERS.find((p) => p.arxivId === arxivId);
      const fallback = {
        title: hint.title,
        abstract: `${hint.title}. ${paper?.why ?? "A canonical AI paper selected for the Aprecis learning map."}`,
        authors: hint.authors ?? [],
        year: hint.year,
        published_at: `${hint.year}-01-01T00:00:00Z`,
        url: `https://arxiv.org/abs/${arxivId}`,
      };
      await Deno.writeTextFile(cachePath, JSON.stringify(fallback, null, 2) + "\n");
      return fallback;
    }
    throw new Error(`arXiv ${res.status} for ${arxivId}`);
  }
  const xml = await res.text();
  const entry = xml.match(/<entry>([\s\S]*?)<\/entry>/)?.[1];
  if (!entry) throw new Error(`arXiv entry missing for ${arxivId}`);
  const tag = (t: string) =>
    decodeXml(entry.match(new RegExp(`<${t}[^>]*>([\\s\\S]*?)</${t}>`))?.[1] ?? "").replace(/\s+/g, " ").trim();
  const title = tag("title");
  const abstract = tag("summary");
  const published = entry.match(/<published>([\s\S]*?)<\/published>/)?.[1]?.trim() ?? new Date().toISOString();
  const authors = [...entry.matchAll(/<author>\s*<name>([\s\S]*?)<\/name>\s*<\/author>/g)]
    .map((m) => decodeXml(m[1].replace(/\s+/g, " ").trim()))
    .filter(Boolean);
  const category =
    entry.match(/<arxiv:primary_category[^>]*\bterm="([^"]+)"/)?.[1] ??
    entry.match(/<category[^>]*\bterm="([^"]+)"/)?.[1];
  if (!title || !abstract) throw new Error(`arXiv metadata incomplete for ${arxivId}`);
  const meta = {
    title,
    abstract,
    authors,
    year: Number(published.slice(0, 4)),
    published_at: published,
    url: `https://arxiv.org/abs/${arxivId}`,
    arxiv_category: category,
  };
  await Deno.writeTextFile(cachePath, JSON.stringify(meta, null, 2) + "\n");
  return meta;
}

async function fetchSemanticScholarMeta(arxivId: string): Promise<ArxivMeta | null> {
  console.warn(`  trying Semantic Scholar fallback for ${arxivId}`);
  const fields = "title,abstract,authors,year,url,publicationDate";
  const res = await fetch(`https://api.semanticscholar.org/graph/v1/paper/arXiv:${arxivId}?fields=${fields}`);
  if (!res.ok) {
    console.warn(`  Semantic Scholar ${res.status} for ${arxivId}`);
    return null;
  }
  const data = await res.json();
  if (!data.title) return null;
  const year = Number(data.year ?? data.publicationDate?.slice(0, 4) ?? new Date().getFullYear());
  return {
    title: data.title,
    abstract: data.abstract ?? `Canonical AI paper: ${data.title}. ${PAPERS.find((p) => p.arxivId === arxivId)?.why ?? ""}`,
    authors: Array.isArray(data.authors) ? data.authors.map((a: { name?: string }) => a.name).filter(Boolean) : [],
    year,
    published_at: data.publicationDate ? `${data.publicationDate}T00:00:00Z` : `${year}-01-01T00:00:00Z`,
    url: `https://arxiv.org/abs/${arxivId}`,
  };
}

type SupabaseScriptClient = ReturnType<typeof createClient<any, "public", any>>;

async function ensureBucket(supabase: SupabaseScriptClient) {
  const { data: buckets, error } = await supabase.storage.listBuckets();
  if (error) throw error;
  if (buckets?.some((b) => b.name === BUCKET)) return;
  const { error: createError } = await supabase.storage.createBucket(BUCKET, {
    public: true,
    fileSizeLimit: "10MB",
  });
  if (createError) throw createError;
}

async function publishHtml(
  supabase: SupabaseScriptClient,
  slug: string,
  html: string,
  lesson: PremiumLesson,
): Promise<string> {
  const objectPath = `${slug}/index.html`;
  const { error: uploadError } = await supabase.storage.from(BUCKET).upload(
    objectPath,
    new TextEncoder().encode(html),
    { contentType: "text/html; charset=utf-8", upsert: true },
  );
  if (uploadError) throw uploadError;
  const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${objectPath}?v=${Date.now()}`;
  const { error: catalogError } = await supabase.from("paper_catalog").upsert({
    paper_id: lesson.paper_id,
    canonical_key: `arxiv:${lesson.arxiv_id}`,
    title: lesson.title,
    source: "curated",
    origin: "curated",
    topic: lesson.topic,
    url: lesson.url,
    arxiv_id: lesson.arxiv_id,
    year: lesson.year,
    published_at: `${lesson.year}-01-01T00:00:00Z`,
    web_lesson_url: publicUrl,
    updated_at: new Date().toISOString(),
  }, { onConflict: "paper_id" });
  if (catalogError) throw catalogError;
  return publicUrl;
}

function renderHtml(lesson: PremiumLesson): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<title>${escapeHtml(lesson.title)}</title>
<style>
:root{--paper:#f7f4ef;--ink:#11141a;--muted:#69717c;--teal:#138481;--aqua:#31b7ae;--amber:#d99a28;--rose:#b75555;--line:rgba(17,20,26,.13);--serif:ui-serif,"New York",Georgia,"Times New Roman",serif;--sans:-apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;--mono:ui-monospace,SFMono-Regular,Menlo,monospace}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}html,body{margin:0;height:100%;min-height:100dvh}body{max-width:430px;margin:0 auto;background:var(--paper);color:var(--ink);font-family:var(--sans);overflow:hidden;-webkit-font-smoothing:antialiased;display:flex;flex-direction:column}.bg{position:fixed;inset:0;z-index:-1;background:var(--paper);transition:background .3s}.bg.cover{background:radial-gradient(circle at 50% 26%,rgba(49,183,174,.28),transparent 58%),#10131a}.bg.focus{background:linear-gradient(to bottom,rgba(49,183,174,.14),rgba(247,244,239,0) 52%),var(--paper)}
.chrome{display:flex;align-items:center;gap:10px;padding:calc(8px + env(safe-area-inset-top,0px)) 18px 13px}.x{width:30px;height:30px;border:0;background:none;color:var(--ink);opacity:.72;font:700 15px var(--sans)}.rail{flex:1;display:flex;gap:4px}.seg{height:3px;flex:1;border-radius:3px;background:rgba(17,20,26,.15)}.seg.on{background:rgba(17,20,26,.86)}.count{width:40px;text-align:right;font:700 11px var(--mono);color:var(--muted)}
.stage{position:relative;flex:1;min-height:0;overflow:hidden}.card{position:absolute;inset:0;overflow-y:auto;-webkit-overflow-scrolling:touch;padding:0 22px 24px;opacity:0;transform:translateX(18px);pointer-events:none;transition:opacity .28s,transform .28s}.card.active{opacity:1;transform:none;pointer-events:auto}.card.back{transform:translateX(-18px)}.advance{padding:9px 22px calc(24px + env(safe-area-inset-bottom,0px));display:flex;flex-direction:column;gap:8px;flex:none}.hint{min-height:16px;text-align:center;font:italic 12px var(--serif);color:var(--muted)}.next{min-height:50px;border:0;border-radius:14px;background:var(--teal);color:white;font:750 15px var(--sans)}.next:disabled{background:rgba(17,20,26,.12);color:var(--muted)}
.stack{display:flex;flex-direction:column;gap:16px;align-items:flex-start}.sp{height:18px}.sp.big{height:42px}.kicker{font:800 11px var(--sans);letter-spacing:2px;text-transform:uppercase;color:var(--teal)}h1{margin:0;font:600 29px/1.14 var(--serif);letter-spacing:0;color:var(--ink)}.prose{margin:0;font:16px/1.52 var(--serif);color:rgba(17,20,26,.82)}.panel{width:100%;border:1px solid var(--line);background:white;border-radius:16px;padding:14px}.caption{font:italic 12px/1.35 var(--serif);color:var(--muted)}.cover{min-height:100%;display:flex;flex-direction:column;text-align:center;align-items:center}.cover .eyebrow{padding-top:18px;color:var(--aqua);font:800 11px var(--sans);letter-spacing:2.3px;text-transform:uppercase}.cover h1{font-size:38px;line-height:1.05;color:#f4f1ea}.cover .amber{color:var(--amber)}.cover .stand{font:italic 15px/1.5 var(--serif);color:rgba(244,241,234,.66);padding:14px 8px 0}.grow{flex:1;min-height:16px}
.switches{display:grid;grid-template-columns:1fr 1fr;gap:8px;width:100%}.sw{border:1px solid var(--line);border-radius:12px;background:white;padding:12px 8px;font:800 10px var(--sans);letter-spacing:1px;text-transform:uppercase;color:var(--muted)}.sw.on{background:var(--teal);border-color:var(--teal);color:white}.status{display:flex;gap:9px;align-items:flex-start}.dot{width:9px;height:9px;border-radius:50%;background:var(--amber);margin-top:5px;flex:none}.dot.ok{background:var(--teal)}.status .t{font:600 13px/1.4 var(--serif);color:rgba(17,20,26,.8)}
.bars{width:100%;display:flex;flex-direction:column;gap:12px}.barrow{display:grid;grid-template-columns:86px 1fr 50px;gap:10px;align-items:center}.lab{font:700 10px/1.2 var(--mono);color:var(--muted)}.bar{height:16px;border-radius:999px;background:rgba(105,113,124,.14);overflow:hidden}.bar i{display:block;height:100%;width:0;background:var(--teal);border-radius:999px;transition:width .35s}.num{text-align:right;font:700 10px var(--mono)}
input[type=range]{-webkit-appearance:none;appearance:none;width:100%;height:3px;border-radius:2px;background:rgba(19,132,129,.25);outline:none}input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:24px;height:24px;border-radius:50%;background:var(--teal);box-shadow:0 1px 4px rgba(0,0,0,.2)}.choicegrid{display:grid;grid-template-columns:1fr 1fr;gap:8px;width:100%}.choice{border:1px solid var(--line);background:white;border-radius:14px;padding:12px;text-align:left}.choice b{display:block;font:700 13px var(--sans);margin-bottom:4px}.choice span{font:13px/1.35 var(--serif);color:var(--muted)}.choice.on{border-color:var(--teal);background:rgba(19,132,129,.08)}.twocol{display:grid;grid-template-columns:1fr 1fr;gap:10px;width:100%}.mini{border:1px solid var(--line);border-radius:14px;background:white;padding:12px}.mini h2{margin:0 0 8px;font:800 10px var(--sans);letter-spacing:1.3px;text-transform:uppercase;color:var(--muted)}.mini p{margin:0;font:14px/1.35 var(--serif)}.src{width:100%;display:flex;gap:10px;align-items:center;text-align:left;border:1px solid rgba(19,132,129,.35);background:white;border-radius:14px;padding:14px}.src small{display:block;color:var(--teal);font:800 9px var(--sans);letter-spacing:1.5px;text-transform:uppercase}.src b{font:600 14px var(--serif)}.quote{font:italic 22px/1.45 var(--serif)}
</style>
</head>
<body>
<div class="bg cover" id="bg"></div>
<div class="chrome"><button class="x" id="close" aria-label="Close">x</button><div class="rail" id="rail"></div><div class="count" id="count"></div></div>
<div class="stage" id="stage"></div>
<div class="advance"><div class="hint" id="hint"></div><button class="next" id="next">Start</button></div>
<script type="application/json" id="lesson-data">${escapeScriptJson(JSON.stringify(lesson))}</script>
<script>
const LESSON=JSON.parse(document.getElementById("lesson-data").textContent);
const Aprecis={_s(n,b){const h=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers[n];h?h.postMessage(b||{}):console.log("[Aprecis]",n,b||"")},haptic(s){this._s("haptic",{style:s||"soft"})},select(){this.haptic("select")},success(){this.haptic("success")},markDone(){this._s("markDone")},finish(){this._s("finish")},close(){this._s("close")},openOriginal(u){this._s("openOriginal",{url:u})}};
function esc(s){return String(s||"").replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]))}
function P(s){return '<p class="prose">'+esc(s)+'</p>'}
function flow(a,b,c){return '<svg viewBox="0 0 320 170" width="100%" height="170" role="img"><rect x="12" y="22" width="296" height="126" rx="18" fill="#10131a"/><circle cx="74" cy="85" r="31" fill="rgba(217,154,40,.16)" stroke="rgba(217,154,40,.72)"/><circle cx="160" cy="85" r="31" fill="rgba(49,183,174,.16)" stroke="rgba(49,183,174,.72)"/><circle cx="246" cy="85" r="31" fill="rgba(244,241,234,.08)" stroke="rgba(244,241,234,.42)"/><path d="M108 85 H126 M194 85 H212" stroke="rgba(244,241,234,.55)" stroke-width="4" stroke-linecap="round"/><text x="74" y="89" text-anchor="middle" fill="#d99a28" font-size="11" font-family="ui-monospace,Menlo,monospace">'+esc(a)+'</text><text x="160" y="89" text-anchor="middle" fill="#31b7ae" font-size="11" font-family="ui-monospace,Menlo,monospace">'+esc(b)+'</text><text x="246" y="89" text-anchor="middle" fill="rgba(244,241,234,.78)" font-size="11" font-family="ui-monospace,Menlo,monospace">'+esc(c)+'</text></svg>'}
function bars(items){return '<div class="bars">'+(items||[]).map(b=>'<div class="barrow"><div class="lab">'+esc(b.label)+'</div><div class="bar"><i style="width:'+Math.max(0,Math.min(100,b.value||0))+'%"></i></div><div class="num">'+esc(b.note)+'</div></div>').join("")+'</div>'}
function cardHtml(c){const body=(c.body||[]).map(P).join("");if(c.kind==="cover")return '<div class="cover"><div class="eyebrow">'+esc(c.kicker)+'</div><div class="grow"></div><h1>'+esc(c.title).replace(/: /,"<br><span class=\\"amber\\">")+'</span></h1><div class="stand">'+esc((c.body||[])[0]||LESSON.promise)+'</div><div class="grow"></div></div>';if(c.kind==="map")return '<div class="stack"><div class="sp"></div><div class="panel">'+flow(c.left,c.middle,c.right)+'</div><div class="caption">'+esc(c.caption)+'</div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1>'+body+'</div>';if(c.kind==="compare")return '<div class="stack"><div class="sp"></div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1>'+body+'<div class="switches"><button class="sw on" id="off">'+esc(c.offLabel)+'</button><button class="sw" id="on">'+esc(c.onLabel)+'</button></div><div class="status"><span class="dot" id="td"></span><div class="t" id="tn">'+esc(c.offNote)+'</div></div></div>';if(c.kind==="slider")return '<div class="stack"><div class="sp"></div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1>'+body+'<input id="sl" type="range" min="0" max="100" value="0"><div class="bars"><div class="barrow"><div class="lab">'+esc(c.lowLabel)+'</div><div class="bar"><i id="lb"></i></div><div class="num" id="ln">100%</div></div><div class="barrow"><div class="lab">'+esc(c.highLabel)+'</div><div class="bar"><i id="rb"></i></div><div class="num" id="rn">0%</div></div></div><div class="status"><span class="dot" id="sd"></span><div class="t" id="sn">'+esc(c.low)+'</div></div></div>';if(c.kind==="chooser")return '<div class="stack"><div class="sp"></div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1>'+body+'<div class="choicegrid">'+(c.choices||[]).map((x,i)=>'<button class="choice" data-i="'+i+'"><b>'+esc(x.label)+'</b><span>'+esc(x.note)+'</span></button>').join("")+'</div><div class="status"><span class="dot" id="cd"></span><div class="t" id="ct">Pick at least three ingredients.</div></div></div>';if(c.kind==="results")return '<div class="stack"><div class="sp"></div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1>'+body+'<div class="panel">'+bars(c.bars)+'</div><div class="caption">'+esc(c.caption)+'</div></div>';if(c.kind==="recap")return '<div class="stack"><div class="sp"></div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1><div class="twocol">'+(c.recap||[]).map((r,i)=>'<div class="mini"><h2>'+(i+1)+' · '+esc(r.label)+'</h2><p>'+esc(r.note)+'</p></div>').join("")+'</div></div>';if(c.kind==="source")return '<div class="stack"><div class="sp big"></div><div class="kicker">'+esc(c.kicker)+'</div><div class="quote">'+esc((c.body||[])[0]||LESSON.hook)+'</div><div class="caption">'+esc(LESSON.authors)+' · '+LESSON.year+'</div><button class="src" id="src"><span><small>Original paper</small><b>'+esc(LESSON.title)+'</b></span></button></div>';return '<div class="stack"><div class="sp"></div><div class="kicker">'+esc(c.kicker)+'</div><h1>'+esc(c.title)+'</h1>'+body+'</div>'}
const cards=LESSON.cards;const explored=new Set();let idx=0;const stage=document.getElementById("stage"),rail=document.getElementById("rail"),bg=document.getElementById("bg"),count=document.getElementById("count"),next=document.getElementById("next"),hint=document.getElementById("hint");rail.innerHTML=cards.map(()=>'<span class="seg"></span>').join("");stage.innerHTML=cards.map(cardHtml).map((h,i)=>'<section class="card" data-i="'+i+'">'+h+'</section>').join("");
function initCard(i){const el=stage.children[i],c=cards[i];if(c._did)return;c._did=true;if(c.kind==="compare"){const off=el.querySelector("#off"),on=el.querySelector("#on"),d=el.querySelector("#td"),n=el.querySelector("#tn");function set(v){off.classList.toggle("on",!v);on.classList.toggle("on",v);d.classList.toggle("ok",v);n.textContent=v?c.onNote:c.offNote;if(v){explored.add(i);refresh();Aprecis.success()}else Aprecis.select()}off.onclick=()=>set(false);on.onclick=()=>set(true)}if(c.kind==="slider"){const sl=el.querySelector("#sl"),lb=el.querySelector("#lb"),rb=el.querySelector("#rb"),ln=el.querySelector("#ln"),rn=el.querySelector("#rn"),d=el.querySelector("#sd"),n=el.querySelector("#sn");function draw(){const v=Number(sl.value);lb.style.width=(100-v)+"%";rb.style.width=v+"%";ln.textContent=(100-v)+"%";rn.textContent=v+"%";n.textContent=v<34?c.low:v<67?c.mid:c.high;d.classList.toggle("ok",v>55);if(v>55){explored.add(i);refresh()}Aprecis.haptic("light")}sl.oninput=draw;draw()}if(c.kind==="chooser"){const seen=new Set(),d=el.querySelector("#cd"),t=el.querySelector("#ct");el.querySelectorAll(".choice").forEach(btn=>btn.onclick=()=>{btn.classList.add("on");seen.add(btn.dataset.i);t.textContent=seen.size<3?seen.size+" selected. Keep going.":"That is the working recipe.";d.classList.toggle("ok",seen.size>=3);if(seen.size>=3){explored.add(i);refresh();Aprecis.success()}else Aprecis.select()})}if(c.kind==="source"){el.querySelector("#src").onclick=()=>Aprecis.openOriginal(LESSON.url)}}
function refresh(){document.querySelectorAll(".seg").forEach((s,i)=>s.classList.toggle("on",i<=idx));document.querySelectorAll(".card").forEach((c,i)=>{c.classList.toggle("active",i===idx);c.classList.toggle("back",i<idx)});bg.className="bg "+(idx===0?"cover":["compare","slider","chooser"].includes(cards[idx].kind)?"focus":"paper");count.textContent=(idx+1)+"/"+cards.length;const gated=["compare","slider","chooser"].includes(cards[idx].kind)&&!explored.has(idx);next.disabled=gated;hint.textContent=gated?"Try the interaction to continue":"";next.textContent=idx===0?"Start":idx===cards.length-1?"Done":"Continue";initCard(idx)}
function go(n){if(n<0||n>=cards.length)return;idx=n;refresh();Aprecis.select();if(idx===cards.length-1)Aprecis.markDone()}function forward(){if(idx===cards.length-1){Aprecis.finish();return}if(!next.disabled)go(idx+1)}next.onclick=forward;document.getElementById("close").onclick=()=>Aprecis.close();let sx=0,sy=0,st=0;stage.addEventListener("touchstart",e=>{const t=e.touches[0];sx=t.clientX;sy=t.clientY;st=Date.now()},{passive:true});stage.addEventListener("touchend",e=>{const t=e.changedTouches[0],dx=t.clientX-sx,dy=t.clientY-sy;if(Math.abs(dx)>70&&Math.abs(dx)>Math.abs(dy)*1.4&&Date.now()-st<700){dx>0?go(idx-1):forward()}},{passive:true});refresh();
</script>
</body>
</html>`;
}

function validateLesson(lesson: PremiumLesson) {
  if (!lesson.paper_id || !lesson.title || !Array.isArray(lesson.cards)) throw new Error("Lesson missing required fields");
  if (lesson.cards.length !== 11) throw new Error(`${lesson.paper_id} has ${lesson.cards.length} cards, expected 11`);
  const kinds = lesson.cards.map((c) => c.kind).join(",");
  const expected = "cover,story,map,compare,story,slider,chooser,results,story,recap,source";
  if (kinds !== expected) throw new Error(`${lesson.paper_id} card order ${kinds}`);
  const chooser = lesson.cards.find((c) => c.kind === "chooser");
  if (chooser?.choices?.length !== 6) throw new Error(`${lesson.paper_id} chooser must have 6 choices`);
  const recap = lesson.cards.find((c) => c.kind === "recap");
  if (recap?.recap?.length !== 4) throw new Error(`${lesson.paper_id} recap must have 4 items`);
  const text = JSON.stringify(lesson);
  if (/—|–|\\u2014|\\u2013/i.test(text)) throw new Error(`${lesson.paper_id} contains forbidden dash`);
}

function validateHtml(html: string, slug: string) {
  if (/—|–|\\u2014|\\u2013/i.test(html)) throw new Error(`${slug} html contains forbidden dash`);
  if (!html.includes("id=\"lesson-data\"")) throw new Error(`${slug} html missing lesson data`);
}

async function readJsonIfExists<T>(path: string): Promise<T | null> {
  try {
    return JSON.parse(await Deno.readTextFile(path)) as T;
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) return null;
    throw err;
  }
}

function scrubDashesDeep<T>(value: T): T {
  if (typeof value === "string") {
    return value.replace(/\s*[—–]\s*/g, ", ").replace(/,\s*,/g, ",") as T;
  }
  if (Array.isArray(value)) return value.map(scrubDashesDeep) as T;
  if (value && typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [key, child] of Object.entries(value)) out[key] = scrubDashesDeep(child);
    return out as T;
  }
  return value;
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;" }[c]!));
}

function escapeScriptJson(s: string): string {
  return s.replace(/</g, "\\u003c").replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
}

function jsonEscape(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
}

function decodeXml(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, "\"")
    .replace(/&#39;/g, "'");
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
