import type { RawPaper } from "./types.ts";

// ─── arXiv ────────────────────────────────────────────────────────────────────

const ARXIV_CATEGORIES = ["cs.AI", "cs.LG", "cs.CL"];
const ARXIV_API = "https://export.arxiv.org/api/query";

export async function fetchArxiv(maxResults = 50): Promise<RawPaper[]> {
  const search = ARXIV_CATEGORIES.map((c) => `cat:${c}`).join("+OR+");
  const url = `${ARXIV_API}?search_query=${search}&sortBy=submittedDate&sortOrder=descending&max_results=${maxResults}`;

  const res = await fetch(url);
  const xml = await res.text();
  return parseArxivXML(xml);
}

function parseArxivXML(xml: string): RawPaper[] {
  const papers: RawPaper[] = [];
  const entries = xml.match(/<entry>([\s\S]*?)<\/entry>/g) ?? [];

  for (const entry of entries) {
    const id = extract(entry, "id")?.split("/abs/")[1]?.trim() ?? "";
    const title = extract(entry, "title")?.replace(/\s+/g, " ").trim() ?? "";
    const abstract = extract(entry, "summary")?.replace(/\s+/g, " ").trim() ?? "";
    const published = extract(entry, "published") ?? new Date().toISOString();
    const authors = [...entry.matchAll(/<name>(.*?)<\/name>/g)].map((m) => m[1]);
    const pdfUrl = entry.match(/href="(https:\/\/arxiv\.org\/pdf\/[^"]+)"/)?.[1];

    if (!id || !title) continue;

    papers.push({
      paper_id: `arxiv:${id}`,
      title,
      authors,
      abstract,
      source: "arxiv",
      url: `https://arxiv.org/abs/${id}`,
      pdf_url: pdfUrl ?? `https://arxiv.org/pdf/${id}`,
      published_at: published,
    });
  }
  return papers;
}

// ─── GitHub Trending ──────────────────────────────────────────────────────────

const GITHUB_API = "https://api.github.com/search/repositories";
const AI_TOPICS = ["large-language-model", "llm", "transformer", "ai-agent", "diffusion-model"];

export async function fetchGitHubTrending(token?: string): Promise<RawPaper[]> {
  const since = new Date(Date.now() - 7 * 86_400_000).toISOString().split("T")[0];
  const query = `${AI_TOPICS.map((t) => `topic:${t}`).join("+OR+")}+pushed:>${since}`;
  const url = `${GITHUB_API}?q=${query}&sort=stars&order=desc&per_page=20`;

  const headers: Record<string, string> = { Accept: "application/vnd.github.v3+json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(url, { headers });
  const data = await res.json();

  return (data.items ?? []).map((repo: any): RawPaper => ({
    paper_id: `github:${repo.full_name}`,
    title: repo.name,
    authors: [repo.owner.login],
    abstract: repo.description ?? "",
    source: "github",
    url: repo.html_url,
    published_at: repo.pushed_at,
    social_signals: { stars: repo.stargazers_count, forks: repo.forks_count },
  }));
}

// ─── RSS Newsletters ──────────────────────────────────────────────────────────

const RSS_FEEDS = [
  { url: "https://buttondown.email/ainews/rss", name: "AI News" },
  { url: "https://www.deeplearning.ai/the-batch/rss", name: "The Batch" },
  { url: "https://huggingface.co/blog/feed.xml", name: "HuggingFace Blog" },
];

export async function fetchRSSFeeds(): Promise<RawPaper[]> {
  const results = await Promise.allSettled(RSS_FEEDS.map(fetchRSS));
  return results
    .filter((r): r is PromiseFulfilledResult<RawPaper[]> => r.status === "fulfilled")
    .flatMap((r) => r.value);
}

async function fetchRSS(feed: { url: string; name: string }): Promise<RawPaper[]> {
  const res = await fetch(feed.url);
  const xml = await res.text();
  const items = xml.match(/<item>([\s\S]*?)<\/item>/g) ?? [];

  return items.slice(0, 10).map((item): RawPaper => {
    const title = extract(item, "title") ?? "";
    const link = extract(item, "link") ?? "";
    const description = extract(item, "description")?.replace(/<[^>]+>/g, "").trim() ?? "";
    const pubDate = extract(item, "pubDate") ?? new Date().toISOString();
    const id = btoa(link).slice(0, 16);

    return {
      paper_id: `rss:${id}`,
      title,
      authors: [feed.name],
      abstract: description.slice(0, 500),
      source: "rss",
      url: link,
      published_at: new Date(pubDate).toISOString(),
    };
  });
}

// ─── Twitter/X ────────────────────────────────────────────────────────────────
// Requires Twitter API v2 bearer token

const AI_ACCOUNTS = [
  "karpathy", "ylecun", "goodfellow_ian", "sama", "tsegay_tesfaye",
  "DrJimFan", "hardmaru", "EMostaque", "fchollet",
];

export async function fetchTwitter(bearerToken: string): Promise<RawPaper[]> {
  const query = `(from:${AI_ACCOUNTS.join(" OR from:")}) (paper OR research OR arxiv) -is:retweet lang:en`;
  const url = `https://api.twitter.com/2/tweets/search/recent?query=${encodeURIComponent(query)}&max_results=50&tweet.fields=created_at,public_metrics,entities&expansions=author_id`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${bearerToken}` },
  });
  const data = await res.json();

  return (data.data ?? []).map((tweet: any): RawPaper => {
    const arxivMatch = tweet.text.match(/arxiv\.org\/abs\/([\d.]+)/);
    return {
      paper_id: `twitter:${tweet.id}`,
      title: tweet.text.slice(0, 100),
      authors: [tweet.author_id],
      abstract: tweet.text,
      source: "twitter",
      url: arxivMatch
        ? `https://arxiv.org/abs/${arxivMatch[1]}`
        : `https://twitter.com/i/web/status/${tweet.id}`,
      published_at: tweet.created_at,
      social_signals: {
        mentions: tweet.public_metrics?.like_count + tweet.public_metrics?.retweet_count,
      },
    };
  });
}

// ─── Hacker News ──────────────────────────────────────────────────────────────

const HN_API = "https://hacker-news.firebaseio.com/v1";
const HN_AI_KEYWORDS = ["llm", "gpt", "ai", "machine learning", "neural", "openai", "anthropic", "gemini", "mistral", "arxiv", "transformer", "diffusion"];

export async function fetchHackerNews(limit = 30): Promise<RawPaper[]> {
  const res = await fetch(`${HN_API}/topstories.json`);
  const ids: number[] = await res.json();

  const items = await Promise.allSettled(
    ids.slice(0, 100).map((id) => fetch(`${HN_API}/item/${id}.json`).then((r) => r.json()))
  );

  const stories = items
    .filter((r): r is PromiseFulfilledResult<any> => r.status === "fulfilled")
    .map((r) => r.value)
    .filter((s) => {
      if (!s || s.type !== "story" || !s.title) return false;
      const text = (s.title + " " + (s.url ?? "")).toLowerCase();
      return HN_AI_KEYWORDS.some((kw) => text.includes(kw));
    })
    .slice(0, limit);

  return stories.map((s): RawPaper => ({
    paper_id: `hn:${s.id}`,
    title: s.title,
    authors: [s.by ?? "unknown"],
    abstract: s.title,
    source: "hackernews",
    url: s.url ?? `https://news.ycombinator.com/item?id=${s.id}`,
    published_at: new Date(s.time * 1000).toISOString(),
    social_signals: { mentions: s.score ?? 0 },
  }));
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function extract(xml: string, tag: string): string | undefined {
  return xml.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`))?.[1];
}
