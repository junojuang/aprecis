/**
 * Agentic lesson refinery for generated Aprecis web lessons.
 *
 * Evaluator-first by default: runs local specialist rubrics, writes quality
 * reports, and ranks the lessons that need repair. Add --llm to ask an LLM
 * critic for deeper paper-fidelity and teaching-flow feedback.
 *
 * Run from repo root:
 *   deno run --allow-read --allow-write --allow-env --allow-net \
 *     backend/scripts/refine-web-lessons.ts --batch canonical-50
 *
 * Focus one lesson:
 *   deno run --allow-read --allow-write --allow-env --allow-net \
 *     backend/scripts/refine-web-lessons.ts --paper mamba --llm
 */

type LessonKind =
  | "cover"
  | "story"
  | "map"
  | "compare"
  | "slider"
  | "chooser"
  | "results"
  | "recap"
  | "source";

type LessonCard = {
  kind: LessonKind;
  kicker: string;
  title: string;
  body?: string[];
  caption?: string;
  left?: string;
  middle?: string;
  right?: string;
  offLabel?: string;
  onLabel?: string;
  offNote?: string;
  onNote?: string;
  lowLabel?: string;
  highLabel?: string;
  low?: string;
  mid?: string;
  high?: string;
  choices?: Array<{ label: string; note: string }>;
  bars?: Array<{ label: string; note: string; value: number }>;
  recap?: Array<{ label: string; note: string }>;
};

