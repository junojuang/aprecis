/**
 * Supabase Edge Function: delete-account
 * POST  (Authorization: Bearer <user access token>)
 *
 * Permanently deletes the calling user's account. The caller is identified
 * solely from their JWT, so a user can only ever delete themselves.
 *
 * Deleting the auth.users row cascades to public.profiles
 * (id references auth.users(id) on delete cascade). The user_interactions
 * table holds no user identifier, so nothing else is tied to the account.
 *
 * Required for App Store Guideline 5.1.1(v): in-app account deletion.
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // ── 1. Identify the caller from their access token ───────────────────────────
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return json({ error: "Missing access token" }, 401);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) {
    return json({ error: "Invalid or expired session" }, 401);
  }
  const userId = userData.user.id;

  // ── 2. Delete the user with the service role (cascades to profiles) ──────────
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const { error: delErr } = await admin.auth.admin.deleteUser(userId);
  if (delErr) {
    console.error(`[delete-account] failed for ${userId}:`, delErr.message);
    return json({ error: "Could not delete account. Try again." }, 500);
  }

  console.log(`[delete-account] deleted user ${userId}`);
  return json({ deleted: true });
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
