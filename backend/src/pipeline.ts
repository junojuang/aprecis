/**
 * Multi-stage LLM pipeline: paper text → concept feed
 *
 * Stage 1 (gpt-4o-mini): Extract summary + 4 concepts.
 *
 * Stage 2 (gpt-4o, 4× parallel): For each concept, generate a complete
 *   self-contained interactive HTML visualization, creative, paper-specific,
 *   chosen and designed by the model itself. No fixed templates or schemas.
 */

import type {
  CardDeck,
  Concept,
  DiagramSpec,
  DailyLoopBlueprint,
  CoreFinding,
  TimelineNode,
  HighlightedText,
  VizCard,
  BarVizSpec,
  ScatterVizSpec,
} from "./types.ts";

interface RawConcept {
  title: string;
  body: string;
}

interface AIClient {
  chat: (messages: ChatMessage[], opts?: ChatOptions) => Promise<string>;
}

// ─── Dash scrubber ────────────────────────────────────────────────────────────
// Explanations must never contain em (—) or en (–) dashes. Even with prompt
// rules, models occasionally slip. Post-process every prose field.

function stripProseDashes(s: string): string {
  return s
    .replace(/\s*—\s*/g, ", ")
    .replace(/(\d)\s*–\s*(\d)/g, "$1 to $2")
    .replace(/\s*–\s*/g, ", ")
    .replace(/,\s*,/g, ",")
    .replace(/,\s*\./g, ".")
    .replace(/\s+,/g, ",");
}

function stripDashesDeep<T>(v: T): T {
  if (typeof v === "string") return stripProseDashes(v) as unknown as T;
  if (Array.isArray(v)) return v.map(stripDashesDeep) as unknown as T;
  if (v && typeof v === "object") {
    const out: Record<string, unknown> = {};
    for (const k of Object.keys(v as object)) {
      out[k] = stripDashesDeep((v as Record<string, unknown>)[k]);
    }
    return out as unknown as T;
  }
  return v;
}
interface ChatMessage { role: "system" | "user" | "assistant"; content: string; }
interface ChatOptions {
  model?: string;
  max_tokens?: number;
  temperature?: number;
  response_format?: { type: "json_object" };
}

// ─── Anthropic Client (summary + HTML viz) ────────────────────────────────────

export function createAnthropicClient(apiKey: string): AIClient {
  async function chat(messages: ChatMessage[], opts: ChatOptions = {}): Promise<string> {
    // Split system message out (Anthropic API uses a separate top-level field)
    const system = messages.find(m => m.role === "system")?.content;
    const userMessages = messages.filter(m => m.role !== "system");

    const model = opts.model ?? "claude-haiku-4-5-20251001";
    // Opus 4.7+ rejects the `temperature` parameter ("deprecated for this
    // model"). Send it only for models that still accept it.
    const acceptsTemperature = !/opus-4-([7-9]|\d\d)/.test(model);

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        max_tokens: opts.max_tokens ?? 800,
        ...(acceptsTemperature ? { temperature: opts.temperature ?? 0.3 } : {}),
        ...(system ? { system } : {}),
        messages: userMessages,
      }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error?.message ?? `Anthropic error ${res.status}`);
    return data.content[0].text;
  }

  return { chat };
}

// ─── Legacy OpenAI Client (kept for chat fallback only) ───────────────────────

export function createOpenAIClient(apiKey: string): AIClient {
  // Map Anthropic-style model hints from upstream callers onto OpenAI models.
  // Cheap/structured stages → gpt-4o-mini. Creative HTML viz (Sonnet) → gpt-4o.
  function mapModel(requested?: string): string {
    if (!requested) return "gpt-4o-mini";
    if (requested.startsWith("gpt-")) return requested;
    if (requested.includes("sonnet") || requested.includes("opus")) return "gpt-4o";
    return "gpt-4o-mini";
  }

  return {
    async chat(messages, opts = {}) {
      const res = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: mapModel(opts.model),
          messages,
          max_tokens: opts.max_tokens ?? 800,
          temperature: opts.temperature ?? 0.3,
          ...(opts.response_format ? { response_format: opts.response_format } : {}),
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error?.message ?? "OpenAI error");
      return data.choices[0].message.content;
    },
  };
}

// ─── Stage 1: Summary + Concepts ─────────────────────────────────────────────

async function stageSummarise(
  ai: AIClient,
  title: string,
  abstract: string
): Promise<{ hook: string; summary: string; concepts: RawConcept[] }> {
  const prompt = `You are distilling an AI research paper for a curious non-expert audience.

Paper title: ${title}
Abstract: ${abstract}

Return JSON:
{
  "hook": "<10-14 words. A punchy present-tense statement that makes someone stop scrolling. Reveals the surprising insight or problem. Never starts with 'This paper'. E.g. 'Your AI only reacts to failure, it never thinks ahead.' or 'Language models trained on human feedback still lie when it benefits them.'>",
  "summary": "<40-55 words. Plain English. What problem? How solved? What's the result? No jargon.>",
  "concepts": [
    {
      "title": "<2-4 word name specific to this paper, e.g. 'Rubric-Based Scoring', not 'Method'>",
      "body": "<2-3 sentences describing the SPECIFIC mechanism: what it does, why novel, exact terms the paper uses.>"
    }
  ]
}

Rules:
- Exactly 4 concepts covering: (1) problem/motivation, (2) core mechanism, (3) training/optimization, (4) results/impact
- Titles must be paper-specific, never generic
- No markdown, no bullet points inside body
- NEVER use em dashes (—) or en dashes (–) anywhere. Use commas, colons, semicolons, periods, or parentheses instead. This applies to hook, summary, concept titles, and concept bodies.`;

  // Haiku: fast + cheap for structured JSON extraction
  const raw = await ai.chat(
    [{ role: "user", content: prompt }],
    { model: "claude-haiku-4-5-20251001", max_tokens: 800 }
  );
  // Claude returns clean JSON without needing response_format enforcement
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error("No JSON in Stage 1 response");
  const parsed = JSON.parse(jsonMatch[0]) as { hook: string; summary: string; concepts: RawConcept[] };
  return stripDashesDeep(parsed);
}

// ─── Stage 2a: Structured DiagramSpec (Haiku, cheap + fast) ─────────────────