type Lesson = {
  paper_id: string;
  short_name: string;
  title: string;
  authors?: string;
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

type ArxivMeta = {
  title: string;
  abstract: string;
  authors?: string[];
  year: number;
  url: string;
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
};

type Severity = "blocker" | "major" | "minor";
type Specialist =
  | "research_grounding"
  | "beginner_mental_model"
  | "narrative_flow"
  | "interaction_design"
  | "aprecis_style"
  | "mobile_fit"
  | "source_integrity"
  | "llm_critic";

type LessonIssue = {
  specialist: Specialist;
  severity: Severity;
  card?: number;
  finding: string;
  repair: string;
};

type CategoryScore = {
  score: number;
  notes: string[];
};

type LessonReport = {
  paper_id: string;
  title: string;
  score: number;
  grade: "ship" | "polish" | "repair" | "rebuild";
  blocking_issues: string[];
  category_scores: Record<Specialist, CategoryScore>;
  issues: LessonIssue[];
  recommended_repairs: string[];
  repair_brief: string;
  llm?: {
    model: string;
    raw_score?: number;
    notes?: string[];
  };
};

type IndexReport = {
  generated_at: string;
  batch: string;
  lesson_count: number;
  average_score: number;
  grade_counts: Record<LessonReport["grade"], number>;
  worst: Array<{ paper_id: string; title: string; score: number; grade: LessonReport["grade"] }>;
  reports: Array<{ paper_id: string; score: number; grade: LessonReport["grade"]; path: string }>;
};

const ROOT = new URL("../../", import.meta.url).pathname.replace(/\/backend\/$/, "");
const DEFAULT_BATCH = "canonical-50";
const EXPECTED_ORDER = "cover,story,map,compare,story,slider,chooser,results,story,recap,source";
const REPORT_ROOT = `${ROOT}/data/generated/lesson-quality`;
const MODEL = Deno.args.find((arg) => arg.startsWith("--model="))?.split("=")[1] ?? "gpt-4.1-mini";

const args = parseArgs(Deno.args);
const batch = args.batch ?? DEFAULT_BATCH;
const cacheDir = `${ROOT}/data/generated/${batch}`;
const htmlDir = `${ROOT}/prototypes/web-lesson/${batch}`;
const reportDir = `${REPORT_ROOT}/${batch}`;
const useLlm = args.flags.has("llm");
const maxLessons = args.limit ?? Number.POSITIVE_INFINITY;
let catalogPaperIds = new Set<string>();

const genericResearchPhrases = [
  "this paper shows",
  "this paper introduces",
  "this paper presents",
  "the paper shows",
  "the paper introduces",
  "state-of-the-art",
  "significant improvement",
  "various tasks",
  "many applications",
];

const genericTitlePhrases = [
  "why it matters",
  "core idea",
  "how it works",
  "what changed",
  "why this paper belongs",
  "result or impact",
  "the big idea",
];

const genericInteractionPhrases = [
  "old way",
  "paper's way",
  "ingredient",
  "what it does",
  "important parts",
  "what matters",
  "efficient output",
  "model learns",
  "better performance",
  "more accurate",
  "fast as sequences grow",
  "focus only on",
  "most relevant",
  "efficient output prediction",
];

const weakStylePhrases = [
  "in conclusion",
  "it is important",
  "a huge challenge",
  "very important",
  "various tasks",
  "many applications",
  "changed ai",
  "revolutionized",
  "powerful tool",
  "huge challenge",
  "sidesteps",
  "what matters most",
];

await Deno.mkdir(reportDir, { recursive: true });

const entries = await lessonEntries();
catalogPaperIds = new Set(entries.map((entry) => entry.paper_id));
const selected = args.papers.size
  ? entries.filter((entry) => args.papers.has(entry.paper_id))
  : entries;

if (selected.length === 0) {
  console.error("No lessons matched the requested batch or paper filter.");
  Deno.exit(1);
}

const reports: LessonReport[] = [];
for (const entry of selected.slice(0, maxLessons)) {
  const lesson = JSON.parse(await Deno.readTextFile(entry.local_json)) as Lesson;
  const arxivMeta = await readJsonIfExists<ArxivMeta>(`${cacheDir}/${entry.arxiv_id.replace("/", "_")}.arxiv.json`);
  const html = await readTextIfExists(entry.local_html ?? `${htmlDir}/${entry.paper_id}.html`);
  console.log(`evaluating ${lesson.paper_id}`);

  const report = evaluateLesson(lesson, arxivMeta, html);
  if (useLlm) {
    const llm = await critiqueWithLlm(lesson, arxivMeta);
    mergeLlmCritique(report, llm);
  }
  finalizeReport(report);
  reports.push(report);

  await Deno.writeTextFile(
    `${reportDir}/${reportFileName(lesson.paper_id)}`,
    JSON.stringify(report, null, 2) + "\n",
  );
}

reports.sort((a, b) => a.score - b.score || a.paper_id.localeCompare(b.paper_id));
const index = buildIndex(reports);
const reportRunName = args.papers.size ? `selected-${[...args.papers].sort().join("-")}` : "index";
const queueRunName = args.papers.size ? `repair-queue-${[...args.papers].sort().join("-")}` : "repair-queue";
await Deno.writeTextFile(`${reportDir}/${reportRunName}.json`, JSON.stringify(index, null, 2) + "\n");
await Deno.writeTextFile(`${reportDir}/${queueRunName}.md`, renderRepairQueue(reports));

console.log("");
console.log(`wrote ${reportDir}/${reportRunName}.json`);
console.log(`wrote ${reportDir}/${queueRunName}.md`);
console.log(`average=${index.average_score.toFixed(1)} lessons=${index.lesson_count}`);
console.log("worst:");
for (const item of index.worst.slice(0, 10)) {
  console.log(`- ${item.score} ${item.grade} ${item.paper_id}: ${item.title}`);
}

async function lessonEntries(): Promise<ManifestEntry[]> {
  const manifest = await readJsonIfExists<ManifestEntry[]>(`${cacheDir}/manifest.json`);
  const all = manifest ??
    (await collectJsonLessons()).map((lesson) => ({
      paper_id: lesson.paper_id,
      title: lesson.title,
      arxiv_id: lesson.arxiv_id,
      topic: lesson.topic,
      year: lesson.year,
      url: lesson.url,
      local_html: `${htmlDir}/${lesson.paper_id}.html`,
      local_json: `${cacheDir}/${lesson.paper_id}.json`,
    }));
  return all.map((entry) => ({
    ...entry,
    local_json: normalizeGeneratedPath(entry.local_json),
    local_html: normalizeGeneratedPath(entry.local_html),
  }));
}

async function collectJsonLessons(): Promise<Lesson[]> {
  const lessons: Lesson[] = [];
  for await (const entry of Deno.readDir(cacheDir)) {
    if (!entry.isFile || !entry.name.endsWith(".json")) continue;
    if (entry.name === "manifest.json" || entry.name.endsWith(".arxiv.json")) continue;
    lessons.push(JSON.parse(await Deno.readTextFile(`${cacheDir}/${entry.name}`)) as Lesson);
  }
  return lessons;
}

function evaluateLesson(lesson: Lesson, arxivMeta: ArxivMeta | null, html: string | null): LessonReport {
  const category_scores = emptyCategoryScores();
  const issues: LessonIssue[] = [];
  const ctx = { lesson, arxivMeta, html, category_scores, issues };

  researchGrounding(ctx);
  beginnerMentalModel(ctx);
  narrativeFlow(ctx);
  interactionDesign(ctx);
  aprecisStyle(ctx);
  mobileFit(ctx);
  sourceIntegrity(ctx);

  return {
    paper_id: lesson.paper_id,
    title: lesson.title,
    score: 0,
    grade: "rebuild",
    blocking_issues: [],
    category_scores,
    issues,
    recommended_repairs: [],
    repair_brief: "",
  };
}

function researchGrounding(ctx: EvalContext) {
  const { lesson, arxivMeta } = ctx;
  const text = lessonText(lesson);
  const abstract = arxivMeta?.abstract ?? "";
  const titleTokens = keywordTokens(lesson.title);
  const abstractTokens = keywordTokens(abstract);
  const paperTerms = distinctivePaperTerms(lesson, arxivMeta);
  const lessonTokens = new Set(keywordTokens(text));
  const titleOverlap = ratio(titleTokens.filter((t) => lessonTokens.has(t)).length, titleTokens.length);
  const abstractOverlap = ratio(abstractTokens.filter((t) => lessonTokens.has(t)).length, Math.min(25, abstractTokens.length));

  if (arxivMeta && normalizeTitle(arxivMeta.title) !== normalizeTitle(lesson.title)) {
    addIssue(ctx, "research_grounding", "blocker", undefined, "Lesson title does not match cached paper metadata.", "Restore the paper's exact title before repairing the lesson.");
  }
  if (titleOverlap < 0.45) {
    addIssue(ctx, "research_grounding", "major", undefined, "Lesson barely uses the title's specific technical vocabulary.", "Rewrite core cards around the paper's named method and contribution, not a generic topic summary.");
  }
  if (abstract && abstractOverlap < 0.26) {
    addIssue(ctx, "research_grounding", "major", undefined, "Lesson has weak overlap with the abstract's distinctive concepts.", "Ground the map, core idea, interaction, and result cards in terms from the abstract.");
  }
  for (const card of importantCards(lesson)) {
    if (countTermHits(cardText(card), paperTerms) < 2) {
      addIssue(ctx, "research_grounding", "major", cardNumber(lesson, card), "Important card does not carry enough paper-specific vocabulary.", "Rewrite this card around named mechanisms, datasets, metrics, or claims from the paper.");
    }
  }
  if (containsAny(text, genericResearchPhrases)) {
    addIssue(ctx, "research_grounding", "major", undefined, "Research framing leans on generic paper-summary phrasing.", "Replace broad claims with the exact problem, mechanism, and result from this paper.");
  }
  const invalidRelated = (lesson.related_slugs ?? []).filter((slug) => !catalogPaperIds.has(slug));
  if (invalidRelated.length > 0) {
    addIssue(ctx, "research_grounding", "major", undefined, `Related slugs are not in the generated catalog: ${invalidRelated.join(", ")}.`, "Use only readable ids already present in the catalog or leave weak relations out.");
  }
  scoreCategory(ctx, "research_grounding");
}

function beginnerMentalModel(ctx: EvalContext) {
  const { lesson } = ctx;
  const firstStory = firstCard(lesson, "story");
  const firstStoryText = cardText(firstStory);
  const glossaryTerms = new Set((lesson.glossary ?? []).flatMap((g) => keywordTokens(g.term)));
  const earlyTechnicalHits = keywordTokens(firstStoryText).filter((t) => glossaryTerms.has(t));

  if (!firstStory) {
    addIssue(ctx, "beginner_mental_model", "blocker", 2, "No opening story card exists.", "Add a jargon-light on-ramp immediately after the cover.");
  } else {
    if (/\b(neural|network|transformer|attention|diffusion|embedding|token|model|training|benchmark|architecture)\b/i.test(firstStoryText)) {
      addIssue(ctx, "beginner_mental_model", "major", cardNumber(lesson, firstStory), "Opening story uses AI terms before earning the intuition.", "Begin with a familiar situation first, then introduce the technical name on the next card.");
    }
    if (earlyTechnicalHits.length > 5) {
      addIssue(ctx, "beginner_mental_model", "major", cardNumber(lesson, firstStory), "Opening story introduces too many glossary concepts before intuition.", "Start with a concrete everyday analogy, then name the technical concept on the next card.");
    }
    if (!hasAnalogy(firstStoryText)) {
      addIssue(ctx, "beginner_mental_model", "major", cardNumber(lesson, firstStory), "Opening card lacks a relatable beginner analogy.", "Add a familiar situation that lets the learner feel the paper's problem before seeing AI jargon.");
    }
  }
  if (/openness|curiosity|alternatives|prior expertise/i.test(lesson.prerequisite_note ?? "")) {
    addIssue(ctx, "beginner_mental_model", "major", undefined, "Prerequisite note is vague rather than useful.", "Name the one concrete idea the learner should bring, for example sequences, images, feedback, or memory.");
  }
  if ((lesson.glossary ?? []).length > 6) {
    addIssue(ctx, "beginner_mental_model", "minor", undefined, "Glossary is getting crowded.", "Keep only terms that are used in the prose and matter to the mental model.");
  }
  scoreCategory(ctx, "beginner_mental_model");
}

function narrativeFlow(ctx: EvalContext) {
  const { lesson } = ctx;
  const order = lesson.cards.map((card) => card.kind).join(",");
  if (order !== EXPECTED_ORDER) {
    addIssue(ctx, "narrative_flow", "blocker", undefined, `Card order is ${order}.`, `Use the expected order: ${EXPECTED_ORDER}.`);
  }
  const titles = lesson.cards.map((card) => normalizeTitle(card.title));
  if (new Set(titles).size !== titles.length) {
    addIssue(ctx, "narrative_flow", "major", undefined, "Some card titles repeat or blur together.", "Give every card a distinct job in the story: problem, mechanism, tradeoff, result, takeaway.");
  }
  const genericTitles = lesson.cards
    .map((card, index) => ({ card, index }))
    .filter(({ card }) => containsAny(card.title, genericTitlePhrases));
  for (const { card, index } of genericTitles.slice(0, 3)) {
    addIssue(ctx, "narrative_flow", "minor", index + 1, `Generic card title: "${card.title}".`, "Replace the title with a concrete claim about this paper's move.");
  }
  const core = lesson.cards.find((card) => card.kicker?.toLowerCase() === "core idea");
  if (core && !mentionsPaperMove(lesson, cardText(core))) {
    addIssue(ctx, "narrative_flow", "major", cardNumber(lesson, core), "Core idea card does not clearly name the paper's specific mechanism.", "Make the card answer: what new move did this paper add?");
  }
  const firstThree = lesson.cards.slice(0, 3).map(cardText).join(" ");
  if (!/\?/.test(firstThree) && !/\b(problem|stuck|hard|fails|cost|gap|puzzle|wall)\b/i.test(firstThree)) {
    addIssue(ctx, "narrative_flow", "major", 2, "Opening arc does not pose a crisp learning tension.", "Make the first story ask a concrete question or name the obstacle the paper solves.");
  }
  scoreCategory(ctx, "narrative_flow");
}

function interactionDesign(ctx: EvalContext) {
  const { lesson } = ctx;
  const terms = distinctivePaperTerms(lesson, ctx.arxivMeta);
  const compare = firstCard(lesson, "compare");
  const slider = firstCard(lesson, "slider");
  const chooser = firstCard(lesson, "chooser");
  const results = firstCard(lesson, "results");

  if (!compare?.offLabel || !compare.onLabel || !compare.offNote || !compare.onNote) {
    addIssue(ctx, "interaction_design", "blocker", cardNumber(lesson, compare), "Compare interaction is incomplete.", "Fill both labels and notes with an old-way versus paper-way contrast.");
  } else if (containsAny(cardText(compare), genericInteractionPhrases) || countTermHits(cardText(compare), terms) < 2) {
    addIssue(ctx, "interaction_design", "major", cardNumber(lesson, compare), "Compare interaction feels generic.", "Make the toggle demonstrate the paper's central before/after change.");
  }

  if (!slider?.low || !slider.mid || !slider.high) {
    addIssue(ctx, "interaction_design", "blocker", cardNumber(lesson, slider), "Slider interaction is incomplete.", "Give low, mid, and high states that teach a real paper-specific tradeoff.");
  } else if (containsAny(cardText(slider), ["speed holds up", "tradeoff", "computation time", "as the sequence grows"]) || countTermHits(cardText(slider), terms) < 2) {
    addIssue(ctx, "interaction_design", "major", cardNumber(lesson, slider), "Slider uses a generic tradeoff template.", "Tie the slider to the paper's own knob, such as retrieval depth, mask quality, prompt strength, memory span, or guidance scale.");
  }

  if (chooser?.choices?.length !== 6) {
    addIssue(ctx, "interaction_design", "blocker", cardNumber(lesson, chooser), "Chooser does not have exactly six choices.", "Add six ingredients, each with a concise paper-specific role.");
  } else {
    const labels = chooser.choices.map((choice) => normalizeTitle(choice.label));
    if (new Set(labels).size !== labels.length) {
      addIssue(ctx, "interaction_design", "major", cardNumber(lesson, chooser), "Chooser labels repeat.", "Make each ingredient distinct.");
    }
    const weakChoices = chooser.choices.filter((choice) => containsAny(choice.label + " " + choice.note, genericInteractionPhrases));
    if (weakChoices.length >= 3) {
      addIssue(ctx, "interaction_design", "major", cardNumber(lesson, chooser), "Chooser contains too many generic ingredients.", "Replace generic items with mechanisms that only make sense for this paper.");
    }
    if (countTermHits(cardText(chooser), terms) < 3) {
      addIssue(ctx, "interaction_design", "major", cardNumber(lesson, chooser), "Chooser does not teach enough paper-specific ingredients.", "Make at least three choices concrete mechanisms from the paper.");
    }
  }

  if (!results?.bars || results.bars.length < 3) {
    addIssue(ctx, "interaction_design", "blocker", cardNumber(lesson, results), "Results card lacks enough result bars.", "Add three to five result bars tied to concrete comparisons or findings.");
  } else if (results.bars.some((bar) => /metric|comparison|impact|result/i.test(bar.label))) {
    addIssue(ctx, "interaction_design", "major", cardNumber(lesson, results), "Result bars use placeholder labels.", "Name the actual benchmark, behavior, or comparison each bar represents.");
  } else if (countTermHits(cardText(results), terms) < 2) {
    addIssue(ctx, "interaction_design", "major", cardNumber(lesson, results), "Results card is not grounded in the paper's distinctive claims.", "Tie the result bars to the actual comparison, capability, or experiment the paper reports.");
  }
  scoreCategory(ctx, "interaction_design");
}

function aprecisStyle(ctx: EvalContext) {
  const { lesson } = ctx;
  const text = JSON.stringify(lesson);
  if (/—|–|\\u2014|\\u2013/i.test(text)) {
    addIssue(ctx, "aprecis_style", "blocker", undefined, "Lesson contains a forbidden dash character or escape.", "Rewrite with commas, periods, colons, parentheses, or a middle dot.");
  }
  if (containsAny(text, weakStylePhrases)) {
    addIssue(ctx, "aprecis_style", "major", undefined, "Lesson contains weak Aprecis copy patterns.", "Cut abstract hype and write concrete, beginner-first prose.");
  }
  if (/Imagine\b[\s\S]{0,120}\b(neural networks|models|Transformers|diffusion|attention)\b/i.test(text)) {
    addIssue(ctx, "aprecis_style", "major", undefined, "Analogy collapses into AI explanation too quickly.", "Let the analogy stand on its own before revealing the technical mapping.");
  }
  for (const [index, card] of lesson.cards.entries()) {
    for (const paragraph of card.body ?? []) {
      const words = wordCount(paragraph);
      if (words < 9 && card.kind !== "cover") {
        addIssue(ctx, "aprecis_style", "minor", index + 1, "Paragraph is too thin to teach.", "Expand it into one concrete idea, not a label.");
      }
      if (words > 34) {
        addIssue(ctx, "aprecis_style", "minor", index + 1, "Paragraph is too long for swipe-card reading.", "Split or tighten the paragraph to one crisp thought.");
      }
    }
  }
  scoreCategory(ctx, "aprecis_style");
}

function mobileFit(ctx: EvalContext) {
  const { lesson, html } = ctx;
  for (const [index, card] of lesson.cards.entries()) {
    if (card.title.length > 72) {
      addIssue(ctx, "mobile_fit", "minor", index + 1, "Card title is likely too long on mobile.", "Shorten the title or move detail into body text.");
    }
    for (const choice of card.choices ?? []) {
      if (choice.label.length > 30) {
        addIssue(ctx, "mobile_fit", "minor", index + 1, "Chooser label may wrap awkwardly.", "Use a shorter label and keep the explanation in the note.");
      }
    }
  }
  if (!html) {
    addIssue(ctx, "mobile_fit", "major", undefined, "Rendered HTML is missing.", "Rerender the lesson before publishing or reviewing visually.");
  } else {
    if (!html.includes("viewport-fit=cover")) addIssue(ctx, "mobile_fit", "minor", undefined, "HTML does not declare viewport-fit.", "Keep the bundle compatible with safe-area rendering.");
    if (!html.includes("flex:1;min-height:0") && !html.includes("flex:1; min-height:0")) {
      addIssue(ctx, "mobile_fit", "major", undefined, "HTML may use a clipped viewport shell.", "Use the flex shell pattern so the bottom button remains visible in WKWebView.");
    }
  }
  scoreCategory(ctx, "mobile_fit");
}

function sourceIntegrity(ctx: EvalContext) {
  const { lesson, arxivMeta } = ctx;
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(lesson.paper_id)) {
    addIssue(ctx, "source_integrity", "blocker", undefined, "paper_id is not a readable slug.", "Use a clean readable id and keep scholarly identity in arxiv_id or canonical_key.");
  }
  if (!lesson.arxiv_id || !lesson.url?.includes(lesson.arxiv_id)) {
    addIssue(ctx, "source_integrity", "blocker", undefined, "Source URL and arXiv id do not line up.", "Correct arxiv_id and url before any content repair.");
  }
  if (arxivMeta && arxivMeta.year !== lesson.year) {
    addIssue(ctx, "source_integrity", "major", undefined, "Lesson year differs from metadata year.", "Use the cached metadata year.");
  }
  if (!lesson.authors || lesson.authors.trim().length < 4) {
    addIssue(ctx, "source_integrity", "major", undefined, "Lesson is missing an author string.", "Populate authors from metadata or curated fallback before publishing.");
  }
  const source = lesson.cards.find((card) => card.kind === "source");
  if (!source || normalizeTitle(source.title) !== normalizeTitle(lesson.title)) {
    addIssue(ctx, "source_integrity", "major", cardNumber(lesson, source), "Source card title does not match lesson title.", "Use the exact paper title on the source card.");
  }
  scoreCategory(ctx, "source_integrity");
}

