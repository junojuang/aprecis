// Aprecis Intern — Instagram content intelligence tool
// Usage: OPENAI_API_KEY=your_key npx ts-node index.ts

import { ACCOUNTS } from './accounts';
import { fetchRecentPosts, type Post } from './instagram';
import { generatePostIdeas } from './generate';

async function main() {
  console.log('🔍 Aprecis Intern — fetching posts...\n');

  const allPosts: Post[] = [];

  for (const username of ACCOUNTS) {
    process.stdout.write(`  Fetching @${username}...`);
    const posts = await fetchRecentPosts(username, 4);
    allPosts.push(...posts);
    console.log(` ${posts.length} posts`);
    // be polite to Instagram's servers
    await new Promise(r => setTimeout(r, 1200));
  }

  console.log(`\n✅ Collected ${allPosts.length} posts total`);

  // Sort by likes — most engaging content first
  allPosts.sort((a, b) => b.likes - a.likes);
  const top = allPosts.slice(0, 20);

  console.log('\n🤖 Generating post ideas with GPT-4o-mini...\n');
  const ideas = await generatePostIdeas(top);

  console.log('═'.repeat(60));
  console.log('  APRECIS POST IDEAS');
  console.log('═'.repeat(60));

  ideas.forEach((idea, i) => {
    console.log(`\n[${i + 1}] ${idea.title}`);
    console.log(`    Inspired by: ${idea.inspiredBy}`);
    console.log(`    Format: ${idea.format}`);
    console.log(`\n    HOOK: "${idea.hook}"`);
    console.log('\n    SLIDES:');
    idea.slides.forEach((s, j) => console.log(`      ${j + 1}. ${s}`));
    console.log(`\n    CAPTION:\n      ${idea.caption}`);
    console.log(`\n    HASHTAGS: ${idea.hashtags.map(h => `#${h}`).join(' ')}`);
    console.log('\n' + '─'.repeat(60));
  });
}

main().catch(console.error);