const DIAGRAM_SPEC_SYSTEM = `You classify AI research concepts into diagram types for a mobile learning app. Return only valid JSON.`;

const DIAGRAM_SPEC_PROMPT = `Available diagram types:

flow: sequential pipeline steps
{ "type": "flow", "caption": "...", "nodes": [{"id":"1","label":"Name","sublabel":"detail","color":"#hex"}], "edges": [{"from":"1","to":"2","label":"optional"}] }

bar_chart: comparative metrics with real numbers
{ "type": "bar_chart", "caption": "...", "bars": [{"label":"Model A","value":87.3,"color":"#hex","note":"★ SOTA"}], "yLabel": "Accuracy (%)" }

comparison: before/after or method vs method table
{ "type": "comparison", "caption": "...", "leftLabel": "Old", "rightLabel": "New", "items": [{"aspect":"Training time","before":"3 days","after":"3.5 hrs"}] }

attention_heatmap: token×token attention (only for attention mechanism concepts)
{ "type": "attention_heatmap", "caption": "...", "tokens": ["The","cat","sat"], "weights": [[0.8,0.1,0.1],[0.2,0.6,0.2],[0.1,0.3,0.6]] }

multi_head: parallel attention heads (only for multi-head attention concepts)
{ "type": "multi_head", "caption": "...", "tokens": ["The","cat","sat"], "heads": [{"name":"Syntax","color":"#1a8a8a","weights":[0.8,0.1,0.1],"desc":"subject-verb links"}] }

sine_waves: frequency/positional encoding concepts (no data needed)
{ "type": "sine_waves", "caption": "..." }

cycle: iterative/looping process with 3 to 6 numbered steps that repeat
{ "type": "cycle", "caption": "...", "steps": [{"label":"Sample noise","sublabel":"ε ~ N(0,1)"}] }

number_box: ONE dramatic headline statistic (use when a single number is the point)
{ "type": "number_box", "caption": "...", "value": "1000×", "valueLabel": "fewer trainable params", "valueSublabel": "vs full fine-tuning" }

equation: a formula with labelled terms (use for loss functions, attention formula, update rules)
{ "type": "equation", "caption": "...", "formula": "Attention(Q,K,V) = softmax(QK^T/√d)V", "terms": [{"symbol":"Q","meaning":"query matrix"},{"symbol":"K","meaning":"key matrix"}] }

custom: concept requires unique creative visualization not covered above
{ "type": "custom" }

Rules:
- Use REAL numbers, model names, and terms from the explanation. Never use "Input", "Output", "Step 1".
- STRONGLY prefer flow, comparison, bar_chart, cycle, number_box, or equation; almost every concept maps to one. "custom" should be chosen less than 5% of the time.
- NEVER use em dashes (—) or en dashes (–) inside any string field (caption, label, sublabel, annotation, note, etc). Use commas, colons, semicolons, periods, or parentheses instead.
- If the concept describes a problem/failure mode → use comparison (old-broken-approach vs new-fix).
- If the concept describes a one-pass mechanism/process → use flow.
- If the concept describes a process that REPEATS / iterates (RLHF loop, diffusion denoise, self-refine) → use cycle.
- If the concept describes results/improvements → use bar_chart with paper-specific numbers (invent plausible values anchored to the explanation if exact numbers aren't given).
- If the SINGLE striking takeaway is a number or ratio (e.g. "1000× fewer parameters", "97% accuracy", "3.2B tokens") → use number_box.
- If the concept is defined by a formula (attention, losses, optimizer update rules) → use equation.
- attention_heatmap / multi_head: only for explicit attention mechanism content.
- sine_waves: only for frequency, positional encoding, or wave phenomena.

Paper: "$TITLE"
Concept: "$CONCEPT"
Explanation: "$BODY"

Return ONLY valid JSON, no markdown.`;

async function stageDiagramSpec(
  ai: AIClient,
  paperTitle: string,
  concept: RawConcept
): Promise<DiagramSpec | null> {
  const prompt = DIAGRAM_SPEC_PROMPT
    .replace("$TITLE", paperTitle)
    .replace("$CONCEPT", concept.title)
    .replace("$BODY", concept.body);

  try {
    const raw = await ai.chat(
      [
        { role: "system", content: DIAGRAM_SPEC_SYSTEM },
        { role: "user", content: prompt },
      ],
      { model: "claude-haiku-4-5-20251001", max_tokens: 700, temperature: 0.2 }
    );
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return null;
    const spec = JSON.parse(jsonMatch[0]) as DiagramSpec;
    if (spec.type === "custom") return null;
    return stripDashesDeep(spec);
  } catch (err) {
    console.error("[stageDiagramSpec] Error:", err);
    return null;
  }
}

// ─── Stage 2b: Interactive HTML visualization per concept (Sonnet, creative) ──

const VIZ_SYSTEM = `You are an expert creative data visualization engineer building interactive visualizations for a mobile reading app. You write beautiful, creative HTML/CSS/JS from scratch. Every visualization you build is unique and specifically designed for the exact content it represents, never generic or templated.`;

const DESIGN_TOKENS = `
APP DESIGN TOKENS, use these exact values:
  Primary teal:     #1a8a8a
  Teal mid:         #2db8b8
  Teal light:       #e5f4f4
  Amber accent:     #e8a020
  Ink (text):       #1a1a1a
  Muted text:       #888888
  Card background:  #ffffff
  App background:   #f7f4ef
  Border:           #e8e3da
  Font: -apple-system, system-ui, sans-serif
`;