type EvalContext = {
  lesson: Lesson;
  arxivMeta: ArxivMeta | null;
  html: string | null;
  category_scores: Record<Specialist, CategoryScore>;
  issues: LessonIssue[];
};

function addIssue(
  ctx: EvalContext,
  specialist: Specialist,
  severity: Severity,
  card: number | undefined,
  finding: string,
  repair: string,
) {
  ctx.issues.push({ specialist, severity, card, finding, repair });
  ctx.category_scores[specialist].notes.push(finding);
}

function scoreCategory(ctx: EvalContext, specialist: Specialist) {
  const relevant = ctx.issues.filter((issue) => issue.specialist === specialist);
  const penalty = relevant.reduce((sum, issue) => sum + severityPenalty(issue.severity), 0);
  ctx.category_scores[specialist].score = clamp(100 - penalty, 0, 100);
}

function finalizeReport(report: LessonReport) {
  const scores = Object.entries(report.category_scores)
    .filter(([key]) => key !== "llm_critic")
    .map(([, value]) => value.score);
  const raw = scores.reduce((sum, score) => sum + score, 0) / Math.max(1, scores.length);
  const blockerCount = report.issues.filter((issue) => issue.severity === "blocker").length;
  const majorCount = report.issues.filter((issue) => issue.severity === "major").length;
  const issuePenalty = blockerCount * 9 + majorCount * 3;
  report.score = Math.round(clamp(raw - issuePenalty, 0, 100));
  report.grade = report.score >= 90 && blockerCount === 0
    ? "ship"
    : report.score >= 78 && blockerCount === 0
    ? "polish"
    : report.score >= 60
    ? "repair"
    : "rebuild";
  report.blocking_issues = report.issues
    .filter((issue) => issue.severity === "blocker")
    .map((issue) => issue.finding);
  report.recommended_repairs = report.issues
    .filter((issue) => issue.severity !== "minor")
    .slice(0, 8)
    .map((issue) => issue.card ? `Card ${issue.card}: ${issue.repair}` : issue.repair);
  if (report.recommended_repairs.length === 0) {
    report.recommended_repairs = report.issues.slice(0, 5).map((issue) => issue.repair);
  }
  report.repair_brief = renderRepairBrief(report);
}

