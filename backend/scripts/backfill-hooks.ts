/**
 * Backfill hooks for existing cards that were processed before hook was saved.
 * Only calls the LLM once per paper (just the hook field), cheap.
 *
 * Usage:
 *   cd backend
 *   deno run --allow-net --allow-env --allow-read scripts/backfill-hooks.ts
 */

import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";
await load({ envPath: ".env.local", export: true, allowEmptyValues: true });

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.3";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const ANTHROPIC_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? Deno.env.get("OPENAI_API_KEY");

if (!SUPABASE_URL || !SUPABASE_KEY) { console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY"); Deno.exit(1); }
if (!ANTHROPIC_KEY) { console.error("Missing ANTHROPIC_API_KEY"); Deno.exit(1); }

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
const anthropic = new Anthropic({ apiKey: ANTHROPIC_KEY });

// Fetch cards that have no hook yet
const { data: cards, error } = await supabase
  .from("cards")
  .select("paper_id, title, cards")
  .filter("cards->>hook", "is", null);

if (error) { console.error("Query failed:", error.message); Deno.exit(1); }
console.log(`Found ${cards?.length ?? 0} cards missing hooks`);

// Fetch abstracts for all those paper_ids
const paperIds = (cards ?? []).map((c: any) => c.paper_id);
const { data: papers } = await supabase
  .from("papers")
  .select("paper_id, abstract")
  .in("paper_id", paperIds);

const abstractMap = new Map((papers ?? []).map((p: any) => [p.paper_id, p.abstract]));

let updated = 0;
let failed = 0;

for (const card of (cards ?? [])) {
  const abstract = abstractMap.get(card.paper_id) ?? "";
  const title = card.title ?? "";

  try {
    const msg = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 60,
      messages: [{
        role: "user",
        content: `Write a hook for this AI research paper. 10-14 words. Punchy present-tense statement that makes someone stop scrolling. Reveals the surprising insight. Never starts with "This paper". Return only the hook text, no quotes.

Title: ${title}
Abstract: ${abstract.slice(0, 400)}`,
      }],
    });

    const hook = (msg.content[0] as any).text?.trim();
    if (!hook) throw new Error("empty response");

    const updatedCards = { ...card.cards, hook };
    const { error: updateError } = await supabase
      .from("cards")
      .update({ cards: updatedCards })
      .eq("paper_id", card.paper_id);

    if (updateError) throw new Error(updateError.message);

    console.log(`✓ ${card.paper_id.slice(0, 40).padEnd(40)} → "${hook}"`);
    updated++;
  } catch (err) {
    console.error(`✗ ${card.paper_id}: ${err}`);
    failed++;
  }
}

console.log(`\nDone: ${updated} updated, ${failed} failed`);