async function stageViz(
  ai: AIClient,
  paperTitle: string,
  concept: RawConcept
): Promise<string> {
  const prompt = `${DESIGN_TOKENS}

Create a self-contained interactive HTML visualization for this concept from an AI research paper.

Paper: "${paperTitle}"
Concept: "${concept.title}"
Explanation: "${concept.body}"

VISUALIZATION STRATEGY, pick the type that best reveals the concept's core insight:
  • Sequential pipeline  → animated nodes that draw in one-by-one, particles or dashes flowing along arrows
  • Before/after contrast → two-column animated reveal, old method fades in left (gray), new method slides in right (teal)
  • Multi-input merge     → fan-in diagram where several sources animate into one output
  • Architecture breakdown → labelled boxes that expand or highlight on tap to show detail
  • Performance metrics   → animated bar/line chart with REAL numbers extracted from the explanation
  • Mathematical concept  → animated formula, weight matrix heatmap, or probability distribution
  • Iterative process     → loop/cycle diagram that spins or steps through phases on tap
  • Attention/similarity  → interactive grid where hovering a cell shows relationship strength
  • Custom creative       → if none of the above fits, invent the right form for this specific idea

RULES:
1. Use SPECIFIC terms, values, and names from this paper. NEVER use "Input", "Output", "Process", "Method", "Step", "Data", "Model", "Result" as labels.
2. At least 2 distinct interactive elements (tap/click/hover each does something different visually).
3. body { margin: 0; padding: 10px 4px 6px; background: transparent; overflow: hidden; }
4. Width 100%, must fit in a 340px card. Zero horizontal overflow.
5. Smooth staggered CSS animations, things appear sequentially, not all at once.
6. No external CDN links, no images, no SVG icons from external sources. Inline everything.
7. Real numbers and specific model names where the explanation mentions them.
8. LAST LINE of your <script>: setTimeout(function(){try{window.webkit.messageHandlers.resize.postMessage(document.documentElement.scrollHeight+24);}catch(e){}},700);

Return ONLY the complete HTML document. No explanation, no markdown fences, no comments outside the code.`;

  try {
    // Sonnet: best creative output for interactive HTML
    const raw = await ai.chat(
      [
        { role: "system", content: VIZ_SYSTEM },
        { role: "user", content: prompt },
      ],
      { model: "claude-sonnet-4-6", max_tokens: 2800, temperature: 0.75 }
    );
    return extractHtml(raw);
  } catch (err) {
    console.error("[stageViz] Claude error:", err);
    return fallbackViz(concept.title, concept.body);
  }
}

export async function generateConceptVisual(
  ai: AIClient,
  paperTitle: string,
  concept: Pick<RawConcept, "title" | "body">
): Promise<{ diagramSpec?: DiagramSpec; vizHtml?: string }> {
  const spec = await stageDiagramSpec(ai, paperTitle, concept);
  if (spec) return { diagramSpec: spec };
  const html = await stageViz(ai, paperTitle, concept);
  return { vizHtml: html };
}

function extractHtml(raw: string): string {
  // Strip markdown code fences if present
  const fenced = raw.match(/```(?:html)?\s*([\s\S]*?)```/i);
  if (fenced) return fenced[1].trim();
  // Find start of HTML document
  const idx = raw.search(/<!DOCTYPE|<html/i);
  if (idx >= 0) return raw.slice(idx).trim();
  // If it looks like HTML fragments, wrap it
  if (raw.includes("<") && raw.includes(">")) return raw.trim();
  return fallbackViz("Concept", raw.slice(0, 100));
}

function fallbackViz(title: string, body: string): string {
  const escaped = title.replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return `<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{background:transparent;font-family:-apple-system,system-ui,sans-serif;padding:10px 4px;}
.card{background:#e5f4f4;border-radius:12px;padding:16px;border:1px solid #c8e8e8;}
.title{font-size:14px;font-weight:700;color:#1a8a8a;margin-bottom:8px;}
.body{font-size:12px;color:#333;line-height:1.5;}
</style></head><body>
<div class="card"><div class="title">${escaped}</div><div class="body">${body.replace(/</g,"&lt;")}</div></div>
<script>setTimeout(function(){try{window.webkit.messageHandlers.resize.postMessage(document.documentElement.scrollHeight+24);}catch(e){}},400);</script>
</body></html>`;
}

// ─── Orchestrator ─────────────────────────────────────────────────────────────

export interface PaperInput {
  paper_id: string;
  title: string;
  abstract: string;
  source: string;
  url: string;
}

export async function processPaper(
  ai: AIClient,
  paper: PaperInput
): Promise<CardDeck> {
  // Stage 1: hook + summary + concept titles/bodies (one call, fast model)
  const { hook, summary, concepts: rawConcepts } = await stageSummarise(
    ai, paper.title, paper.abstract
  );

  // Stage 2: per-concept structured DiagramSpec. The web converter renders
  // these as native React components (flow, bar_chart, comparison, cycle,
  // number_box, equation, attention_heatmap, multi_head, sine_waves), so the
  // app surface is "paper in → interactive diagrams out". Run in parallel; a
  // null spec means "no structured diagram fit" and the concept renders as
  // prose only on the client.
  const diagramSpecs = await Promise.all(
    rawConcepts.map((c) => stageDiagramSpec(ai, paper.title, c)),
  );
  const concepts: Concept[] = rawConcepts.map((c, i) => ({
    title: c.title,
    body: c.body,
    diagramSpec: diagramSpecs[i] ?? undefined,
  }));

  // Stage 4: editorial blueprint for the rich 7-card daily-loop render.
  // Independent from concept work, so we ran it as soon as Stage 1 finished
  // would also be fine; left sequential here to keep the orchestration simple
  // and the per-paper budget bounded.
  const blueprint = await buildBlueprint(ai, paper, hook, summary, concepts);

  return {
    paper_id: paper.paper_id,
    title: paper.title,
    source: paper.source,
    url: paper.url,
    hook,
    summary,
    concepts,
    blueprint,
    created_at: new Date().toISOString(),
  };
}

// ─── Stage 4: Editorial Blueprint ────────────────────────────────────────────
//
// Six parallel sub-stages, each a focused Haiku call producing one strict-JSON
// fragment. Sub-stages are independent and run concurrently. Failures fall back
// to a deterministic shape derived from the deck so the iOS render never
// breaks; the loop becomes calmer (no highlights, no metaphor) but never blank.

