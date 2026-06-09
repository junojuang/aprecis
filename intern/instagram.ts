// Fetches recent posts from public Instagram profiles via page HTML scraping

export interface Post {
  username: string;
  caption: string;
  timestamp: number;
  url: string;
  likes: number;
}

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
  'Accept-Encoding': 'gzip, deflate, br',
  'Cache-Control': 'no-cache',
};

export async function fetchRecentPosts(username: string, limit = 6): Promise<Post[]> {
  try {
    const res = await fetch(`https://www.instagram.com/${username}/`, { headers: HEADERS });

    if (!res.ok) {
      console.warn(`  ⚠ @${username}: HTTP ${res.status} — skipping`);
      return [];
    }

    const html = await res.text();

    // Extract JSON from the embedded script tags
    const match = html.match(/"edge_owner_to_timeline_media":\{"edges":\[(.*?)\],"page_info"/s);
    if (!match) {
      // Try alternate data shape
      console.warn(`  ⚠ @${username}: could not parse posts (profile may be private or layout changed)`);
      return [];
    }

    const edgesJson = `[${match[1]}]`;
    const edges = JSON.parse(edgesJson);

    return edges.slice(0, limit).map((e: any) => ({
      username,
      caption: e?.node?.edge_media_to_caption?.edges?.[0]?.node?.text ?? '',
      timestamp: e?.node?.taken_at_timestamp ?? 0,
      url: `https://www.instagram.com/p/${e?.node?.shortcode}/`,
      likes: e?.node?.edge_liked_by?.count ?? 0,
    }));
  } catch (err) {
    console.warn(`  ⚠ @${username}: ${(err as Error).message}`);
    return [];
  }
}
