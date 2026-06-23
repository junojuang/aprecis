# Web-lesson channel

Author premium, bespoke lessons as self-contained web bundles, push them to the
server, and have them appear as a new paper **with no App Store update**. The
app renders the bundle full-screen in a `WKWebView` (`WebLessonView.swift`) that
looks and behaves like the native reader.

## Why this exists

Native bespoke lessons (`*Lesson.swift` + `*Interactive.swift`) are compiled
into the binary, so a new one requires a TestFlight build + review. A web bundle
is data: write it, upload it, point a column at it, done.

## Files

| File | Role |
|---|---|
| `grokking-premium.html` | Reference lesson. Pixel-faithful port of the native Grokking lesson. **Copy this to start a new lesson.** |
| `flashattention.html` | Bespoke systems lesson for FlashAttention, with custom memory-traffic, tiling, online-softmax, and memory-receipt interactives. |
| `kit/aprecis-sdk.js` | Shared native↔web bridge + glossary + card-shell engine (`Aprecis.mount`). |
| `grokking-full.html`, `grokking.html` | Earlier prototypes, kept for reference only. |

The reference lesson currently embeds its CSS and shell inline so it runs
standalone in any browser. Once a second lesson exists, lift the `<style>` block
into `kit/aprecis-kit.css` and the shell into `aprecis-sdk.js` so each lesson is
just content.

## The bridge (what the app understands)

The bundle calls these; `WebLessonView.swift` handles them natively:

```js
Aprecis.haptic("soft");   // soft|light|medium|heavy|rigid|select|success|warning|error
Aprecis.markDone();        // mark this paper complete (streak / daily goal)
Aprecis.finish();          // mark complete + dismiss the reader
Aprecis.close();           // dismiss the reader
Aprecis.openOriginal("https://arxiv.org/abs/2201.02177"); // in-app browser
```

Open `grokking-premium.html` in **Safari** (not Chrome) to judge type, the serif
resolves to New York via `ui-serif`, matching the app.

## Example: publish FlashAttention

```bash
cd backend
deno run --allow-net --allow-env --allow-read scripts/set-web-lesson.ts \
  --loop loop:systems:flashattention \
  --file ../prototypes/web-lesson/flashattention.html \
  --slug flashattention \
  --title "FlashAttention" \
  --canonical-key arxiv:2205.14135 \
  --topic Systems \
  --year 2022 \
  --url https://arxiv.org/abs/2205.14135 \
  --arxiv-id 2205.14135
```

Then deploy the Edge Function so existing app binaries see catalog-only web
lessons in feed/search:

```bash
npx supabase functions deploy serve-cards
```

## Authoring a new lesson

1. `cp grokking-premium.html <slug>.html`.
2. Edit the `CARDS` array: cover, prose, illustrated, interactive studios,
   recap, paper link. Reuse the studio patterns or write new Canvas/SVG ones.
3. Keep the design tokens and card classes intact so it matches the app.
4. Test in Safari at iPhone width.

## Deploying (no app update)

### Mental model

There are two separate jobs:

- **Renderable**: the app can open the paper id and load its HTML bundle.
- **Discoverable**: the app can find that paper in feed/search.
- **Connectable**: the app can show Builds on / Led to / Adjacent rails for it.

For a brand-new web-only paper, `paper_catalog.web_lesson_url` provides the
render URL, and the deployed `serve-cards` catalog fallback turns that catalog
row into a lightweight `CardDeck` for feed/search. The publish script also seeds
the canonical arXiv graph row when `--arxiv-id` is provided, and
`serve-cards/related` resolves the app-facing `loop:` id to that graph row.
That is what lets the current App Store binary show connection rails for a new
web bundle. For an existing ingested paper with a `cards` row, you can still set
`cards.web_lesson_url` or `paper_catalog.web_lesson_url` to upgrade the reader.

1. Create a public Storage bucket once:
   ```sql
   insert into storage.buckets (id, name, public) values ('web-lessons', 'web-lessons', true);
   ```
2. Upload the bundle (Dashboard → Storage, or CLI):
   ```bash
   supabase storage cp ./grokking-premium.html \
     ss:///web-lessons/grokking/index.html
   ```
3. Point the paper at it. For brand-new web-only lessons, use
   `backend/scripts/set-web-lesson.ts`; it uploads the file and writes
   `paper_catalog.web_lesson_url`, which `serve-cards` exposes as a lightweight
   searchable deck. Include `--arxiv-id` whenever possible so the same command
   also seeds the connection graph. For an already-ingested paper with a `cards`
   row, you can also set `cards.web_lesson_url` directly (migration
   `019_web_lesson.sql`):
   ```sql
   update cards set web_lesson_url =
     'https://<project>.supabase.co/storage/v1/object/public/web-lessons/grokking/index.html'
   where paper_id = 'loop:foundational:grokking';
   ```
4. `serve-cards` returns `web_lesson_url`; the app renders it. Done. A
   web-lesson URL takes precedence over the native reader, so this also upgrades
   existing papers.

## Local testing (before the backend is wired)

Add the bundle to the app target as a resource and register it in
`WebLessonView.swift`:

```swift
enum WebLessonRegistry {
    static let localOverrides: [String: URL] = [
        "loop:foundational:grokking":
            Bundle.main.url(forResource: "grokking-premium", withExtension: "html")!
    ]
}
```

Open that paper and the web lesson renders instead of the native one. Remove the
override once the bundle is live on the server.