async function buildBlueprint(
  ai: AIClient,
  paper: PaperInput,
  hook: string,
  summary: string,
  concepts: Concept[],
): Promise<DailyLoopBlueprint> {
  const ctx = {
    title: paper.title,
    abstract: paper.abstract,
    hook,
    summary,
    concepts: concepts.map((c) => ({ title: c.title, body: c.body })),
  };

  const [
    titles,
    findings,
    eli5,
    timeline,
    vizCards,
    completion,
    extras,
  ] = await Promise.all([
    stageBlueprintTitles(ai, ctx),
    stageBlueprintCoreFindings(ai, ctx),
    stageBlueprintEli5(ai, ctx),
    stageBlueprintTimeline(ai, ctx),
    stageBlueprintVizCards(ai, ctx, concepts),
    stageBlueprintCompletion(ai, ctx),
    stageBlueprintExtras(ai, ctx),
  ]);

  const blueprint: DailyLoopBlueprint = stripDashesDeep({
    heroEyebrow: "DAILY LOOP · NEW",
    heroTitle: titles.heroTitle,
    heroBody: titles.heroBody,
    sourceLine: deriveSourceLine(paper),

    hookTitle: titles.hookTitle,
    hookBody: titles.hookBody,

    coreIdeaTitle: titles.coreIdeaTitle,
    coreFindings: findings,

    eliAnalogyLabel: eli5.label,
    eliHeadline: eli5.headline,
    eliBody: eli5.body,

    diagramTitle: titles.diagramTitle,
    timelineNodes: timeline.nodes,
    diagramCollapseText: timeline.collapseText,
    diagramDefaultPanelBody: timeline.defaultPanelBody,

    vizCards,

    completeQuote: completion.quote,
    completeTease: completion.tease,

    paperTitle:    paper.title,
    glossary:      extras.glossary,
    eliArt:        extras.eliArt,
    diagramLayout: extras.diagramLayout,
  });

  return blueprint;
}

// ─── Sub-stage G: Curated extras (glossary, eliArt, diagramLayout) ───────────

interface BlueprintExtrasOut {
  glossary: Record<string, string>;
  eliArt: "scratchPaper" | "megaphone";
  diagramLayout: "flow" | "hub";
}