function buildIndex(reports: LessonReport[]): IndexReport {
  const grade_counts = { ship: 0, polish: 0, repair: 0, rebuild: 0 };
  for (const report of reports) grade_counts[report.grade]++;
  return {
    generated_at: new Date().toISOString(),
    batch,
    lesson_count: reports.length,
    average_score: round1(reports.reduce((sum, report) => sum + report.score, 0) / Math.max(1, reports.length)),
    grade_counts,
    worst: reports.slice(0, 15).map(({ paper_id, title, score, grade }) => ({ paper_id, title, score, grade })),
    reports: reports.map((report) => ({
      paper_id: report.paper_id,
      score: report.score,
      grade: report.grade,
      path: `${reportDir}/${reportFileName(report.paper_id)}`,
    })),
  };
}

function reportFileName(paperId: string): string {
  return args.papers.size ? `${paperId}.selected.json` : `${paperId}.json`;
}

function renderRepairQueue(reports: LessonReport[]): string {
  const lines = [
    `# Lesson Repair Queue`,
    ``,
    `Generated: ${new Date().toISOString()}`,
    `Batch: ${batch}`,
    ``,
  ];
  for (const report of reports) {
    lines.push(`## ${report.score} · ${report.grade} · ${report.paper_id}`);
    lines.push(``);
    lines.push(report.title);
    lines.push(``);
    for (const repair of report.recommended_repairs.slice(0, 6)) {
      lines.push(`- ${repair}`);
    }
    lines.push(``);
  }
  return lines.join("\n");
}

