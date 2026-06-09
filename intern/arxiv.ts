// Fetches trending AI papers from arXiv — no auth required

export interface Paper {
  title: string;
  summary: string;
  authors: string[];
  url: string;
  published: string;
}

const QUERIES = [
  'cat:cs.AI+AND+submittedDate:[NOW-7DAYS+TO+NOW]',
  'cat:cs.LG+AND+submittedDate:[NOW-7DAYS+TO+NOW]',
  'cat:cs.CL+AND+submittedDate:[NOW-7DAYS+TO+NOW]', // NLP / LLMs
];

function parseXml(xml: string, tag: string): string {
  const match = xml.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`));
  return match ? match[1].replace(/<[^>]+>/g, '').trim() : '';
}

function parseXmlAll(xml: string, tag: string): string[] {
  const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'g');
  const results: string[] = [];
  let m;
  while ((m = re.exec(xml)) !== null) {
    results.push(m[1].replace(/<[^>]+>/g, '').trim());
  }
  return results;
}

export async function fetchTrendingPapers(limit = 15): Promise<Paper[]> {
  const papers: Paper[] = [];

  for (const query of QUERIES) {
    try {
      const url = `https://export.arxiv.org/api/query?search_query=${query}&sortBy=submittedDate&sortOrder=descending&max_results=8`;
      const res = await fetch(url, {
        headers: { 'User-Agent': 'Aprecis-Intern/1.0' },
      });
      const xml = await res.text();

      const entries = xml.split('<entry>').slice(1);
      for (const entry of entries) {
        const title   = parseXml(entry, 'title').replace(/\n/g, ' ');
        const summary = parseXml(entry, 'summary').replace(/\n/g, ' ').slice(0, 500);
        const link    = parseXmlAll(entry, 'id')[0] ?? '';
        const authors = parseXmlAll(entry, 'name').slice(0, 3);
        const published = parseXml(entry, 'published').slice(0, 10);

        if (title && summary) {
          papers.push({ title, summary, authors, url: link, published });
        }
      }
    } catch (err) {
      console.warn(`  ⚠ arXiv fetch failed: ${(err as Error).message}`);
    }
  }

  // deduplicate by title and return top N
  const seen = new Set<string>();
  return papers.filter(p => {
    if (seen.has(p.title)) return false;
    seen.add(p.title);
    return true;
  }).slice(0, limit);
}