async function stageBlueprintExtras(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<BlueprintExtrasOut> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You produce three small but important fields that polish the daily-loop reading experience.

Paper: "${ctx.title}"
Summary: "${ctx.summary}"
Concepts:
${ctx.concepts.map((c) => `- ${c.title}: ${c.body}`).join("\n")}
Abstract: """${ctx.abstract.slice(0, 1400)}"""

Return JSON:
{
  "glossary": {
    "<term>": "<1-2 sentence definition, plain English, names a concrete mechanism. 25-50 words.>",
    ...
  },
  "eliArt":        "scratchPaper" | "megaphone",
  "diagramLayout": "flow" | "hub"
}

Glossary rules:
- 8 to 14 entries.
- Pick terms a smart reader without an ML degree might still need: technical jargon ("forward pass", "logit", "softmax"), proper nouns the paper relies on ("PaLM", "GSM8K", "ChatGPT"), study-specific phrases ("treatment group", "scaffold", "homogenization"), domain abbreviations.
- Keys are lowercase or natural-case as they appear in the body. Definitions never restate the term as the first phrase.
- Definitions must teach the term in isolation. Do not say "the paper shows…", just define.
- Voice: clear, declarative, concrete. Same texture as a Kindle dictionary entry.

eliArt rules:
- "scratchPaper" if the paper's analogy is about reasoning, writing, working things out, accumulation, learning over time.
- "megaphone" if the analogy is about amplification, signal vs noise, one voice drowning others, attention, broadcasting.
- Pick the one that visually rhymes with the analogy you wrote in eliBody.

diagramLayout rules:
- "flow" for sequential narratives: time series, training steps, model-size sweep, chain of reasoning. Most papers want this.
- "hub" only when one central node has multiple peripheral relationships (one query attending to many keys, one model serving many tasks).`;

  type Out = BlueprintExtrasOut;
  const fb: Out = {
    glossary: {},
    eliArt: "scratchPaper",
    diagramLayout: "flow",
  };
  const out = await chatJson<Out>(ai, prompt, fb, {
    tier: "editorial",
    temperature: 0.4,
    maxTokens: 2200,
  });
  // Coerce in case the LLM wandered.
  const eliArt = out.eliArt === "megaphone" ? "megaphone" : "scratchPaper";
  const diagramLayout = out.diagramLayout === "hub" ? "hub" : "flow";
  const glossary = (out.glossary && typeof out.glossary === "object") ? out.glossary : {};
  return { glossary, eliArt, diagramLayout };
}

// ─── Blueprint shared types & helpers ─────────────────────────────────────────

interface BlueprintCtx {
  title: string;
  abstract: string;
  hook: string;
  summary: string;
  concepts: { title: string; body: string }[];
}

const BLUEPRINT_GLOBAL_RULES = `
Voice: editorial, calm, declarative, present tense. Concrete > abstract every time.
NEVER use generic placeholders ("Model A", "Method X", "Step 1", "Group 1"). Every label
must be drawn from the paper: real model names, parameter counts, dataset names, dates.
NEVER use hype words ("revolutionary", "groundbreaking", "unprecedented", "stunning").
NEVER use em dashes (—) or en dashes (–). Use commas, colons, semicolons, periods, or parentheses.
Highlight phrases must be a verbatim substring of the parent string. Pick one short phrase (1-4 words).
Return only valid JSON, no markdown, no commentary.

Two FULL exemplars below. Match this density, this voice, this level of concrete grounding.
Do not copy the wording. Match the *texture*: short contrarian punchlines, real numbers,
metaphors that are physical scenes (not abstract bridges or journeys), bold spans that land
the unsettling beat last.

────────────────────────── EXEMPLAR 1 ──────────────────────────
Paper: "Generative AI and the Lasting Homogenization of Human Creative Writing" (Liu et al., 2024)
heroTitle:     "When ChatGPT leaves, creativity vanishes" / highlight "vanishes"
heroBody:      "ChatGPT's creative boost vanishes the second it's gone. The flattened style stays."
hookTitle:     "Is the boost in your head, or just rented from the tool?" / highlight "rented"
hookBody:      "A 7-day lab experiment + 30-day follow-up across 61 students and 3,302 ideas. The treatment group used ChatGPT; the control did not. The boost shows up for 5 days, evaporates the moment ChatGPT is switched off, and homogenization of writing style persists 30 days later."
coreFindings:
  - "The boost is rented, not learned" / "Over 5 days the treatment group consistently outscored controls on idea novelty and quality. On day 7, with ChatGPT removed, treatment scores dropped to control-group baseline. The skill never crossed into the user."
  - "Homogenization sticks around" / "ChatGPT-assisted ideas converged toward a shared style: same phrasings, same structures, lower inter-person variance. That convergence persisted on day 7 and at the 30-day follow-up, long after ChatGPT was gone."
  - "Performance ≠ capability" / "Higher scores during access masked an unchanged underlying capability. Once the scaffold dropped, output reverted, but the *style* fingerprint of the tool was now baked into how participants wrote."
eliLabel:      "ANALOGY · EXOSKELETON, NOT MUSCLE"
eliHeadline:   "It's like training every day in a powered exoskeleton." / highlight "a powered exoskeleton"
eliBody:       "With the suit on, you run further than ever. Take it off, and you're right back where you started. The suit did the work, your legs didn't change. Worse: every day in the suit, your gait reshapes to match the machine. Even unaided, everyone now runs the same way. ChatGPT lifts your output while you lean on it, and quietly flattens how you write, for keeps." / bold "everyone now runs the same way"
timelineNodes: Day 1 (baseline) → Day 5 (peak boost) → Day 7 (ChatGPT off) → Day 30 (still flat)
vizBar.points: D1 / D3 / D5 (peak) / D7 (off) / D30, primary climbs to 0.95 then drops to 0.10
vizBar.takeaway:    "The gain lives in the tool, not in the user."
vizScatter.before:  "Day 1: every student has their own writing fingerprint."
vizScatter.after:   "Day 30: ChatGPT group has collapsed to a tight cluster. The fingerprint outlived the tool."
vizScatter.takeaway: "Performance reverts. Style does not."
completeQuote: "ChatGPT lifts you while you lean on it. It flattens you forever."

────────────────────────── EXEMPLAR 2 ──────────────────────────
Paper: "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models" (Wei et al., 2022)
heroTitle:     "How one line of text made models reason" / highlight "reason"
heroBody:      "Wei et al. show that prepending worked-out examples lifts a 540B model from 17% to 57% on grade-school math, with no retraining."
hookTitle:     "What if writing \\"let's think step by step\\" made a model 3× smarter?" / highlight \\"let's think step by step\\"
hookBody:      "Google traced a massive reasoning gain to a prompting trick: include a few worked-out examples and the model starts writing its own scratch work, lifting grade-school-math accuracy from 17% to 57%."
coreFindings:
  - "Standard prompting hides the work" / "Q → A forces the model to compute the answer in one forward pass. For multi-step problems there's no room for intermediate reasoning. The answer arrives half-formed."
  - "Chain-of-thought exposes the path" / "Prepend a few examples of worked-out reasoning (Q → thought₁ → thought₂ → A). The model imitates the format and starts generating its own intermediate steps before answering."
  - "The ability emerges with scale" / "CoT barely helps below ~62B parameters. The steps come out incoherent and often hurt accuracy. Above that threshold, multi-step reasoning clicks on sharply. It's an emergent capability, not a continuous curve."
eliLabel:      "ANALOGY · MENTAL MATH VS. SCRATCH PAPER"
eliHeadline:   "Imagine solving 23 × 17 in your head, vs. on paper." / highlight "23 × 17"
eliBody:       "A model with plain prompting is a kid asked to shout the answer immediately. Chain-of-thought is like giving that same kid scratch paper. Same brain, same numbers. But now they can work it out step by step, check as they go, and land on the right answer. The trick isn't a smarter kid. It's space to think." / bold "scratch paper"
timelineNodes: Problem (5 + 2 cans) → Thought 1 (2 × 3 = 6) → Thought 2 (5 + 6 = 11) → Answer (11)
vizBar.points: 8B / 62B / 175B / 540B (PaLM), CoT 0.05 / 0.18 / 0.35 / 0.57 vs standard flat
vizBar.cliffLabel:   "emergence" at index 1
vizBar.takeaway:     "Reasoning is emergent. It needs scale to compile."
vizScatter.takeaway: "Same brain, more space, better answer."
completeQuote: "Big models can reason, if you give them room to write it down."

────────────────────────── PRINCIPLES ──────────────────────────
1. Every coreFinding.title is 4-7 words, contains a verb or contrast (≠, "not", reversal).
2. Metaphors are physical scenes with multiple beats: suit on→off→gait reshaped, kid mental→paper→step-by-step. Avoid bridges, journeys, keys, foundations.
3. Bold spans land the unsettling punchline last, not summarise.
4. Bar/scatter takeaway lines are aphoristic, 6-12 words, declarative, contrarian if possible.
5. Annotations cite a real number (62B, 17%→57%, day 7, ~1σ).
6. completeQuote is one sentence, sounds like the paper's takeaway said by a friend at a bar.
`;

async function chatJson<T>(
  ai: AIClient,
  prompt: string,
  fallback: T,
  opts: { temperature?: number; maxTokens?: number; tier?: "fast" | "editorial" } = {},
): Promise<T> {
  // Editorial tier hits the more capable model (Sonnet on Anthropic, gpt-4o on
  // the OpenAI fallback) so prose voice matches the hand-written daily-paper
  // exemplars instead of the cheaper summary-style default.
  const model = opts.tier === "editorial"
    ? "claude-opus-4-7"
    : "claude-haiku-4-5-20251001";
  try {
    const raw = await ai.chat(
      [{ role: "user", content: prompt }],
      {
        model,
        max_tokens: opts.maxTokens ?? 700,
        temperature: opts.temperature ?? 0.4,
      },
    );
    const m = raw.match(/\{[\s\S]*\}/);
    if (!m) return fallback;
    return JSON.parse(m[0]) as T;
  } catch (err) {
    console.error("[blueprint] chatJson failed:", err);
    return fallback;
  }
}

function deriveSourceLine(paper: PaperInput): string {
  const src = paper.source.toLowerCase() === "arxiv" ? "arXiv" : paper.source;
  const idMatch = paper.paper_id.match(/(\d{4}\.\d{4,5})/);
  const idPart = idMatch ? `:${idMatch[1]}` : "";
  return `${src}${idPart}`;
}

// ─── Sub-stage A: Section titles + hero/hook strings ─────────────────────────

interface BlueprintTitlesOut {
  heroTitle: HighlightedText;
  heroBody: string;
  hookTitle: HighlightedText;
  hookBody: string;
  coreIdeaTitle: HighlightedText;
  diagramTitle: HighlightedText;
}

async function stageBlueprintTitles(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<BlueprintTitlesOut> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You write editorial section titles for a 7-card paper deep-dive.

Paper: "${ctx.title}"
Existing hook: "${ctx.hook}"
Summary: "${ctx.summary}"

Return JSON exactly:
{
  "heroTitle":     { "text": "<8-12 word headline, present tense>", "highlight": "<2-4 word phrase from text>" },
  "heroBody":      "<one sentence, 18-32 words, the core stake>",
  "hookTitle":     { "text": "<10-18 word provocative question>", "highlight": "<2-4 word phrase>" },
  "hookBody":      "<3-4 sentences, 60-90 words, sets up the experiment / claim with concrete numbers from the abstract>",
  "coreIdeaTitle": { "text": "<6-10 word framing of the three findings>", "highlight": "<1-3 word phrase>" },
  "diagramTitle":  { "text": "<6-10 word framing of the timeline>", "highlight": "<1-3 word phrase>" }
}

Abstract for grounding: """${ctx.abstract.slice(0, 1400)}"""`;

  return chatJson<BlueprintTitlesOut>(ai, prompt, {
    heroTitle:     { text: ctx.title },
    heroBody:      ctx.summary,
    hookTitle:     { text: ctx.hook },
    hookBody:      ctx.summary,
    coreIdeaTitle: { text: "Three things this paper uncovers" },
    diagramTitle:  { text: "How the result unfolds" },
  }, { maxTokens: 900, tier: "editorial", temperature: 0.55 });
}