function renderRepairBrief(report: LessonReport): string {
  const topIssues = report.issues
    .filter((issue) => issue.severity !== "minor")
    .slice(0, 6)
    .map((issue) => `${issue.card ? `Card ${issue.card}: ` : ""}${issue.finding} Repair: ${issue.repair}`)
    .join("\n");
  return [
    `Repair ${report.paper_id}: ${report.title}`,
    `Current score: ${report.score}`,
    `Goal: 90+ with no blocker issues.`,
    `Keep the existing schema and card order.`,
    `Preserve exact title, arxiv_id, url, year, and readable paper_id.`,
    `Never use em dashes or en dashes in user-facing copy.`,
    `Primary issues:`,
    topIssues || "No major issues. Polish specificity, rhythm, and interaction teaching value.",
  ].join("\n");
}

async function critiqueWithLlm(lesson: Lesson, arxivMeta: ArxivMeta | null): Promise<Record<string, unknown>> {
  const apiKey = await loadOpenAIKey();
  if (!apiKey) {
    throw new Error("Missing OPENAI_API_KEY. Run without --llm or add it to .env.local.");
  }
  const prompt = {
    task: "Critique this Aprecis web lesson as specialist curriculum agents.",
    rubric: [
      "research fidelity to the paper",
      "beginner mental model and on-ramp",
      "narrative order",
      "interaction teaching value",
      "Aprecis voice and specificity",
    ],
    output: {
      score: "0 to 100",
      blocking_issues: ["short issue strings"],
      repairs: ["actionable repair strings"],
      category_notes: ["short notes"],
    },
    paper_metadata: arxivMeta,
    lesson,
  };
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "You are a strict senior learning designer for Aprecis. Return only JSON. Be concrete, skeptical, and repair-oriented.",
        },
        { role: "user", content: JSON.stringify(prompt) },
      ],
      response_format: { type: "json_object" },
      temperature: 0.2,
      max_tokens: 1800,
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message ?? `OpenAI error ${res.status}`);
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI returned no critique content");
  return JSON.parse(content) as Record<string, unknown>;
}

