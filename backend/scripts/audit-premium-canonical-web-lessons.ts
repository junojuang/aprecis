/**
 * Audit generated canonical web lessons for Aprecis quality gates.
 *
 * Run from repo root:
 *   deno run --allow-read backend/scripts/audit-premium-canonical-web-lessons.ts
 */

type LessonCard = {
  kind: string;
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
  hook: string;
  promise: string;
  glossary: Array<{ term: string; plain: string }>;
  cards: LessonCard[];
};

const ROOT = new URL("../../", import.meta.url).pathname.replace(/\/backend\/$/, "");
const CACHE_DIR = `${ROOT}/data/generated/canonical-50`;
const HTML_DIR = `${ROOT}/prototypes/web-lesson/canonical-50`;
const EXPECTED_ORDER = "cover,story,map,compare,story,slider,chooser,results,story,recap,source";
const weakPhrases = [
  "this paper shows",
  "this paper introduces",
  "this paper presents",
  "the paper shows",
  "the paper introduces",
  "in conclusion",
  "it is important",
  "various tasks",
  "many applications",
  "significant improvement",
  "state-of-the-art",
];

const issues: string[] = [];
let count = 0;
let htmlCount = 0;

for await (const entry of Deno.readDir(CACHE_DIR)) {
  if (!entry.isFile || !entry.name.endsWith(".json")) continue;
  if (entry.name === "manifest.json" || entry.name.endsWith(".arxiv.json")) continue;
  const path = `${CACHE_DIR}/${entry.name}`;
  const lesson = JSON.parse(await Deno.readTextFile(path)) as Lesson;
  count++;
  auditLesson(lesson, path);
  const htmlPath = `${HTML_DIR}/${lesson.paper_id}.html`;
  try {
    const html = await Deno.readTextFile(htmlPath);
    htmlCount++;
    auditHtml(lesson, html, htmlPath);
  } catch {
    issues.push(`${lesson.paper_id}: missing HTML ${htmlPath}`);
  }
}

const manifestPath = `${CACHE_DIR}/manifest.json`;
try {
  const manifest = JSON.parse(await Deno.readTextFile(manifestPath)) as Array<{ paper_id: string }>;
  if (manifest.length !== 50) issues.push(`manifest has ${manifest.length} entries, expected 50`);
  const ids = new Set(manifest.map((m) => m.paper_id));
  if (ids.size !== manifest.length) issues.push("manifest contains duplicate paper_id values");
} catch {
  issues.push("missing manifest.json");
}

console.log(`audited lessons=${count} html=${htmlCount}`);
if (issues.length) {
  console.error(`\n${issues.length} issue(s):`);
  for (const issue of issues) console.error(`- ${issue}`);
  Deno.exit(1);
}
console.log("QA passed");

function auditLesson(lesson: Lesson, path: string) {
  const id = lesson.paper_id || path;
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) issues.push(`${id}: paper_id is not a readable slug`);
  if (!lesson.title || lesson.title.length < 8) issues.push(`${id}: missing title`);
  if (!lesson.short_name || lesson.short_name.length < 2) issues.push(`${id}: missing short_name`);
  if (!lesson.hook || lesson.hook.split(/\s+/).length < 6) issues.push(`${id}: hook too short`);
  if (!lesson.promise || lesson.promise.split(/\s+/).length < 8) issues.push(`${id}: promise too short`);
  if (!Array.isArray(lesson.glossary) || lesson.glossary.length < 4) issues.push(`${id}: glossary too thin`);
  if (!Array.isArray(lesson.cards) || lesson.cards.length !== 11) issues.push(`${id}: expected 11 cards`);
  const order = lesson.cards.map((c) => c.kind).join(",");
  if (order !== EXPECTED_ORDER) issues.push(`${id}: wrong card order ${order}`);

  const text = JSON.stringify(lesson);
  if (/—|–|\\u2014|\\u2013/i.test(text)) issues.push(`${id}: forbidden dash`);
  for (const phrase of weakPhrases) {
    if (text.toLowerCase().includes(phrase)) issues.push(`${id}: weak phrase "${phrase}"`);
  }

  const map = lesson.cards.find((c) => c.kind === "map");
  if (!map?.left || !map.middle || !map.right || new Set([map.left, map.middle, map.right]).size < 3) {
    issues.push(`${id}: map labels are missing or repetitive`);
  }

  const compare = lesson.cards.find((c) => c.kind === "compare");
  if (!compare?.offLabel || !compare.onLabel || !compare.offNote || !compare.onNote) {
    issues.push(`${id}: compare card incomplete`);
  }

  const slider = lesson.cards.find((c) => c.kind === "slider");
  if (!slider?.low || !slider.mid || !slider.high) issues.push(`${id}: slider card incomplete`);

  const chooser = lesson.cards.find((c) => c.kind === "chooser");
  if (chooser?.choices?.length !== 6) issues.push(`${id}: chooser does not have 6 choices`);
  if (chooser?.choices && new Set(chooser.choices.map((c) => c.label.toLowerCase())).size !== chooser.choices.length) {
    issues.push(`${id}: chooser labels repeat`);
  }

  const results = lesson.cards.find((c) => c.kind === "results");
  if (!results?.bars || results.bars.length < 3 || results.bars.length > 5) issues.push(`${id}: result bars count invalid`);
  for (const bar of results?.bars ?? []) {
    if (typeof bar.value !== "number" || bar.value < 10 || bar.value > 100) issues.push(`${id}: invalid result bar value`);
    if (!bar.label || !bar.note) issues.push(`${id}: result bar missing label or note`);
  }

  const recap = lesson.cards.find((c) => c.kind === "recap");
  if (recap?.recap?.length !== 4) issues.push(`${id}: recap does not have 4 items`);

  for (const card of lesson.cards) {
    if (!card.title || card.title.length < 4) issues.push(`${id}: card missing title`);
    for (const paragraph of card.body ?? []) {
      const words = paragraph.split(/\s+/).filter(Boolean).length;
      if (words < 6) issues.push(`${id}: very short paragraph "${paragraph}"`);
      if (words > 38) issues.push(`${id}: long paragraph in ${card.kind}`);
    }
  }
}

function auditHtml(lesson: Lesson, html: string, path: string) {
  if (/—|–|\\u2014|\\u2013/i.test(html)) issues.push(`${lesson.paper_id}: forbidden dash in HTML`);
  if (!html.includes("id=\"lesson-data\"")) issues.push(`${lesson.paper_id}: missing embedded lesson data`);
  if (!html.includes("Aprecis.openOriginal")) issues.push(`${lesson.paper_id}: missing original-paper bridge`);
  if (!html.includes(lesson.title.replace(/&/g, "&amp;").slice(0, 12)) && !html.includes(lesson.title.slice(0, 12))) {
    issues.push(`${lesson.paper_id}: HTML title mismatch at ${path}`);
  }
}