// ─── Sub-stage B: Core findings (3 roman items) ──────────────────────────────

async function stageBlueprintCoreFindings(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<CoreFinding[]> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You distill a paper into exactly THREE core findings, like roman-numeral chapter beats.

These bullets render on the FIRST card under "YOU'LL LEARN", so they are the
reader's first impression. The audience is curious but NOT technical: a
designer, a journalist, a smart teenager. They have never read an ML paper.
Every title MUST read as plain English to that reader.

CRITICAL voice rules for titles:
- Plain English only. No ML jargon, no math notation, no acronyms.
  BANNED words and phrases include: emerges, scales, parameters, tokens,
  embeddings, gradients, residual, softmax, activation, dropout, ReLU,
  encoder, decoder, BLEU, O(1), Nash, minimax, in context learning,
  invariance, hierarchy, co-occurrence, negative sampling, fine-tuning,
  capability, scaling laws, attention, multi-head.
- Use everyday verbs and concrete images (talk, fixate, leak, copy, see,
  forget, fake, spot, slip, picks up, sounds like).
- Contrarian comma-reversal is welcome ("Looking smart is not being smart").
- 4 to 9 words. Sentence case. No trailing period.
- A non-technical reader must finish the bullet and instantly know what it
  is gesturing at, even if they don't yet know how it works.

Paper: "${ctx.title}"
Concepts the paper covers:
${ctx.concepts.map((c, i) => `${i + 1}. ${c.title}: ${c.body}`).join("\n")}

Plain-English title exemplars (use this voice):
- "The skill leaves when the tool leaves"
- "Everyone starts sounding the same"
- "Looking smart is not being smart"
- "Show it a few examples and it picks up the task"
- "Bigger models get steadily smarter"
- "Size matters more than clever tricks"
- "Any word can talk to any other instantly"
- "A shortcut keeps signals alive"
- "One filter slid across the whole image"

Return JSON:
{ "findings": [
  { "title": "<plain English, 4-9 words, no jargon, see rules above>", "detail": "<35-55 words. Cite at least one concrete number, model name, or dataset from the concepts. The detail can be more technical, the title cannot.>" },
  { "title": "...", "detail": "..." },
  { "title": "...", "detail": "..." }
] }

Bad title examples (jargon or PR voice, do NOT do this):
- "Chain of Thought Improves Reasoning" (jargon term, paraphrases title)
- "Capability scales smoothly with parameters" (jargon, abstract)
- "Path length collapses to O(1)" (math notation, opaque)
- "ReLU replaces tanh" (acronyms only a researcher knows)
- "Eight Examples Elevate Accuracy" (PR voice, no edge)`;

  type Out = { findings: CoreFinding[] };
  const fb: Out = {
    findings: ctx.concepts.slice(0, 3).map((c) => ({ title: c.title, detail: c.body })),
  };
  const out = await chatJson<Out>(ai, prompt, fb, { maxTokens: 1200, tier: "editorial", temperature: 0.55 });
  // Force exactly 3 items.
  const list = (out.findings ?? []).slice(0, 3);
  while (list.length < 3) list.push(fb.findings[list.length] ?? { title: ctx.concepts[0]?.title ?? "Finding", detail: ctx.concepts[0]?.body ?? "" });
  return list;
}

// ─── Sub-stage C: ELI5 metaphor card ─────────────────────────────────────────

interface BlueprintEli5Out {
  label: string;
  headline: HighlightedText;
  body: HighlightedText;  // bold spans permitted
}

async function stageBlueprintEli5(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<BlueprintEli5Out> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You translate a research paper's central claim into ONE concrete physical metaphor.

Paper: "${ctx.title}"
Core summary: "${ctx.summary}"

Reference (the bar we're matching, do not copy it, just match the texture):
- label:    "ANALOGY · EXOSKELETON, NOT MUSCLE"
- headline: "It's like training every day in a powered exoskeleton."
            highlight: "a powered exoskeleton"
- body:     "With the suit on, you run further than ever. Take it off, and you're right back where you started. The suit did the work, your legs didn't change. Worse: every day in the suit, your gait reshapes to match the machine. Even unaided, everyone now runs the same way. ChatGPT lifts your output while you lean on it, and quietly flattens how you write, for keeps."
            bold: "everyone now runs the same way"

Notice the metaphor is a physical scene with multiple beats (suit on → suit off → gait reshaped). The body narrates *the metaphor first*, then in the LAST sentence maps it back to the paper. Bold is the unsettling punchline.

Return JSON:
{
  "label":    "ANALOGY · <2-4 WORD ALL-CAPS PUNCHLINE WITH COMMA OR 'NOT' STRUCTURE>",
  "headline": { "text": "<one sentence, 'It's like ...', 12-22 words, ends with period>", "highlight": "<2-4 word noun phrase from text, the metaphor object>" },
  "body":     { "text": "<3-5 sentences, 80-130 words. Sentences 1-3 narrate the metaphor scene with concrete action. Final sentence maps the metaphor back to the paper's claim using a paper-specific term.>", "bold": "<verbatim phrase from text, 3-7 words, the unsettling punchline>" }
}

Constraints:
- Metaphor must be a single physical object or scene with action: a sieve filtering, a gait reshaping, a road forking, a sealed vault.
- Avoid abstract metaphors ("a bridge", "a journey", "a key", "a foundation"). Those are dead.
- Avoid AI/tech imagery (no robots, screens, circuits, neural networks).
- "bold" must be a verbatim substring of "text".`;

  return chatJson<BlueprintEli5Out>(ai, prompt, {
    label:    "ANALOGY · DIRECT",
    headline: { text: `It's the kind of result that ${ctx.title.toLowerCase()}.` },
    body:     { text: ctx.summary },
  }, { temperature: 0.7, maxTokens: 1100, tier: "editorial" });
}