function mergeLlmCritique(report: LessonReport, critique: Record<string, unknown>) {
  const score = typeof critique.score === "number" ? critique.score : undefined;
  const notes = arrayOfStrings(critique.category_notes);
  const blocking = arrayOfStrings(critique.blocking_issues);
  const repairs = arrayOfStrings(critique.repairs);
  report.llm = { model: MODEL, raw_score: score, notes };
  report.category_scores.llm_critic = {
    score: typeof score === "number" ? clamp(Math.round(score), 0, 100) : 75,
    notes: [...notes, ...blocking],
  };
  for (const issue of blocking.slice(0, 6)) {
    report.issues.push({
      specialist: "llm_critic",
      severity: "major",
      finding: issue,
      repair: repairs.shift() ?? "Repair this issue with a paper-specific rewrite.",
    });
  }
  for (const repair of repairs.slice(0, 4)) {
    report.issues.push({
      specialist: "llm_critic",
      severity: "minor",
      finding: "LLM critic suggested a polish repair.",
      repair,
    });
  }
}

function emptyCategoryScores(): Record<Specialist, CategoryScore> {
  return {
    research_grounding: { score: 100, notes: [] },
    beginner_mental_model: { score: 100, notes: [] },
    narrative_flow: { score: 100, notes: [] },
    interaction_design: { score: 100, notes: [] },
    aprecis_style: { score: 100, notes: [] },
    mobile_fit: { score: 100, notes: [] },
    source_integrity: { score: 100, notes: [] },
    llm_critic: { score: 100, notes: [] },
  };
}

