/**
 * Supabase Edge Function: serve-cards
 * Public API consumed by the iOS app.
 *
 * GET /serve-cards?page=0&limit=20        → paginated feed (includes score + published_at from papers)
 * POST /serve-cards/interaction           → log swipe/save/share
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const url = new URL(req.url);
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });

  try {
    // POST /serve-cards/interaction
    if (req.method === "POST" && url.pathname.endsWith("/interaction")) {
      const body = await req.json();
      const { paper_id, action, timestamp } = body;

      if (!paper_id || !action) {
        return json({ error: "Missing paper_id or action" }, 400);
      }

      const { error } = await supabase.from("user_interactions").insert({
        paper_id,
        action,
        interacted_at: timestamp ?? new Date().toISOString(),
      });

      if (error) throw error;
      return json({ ok: true });
    }

    // GET /serve-cards
    if (req.method === "GET") {
      const page  = parseInt(url.searchParams.get("page")  ?? "0");
      const limit = Math.min(parseInt(url.searchParams.get("limit") ?? "20"), 50);
      const offset = page * limit;

      // Join cards → papers to pull score + published_at up to the top level
      const { data: rawDecks, error, count } = await supabase
        .from("cards")
        .select(
          `
          paper_id,
          title,
          source,
          url,
          cards,
          created_at,
          papers!inner (
            score,
            published_at
          )
        `,
          { count: "exact" }
        )
        .order("created_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) throw error;

      // Flatten score and published_at to the top level of each deck object
      const decks = (rawDecks ?? []).map((deck: any) => {
        const { papers, ...rest } = deck;
        return {
          ...rest,
          score:        papers?.score        ?? null,
          published_at: papers?.published_at ?? null,
        };
      });

      return json({
        decks,
        page,
        has_more: (count ?? 0) > offset + limit,
      });
    }

    return json({ error: "Not found" }, 404);
  } catch (err) {
    console.error("[serve-cards] Error:", err);
    return json({ error: String(err) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