// ─── Sub-stage D: Timeline diagram (3-4 checkpoints) ─────────────────────────

interface BlueprintTimelineOut {
  nodes: TimelineNode[];
  collapseText: string;
  defaultPanelBody: string;
}

async function stageBlueprintTimeline(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<BlueprintTimelineOut> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You map a paper's central narrative arc to 3-4 ordered checkpoints. The
checkpoints can be temporal (Day 1, Day 7, Day 30), scale-based (8B, 62B,
175B, 540B), or step-based (Sample, Train, Eval, Deploy). Pick the axis the
paper itself emphasises.

Paper: "${ctx.title}"
Concepts:
${ctx.concepts.map((c) => `- ${c.title}: ${c.body}`).join("\n")}

Return JSON:
{
  "nodes": [
    { "label": "<short, 2-6 chars>", "sublabel": "<1-3 word qualifier>", "panelTitle": "<title-cased phrase>", "panelBody": "<30-50 word panel description, present tense>" }
  ],
  "collapseText":     "<3-6 word callout line shown when all nodes collapse, with one leading symbol like ⚠ or ↳>",
  "defaultPanelBody": "<one sentence prompting the user to tap a node>"
}

Provide between 3 and 4 nodes.`;

  type Out = BlueprintTimelineOut;
  const fb: Out = {
    nodes: ctx.concepts.slice(0, 4).map((c, i) => ({
      label: `Step ${i + 1}`,
      sublabel: undefined,
      panelTitle: c.title,
      panelBody: c.body,
    })),
    collapseText: "↳ Paper arc",
    defaultPanelBody: "Tap a checkpoint to see what the paper shows at that point.",
  };
  const out = await chatJson<Out>(ai, prompt, fb, { maxTokens: 1100 });
  const nodes = (out.nodes ?? []).slice(0, 4);
  if (nodes.length < 3) nodes.push(...fb.nodes.slice(nodes.length, 3));
  return { nodes, collapseText: out.collapseText ?? fb.collapseText, defaultPanelBody: out.defaultPanelBody ?? fb.defaultPanelBody };
}

// ─── Sub-stage E: Two narrative viz cards ────────────────────────────────────

async function stageBlueprintVizCards(
  ai: AIClient,
  ctx: BlueprintCtx,
  concepts: Concept[],
): Promise<VizCard[]> {
  const barConcept = pickBarConcept(concepts);

  const [bar, scatter] = await Promise.all([
    stageVizBarCard(ai, ctx, barConcept),
    stageVizScatterCard(ai, ctx),
  ]);

  return [bar, scatter];
}

function pickBarConcept(concepts: Concept[]): { title: string; body: string } | null {
  const withBar = concepts.find((c) => c.diagramSpec?.type === "bar_chart");
  if (withBar) return { title: withBar.title, body: withBar.body };
  return concepts[1] ?? concepts[0] ?? null;
}

async function stageVizBarCard(
  ai: AIClient,
  ctx: BlueprintCtx,
  source: { title: string; body: string } | null,
): Promise<VizCard> {
  const abstractTail = ctx.abstract.slice(-1200);
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You design a narrative bar chart that tells the paper's central comparative story.
The chart is a sequence of points along the SAME axis (time, model size, dataset, training step, dose) where the gap between primary and secondary opens then closes (or grows monotonically) across the points.

Paper: "${ctx.title}"
Anchor concept: "${source?.title ?? ctx.concepts[0]?.title ?? ""}: ${source?.body ?? ctx.concepts[0]?.body ?? ""}"
Summary: "${ctx.summary}"
Abstract excerpt (mine for axis, numbers, model names): """${abstractTail}"""

Reference points (notice: concrete x-axis labels, real numbers, narrative annotations):
- {"label":"D1","sublabel":"baseline","primary":0.30,"secondary":0.30,"annotation":"Both groups start at the same creativity score. Random assignment held; any later gap is causal."}
- {"label":"D5","sublabel":"peak","primary":0.82,"secondary":0.34,"annotation":"Peak boost. Treatment group is now ~1σ above control on novelty + quality. Looks like real learning."}
- {"label":"D7","sublabel":"GPT off","primary":0.32,"secondary":0.33,"annotation":"ChatGPT withdrawn. Treatment scores collapse to control-group baseline within 24 hours. The skill never crossed in."}

Return JSON:
{
  "kicker":  "CARD 05 · <1-3 ALL-CAPS WORDS, e.g. 'THE CLIFF', 'EMERGENCE', 'THE DOSE'>",
  "title":   { "text": "<8-14 word descriptive title with verb>", "highlight": "<2-4 word phrase>" },
  "spec": {
    "kind": "bar",
    "yAxisLabel":      "<short axis label, plain English>",
    "primaryLabel":    "<2-4 word legend, the new method/treatment with paper-specific name>",
    "secondaryLabel":  "<2-4 word legend, the baseline/control with paper-specific name>",
    "yTickLabels":     ["<low tick label>", "<mid tick label>", "<high tick label>"],
    "cliffIndex":      <0-based index of the narrative pivot bar, optional>,
    "cliffLabel":      "<1-3 word label for that bar's pivot moment, optional>",
    "defaultInsight":  "<one sentence prompting the user to tap any bar to see what happens>",
    "points": [
      { "label": "<x-axis label, paper-specific: model size, day, dataset, dose>", "sublabel": "<optional 1-3 word qualifier>", "primary": <0-1>, "secondary": <0-1>, "annotation": "<25-40 word narrative beat for THIS bar, citing concrete numbers or mechanism>" }
    ]
  },
  "caption":  "<1-2 sentences naming the axes and the story>",
  "takeaway": "<one declarative line, 6-12 words, contrarian if possible>"
}

Provide 4-6 points. The narrative must read coherently left to right.

ABSOLUTE BANS:
- NO generic labels: "Model A", "Model B", "Group 1", "Method 1", "Step 1", "Trial 1". Use real names from the paper (PaLM-540B, GSM8K, 62B, "Day 7", "ChatGPT off").
- NO PR-style annotations ("showcasing enhanced reasoning", "highlighting the impact"). Be specific about what each bar shows.
- All primary/secondary values must be 0..1 (normalised).`;

  const fb: VizCard = {
    kicker: "CARD 05 · COMPARISON",
    title: { text: source?.title ?? ctx.concepts[0]?.title ?? "Comparison" },
    spec: {
      kind: "bar",
      yAxisLabel: "Score",
      primaryLabel: "New",
      secondaryLabel: "Baseline",
      yTickLabels: ["low", "mid", "high"],
      defaultInsight: "Tap any bar to read what changes at that point.",
      points: [
        { label: "A", primary: 0.3, secondary: 0.3, annotation: "Starting point: both methods comparable." },
        { label: "B", primary: 0.5, secondary: 0.32, annotation: "New method pulls ahead." },
        { label: "C", primary: 0.7, secondary: 0.34, annotation: "Gap widens with scale." },
        { label: "D", primary: 0.85, secondary: 0.36, annotation: "Peak separation." },
      ],
    },
    caption: "Comparative scores across configurations.",
    takeaway: "The gap is the story.",
  };
  return chatJson<VizCard>(ai, prompt, fb, { temperature: 0.55, maxTokens: 1500, tier: "editorial" });
}