function parseArgs(raw: string[]) {
  const papers = new Set<string>();
  const flags = new Set<string>();
  let batch: string | undefined;
  let limit: number | undefined;
  for (let i = 0; i < raw.length; i++) {
    const arg = raw[i];
    if (arg === "--llm") flags.add("llm");
    else if (arg === "--batch") batch = raw[++i];
    else if (arg.startsWith("--batch=")) batch = arg.split("=")[1];
    else if (arg === "--paper") papers.add(raw[++i]);
    else if (arg.startsWith("--paper=")) papers.add(arg.split("=")[1]);
    else if (arg === "--limit") limit = Number(raw[++i]);
    else if (arg.startsWith("--limit=")) limit = Number(arg.split("=")[1]);
  }
  return { batch, papers, flags, limit };
}

async function loadOpenAIKey(): Promise<string | null> {
  const fromEnv = Deno.env.get("OPENAI_API_KEY");
  if (fromEnv) return fromEnv;
  const local = await readTextIfExists(`${ROOT}/backend/.env.local`) ?? await readTextIfExists(`${ROOT}/.env.local`);
  if (!local) return null;
  const match = local.match(/^OPENAI_API_KEY=(.+)$/m);
  return match?.[1]?.trim().replace(/^["']|["']$/g, "") ?? null;
}

async function readJsonIfExists<T>(path: string): Promise<T | null> {
  try {
    return JSON.parse(await Deno.readTextFile(path)) as T;
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) return null;
    throw err;
  }
}

async function readTextIfExists(path: string): Promise<string | null> {
  try {
    return await Deno.readTextFile(path);
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) return null;
    throw err;
  }
}

function normalizeGeneratedPath(path: string): string {
  return path.replace(`${ROOT}//`, `${ROOT}/`);
}

function firstCard(lesson: Lesson, kind: LessonKind): LessonCard | undefined {
  return lesson.cards.find((card) => card.kind === kind);
}

function cardNumber(lesson: Lesson, card: LessonCard | undefined): number | undefined {
  if (!card) return undefined;
  const index = lesson.cards.indexOf(card);
  return index >= 0 ? index + 1 : undefined;
}

function cardText(card: LessonCard | undefined): string {
  if (!card) return "";
  return [
    card.kicker,
    card.title,
    ...(card.body ?? []),
    card.caption,
    card.left,
    card.middle,
    card.right,
    card.offLabel,
    card.onLabel,
    card.offNote,
    card.onNote,
    card.low,
    card.mid,
    card.high,
    ...(card.choices ?? []).flatMap((choice) => [choice.label, choice.note]),
    ...(card.bars ?? []).flatMap((bar) => [bar.label, bar.note]),
    ...(card.recap ?? []).flatMap((item) => [item.label, item.note]),
  ].filter(Boolean).join(" ");
}

function lessonText(lesson: Lesson): string {
  return [
    lesson.title,
    lesson.hook,
    lesson.promise,
    lesson.prerequisite_note,
    ...(lesson.glossary ?? []).flatMap((g) => [g.term, g.plain]),
    ...lesson.cards.map(cardText),
  ].join(" ");
}

function keywordTokens(text: string): string[] {
  const stop = new Set([
    "about",
    "after",
    "again",
    "also",
    "and",
    "are",
    "because",
    "but",
    "can",
    "each",
    "every",
    "from",
    "has",
    "have",
    "how",
    "into",
    "its",
    "more",
    "most",
    "not",
    "only",
    "paper",
    "than",
    "that",
    "the",
    "their",
    "then",
    "this",
    "through",
    "using",
    "when",
    "where",
    "with",
    "without",
    "your",
  ]);
  return text.toLowerCase()
    .replace(/[^a-z0-9+.-]+/g, " ")
    .split(/\s+/)
    .filter((token) => token.length > 3 && !stop.has(token))
    .slice(0, 260);
}

function mentionsPaperMove(lesson: Lesson, text: string): boolean {
  const titleTokens = new Set(keywordTokens(lesson.title));
  return keywordTokens(text).some((token) => titleTokens.has(token));
}

function importantCards(lesson: Lesson): LessonCard[] {
  return lesson.cards.filter((card) => ["map", "compare", "slider", "chooser", "results"].includes(card.kind));
}

function distinctivePaperTerms(lesson: Lesson, arxivMeta: ArxivMeta | null): Set<string> {
  const generic = new Set([
    "model",
    "models",
    "neural",
    "network",
    "networks",
    "learning",
    "training",
    "sequence",
    "sequences",
    "image",
    "images",
    "language",
    "efficient",
    "performance",
    "generation",
    "generative",
    "representation",
    "representations",
  ]);
  const source = [
    lesson.title,
    arxivMeta?.title ?? "",
    arxivMeta?.abstract ?? "",
    ...(lesson.glossary ?? []).map((term) => term.term),
  ].join(" ");
  return new Set(keywordTokens(source).filter((token) => !generic.has(token)).slice(0, 42));
}

function countTermHits(text: string, terms: Set<string>): number {
  const tokens = new Set(keywordTokens(text));
  let hits = 0;
  for (const term of terms) {
    if (tokens.has(term)) hits++;
  }
  return hits;
}

function hasAnalogy(text: string): boolean {
  return /\b(imagine|like|as if|think of|picture|pretend|you are|you have|reading|teacher|map|library|kitchen|game|book|photo|conversation)\b/i.test(text);
}

function containsAny(text: string, phrases: string[]): boolean {
  const lower = text.toLowerCase();
  return phrases.some((phrase) => lower.includes(phrase.toLowerCase()));
}

function normalizeTitle(title: string | undefined): string {
  return (title ?? "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function ratio(a: number, b: number): number {
  return b <= 0 ? 1 : a / b;
}

function wordCount(text: string): number {
  return text.split(/\s+/).filter(Boolean).length;
}

function severityPenalty(severity: Severity): number {
  if (severity === "blocker") return 45;
  if (severity === "major") return 28;
  return 12;
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function round1(value: number): number {
  return Math.round(value * 10) / 10;
}

function arrayOfStrings(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === "string") : [];
}