async function stageVizScatterCard(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<VizCard> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You design a before/after scatter morph that visualises a distributional shift
the paper documents (e.g., spread → cluster, or one cluster → another).

Paper: "${ctx.title}"
Summary: "${ctx.summary}"
Concepts: ${ctx.concepts.map((c) => c.title).join(", ")}

Return JSON:
{
  "kicker":  "CARD 06 · <2-4 word framing>",
  "title":   { "text": "<8-14 word descriptive title>", "highlight": "<2-4 word phrase>" },
  "spec": {
    "kind": "scatter",
    "beforeLabel":            "<2-4 words, e.g. 'Day 1' or 'Without scratchpad'>",
    "afterLabel":             "<2-4 words>",
    "treatmentLabel":         "<2-4 words, the group affected>",
    "controlLabel":           "<2-4 words, the comparison group>",
    "treatmentBeforePattern": "spread" | "cluster_left" | "cluster_right",
    "treatmentAfterPattern":  "spread" | "cluster_left" | "cluster_right" | "cluster_center",
    "controlBeforePattern":   "spread" | "cluster_left" | "cluster_right",
    "controlAfterPattern":    "spread" | "cluster_left" | "cluster_right",
    "treatmentCount":         <integer 6-10>,
    "controlCount":           <integer 4-8>,
    "beforeCaption":          "<one sentence describing the before state>",
    "afterCaption":           "<one sentence describing the after state>",
    "xAxisLabel":             "<short axis label ending with →>",
    "yAxisLabel":             "<short axis label ending with →>"
  },
  "caption":  "<1-2 sentences instructing the user to scrub from before to after>",
  "takeaway": "<one declarative line, 6-12 words>"
}

Pick patterns that visually echo the paper's claim. Default to "spread" before
and a cluster after when the paper documents convergence.`;

  const fb: VizCard = {
    kicker: "CARD 06 · SHIFT",
    title: { text: "How the distribution changes" },
    spec: {
      kind: "scatter",
      beforeLabel: "Before",
      afterLabel: "After",
      treatmentLabel: "Treatment",
      controlLabel: "Control",
      treatmentBeforePattern: "spread",
      treatmentAfterPattern: "cluster_center",
      controlBeforePattern: "spread",
      controlAfterPattern: "spread",
      treatmentCount: 8,
      controlCount: 6,
      beforeCaption: "Both groups occupy the full space.",
      afterCaption: "Treatment converges; control stays spread.",
      xAxisLabel: "Dimension 1 →",
      yAxisLabel: "Dimension 2 →",
    },
    caption: "Each dot is one observation. Drag the scrubber to see the shift.",
    takeaway: "The treatment leaves a fingerprint.",
  };
  return chatJson<VizCard>(ai, prompt, fb, { temperature: 0.55, maxTokens: 1300, tier: "editorial" });
}

// ─── Sub-stage F: Completion quote + tease ───────────────────────────────────

interface BlueprintCompletionOut {
  quote: string;
  tease: string;
}

async function stageBlueprintCompletion(
  ai: AIClient,
  ctx: BlueprintCtx,
): Promise<BlueprintCompletionOut> {
  const prompt = `${BLUEPRINT_GLOBAL_RULES}

You write the closing pull-quote and next-day tease for a paper deep-dive.

Paper: "${ctx.title}"
Summary: "${ctx.summary}"

Return JSON:
{
  "quote": "<one sentence in double quotes, 10-22 words, captures the paper's claim as the user should remember it>",
  "tease": "<one short sentence, 6-12 words, hints at tomorrow's paper without naming it>"
}`;

  return chatJson<BlueprintCompletionOut>(ai, prompt, {
    quote: `"${ctx.summary.split(".")[0]}."`,
    tease: "Come back tomorrow for the next paper.",
  }, { maxTokens: 500, tier: "editorial", temperature: 0.6 });
}
