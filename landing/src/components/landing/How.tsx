const SVG_HOOK = `
<svg viewBox="0 0 200 144" xmlns="http://www.w3.org/2000/svg">
  <circle cx="100" cy="72" r="46" fill="none" stroke="#1a8a8a" stroke-width="1" opacity="0.12"/>
  <circle cx="100" cy="72" r="34" fill="none" stroke="#1a8a8a" stroke-width="1" opacity="0.18"/>
  <circle cx="100" cy="72" r="22" fill="none" stroke="#1a8a8a" stroke-width="1" opacity="0.25"/>
  <circle cx="100" cy="72" r="8" fill="#1a8a8a" class="pulse_dot"/>
  <text x="100" y="42" text-anchor="middle" font-family="EB Garamond, serif" font-style="italic" font-size="20" fill="#0e3434" opacity="0.6">why?</text>
</svg>`

const SVG_ANALOGY = `
<svg viewBox="0 0 200 144" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(28,30)">
    <rect width="52" height="84" rx="6" fill="white" stroke="#1a8a8a" stroke-width="1.2"/>
    <rect x="8" y="14" width="36" height="3" rx="1.5" fill="#0f1117" opacity="0.5"/>
    <rect x="8" y="22" width="28" height="3" rx="1.5" fill="#0f1117" opacity="0.3"/>
    <rect x="8" y="36" width="36" height="3" rx="1.5" fill="#0f1117" opacity="0.3"/>
    <rect x="8" y="44" width="32" height="3" rx="1.5" fill="#0f1117" opacity="0.3"/>
    <rect x="8" y="52" width="36" height="3" rx="1.5" fill="#0f1117" opacity="0.3"/>
    <text x="26" y="78" text-anchor="middle" font-family="Satoshi, sans-serif" font-size="6" fill="#8a8f9a" letter-spacing="1">YOU KNOW</text>
  </g>
  <g stroke="#1a8a8a" stroke-width="1.2" fill="none" opacity="0.7">
    <path d="M 84 50 C 100 50, 100 56, 116 56" class="flow_line"/>
    <path d="M 84 76 C 100 76, 100 88, 116 88" class="flow_line" style="animation-delay:.4s"/>
  </g>
  <g transform="translate(116,32)">
    <rect width="56" height="14" rx="3" fill="#1a8a8a" opacity="0.85"/>
    <rect y="20" width="56" height="14" rx="3" fill="#1a8a8a" opacity="0.6"/>
    <rect y="40" width="56" height="14" rx="3" fill="#1a8a8a" opacity="0.4"/>
    <rect y="60" width="56" height="14" rx="3" fill="#1a8a8a" opacity="0.25"/>
    <text x="28" y="92" text-anchor="middle" font-family="Satoshi, sans-serif" font-size="6" fill="#8a8f9a" letter-spacing="1">THE PAPER</text>
  </g>
</svg>`

const SVG_VISUAL = `
<svg viewBox="0 0 200 144" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="legendGrad" x1="0" x2="1" y1="0" y2="0">
      <stop offset="0" stop-color="#1a8a8a" stop-opacity="0.05"/>
      <stop offset="1" stop-color="#1a8a8a" stop-opacity="0.95"/>
    </linearGradient>
  </defs>
  <g transform="translate(34,22)">
    <g>
      <rect x="0" y="0" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.18"/>
      <rect x="22" y="0" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.42"/>
      <rect x="44" y="0" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.86"/>
      <rect x="66" y="0" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.55"/>
      <rect x="88" y="0" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.22"/>
      <rect x="110" y="0" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.34"/>
      <rect x="0" y="16" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.32"/>
      <rect x="22" y="16" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.92"/>
      <rect x="44" y="16" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.42"/>
      <rect x="66" y="16" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.18"/>
      <rect x="88" y="16" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.66"/>
      <rect x="110" y="16" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.26"/>
      <rect x="0" y="32" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.62"/>
      <rect x="22" y="32" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.22"/>
      <rect x="44" y="32" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.38"/>
      <rect x="66" y="32" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.78"/>
      <rect x="88" y="32" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.46"/>
      <rect x="110" y="32" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.18"/>
      <rect x="0" y="48" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.18"/>
      <rect x="22" y="48" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.34"/>
      <rect x="44" y="48" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.55"/>
      <rect x="66" y="48" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.94"/>
      <rect x="88" y="48" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.32"/>
      <rect x="110" y="48" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.22"/>
      <rect x="0" y="64" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.42"/>
      <rect x="22" y="64" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.18"/>
      <rect x="44" y="64" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.66"/>
      <rect x="66" y="64" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.34"/>
      <rect x="88" y="64" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.82"/>
      <rect x="110" y="64" width="20" height="14" rx="2" fill="#1a8a8a" opacity="0.42"/>
    </g>
    <rect x="0" y="86" width="64" height="3" rx="1.5" fill="url(#legendGrad)"/>
    <text x="68" y="89" font-family="Satoshi, sans-serif" font-size="6" fill="#8a8f9a">low → high</text>
  </g>
</svg>`

const SVG_TAKEAWAY = `
<svg viewBox="0 0 200 144" xmlns="http://www.w3.org/2000/svg">
  <g class="orbit_group" style="transform-origin: 100px 72px;">
    <circle cx="100" cy="72" r="44" fill="none" stroke="#1a8a8a" stroke-width="1" stroke-dasharray="2 4" opacity="0.4"/>
    <circle cx="144" cy="72" r="3" fill="#1a8a8a"/>
    <circle cx="100" cy="28" r="3" fill="#e8a020"/>
    <circle cx="56" cy="72" r="3" fill="#1a8a8a" opacity="0.7"/>
    <circle cx="100" cy="116" r="3" fill="#1a8a8a" opacity="0.7"/>
  </g>
  <circle cx="100" cy="72" r="18" fill="#0e3434"/>
  <text x="100" y="76" text-anchor="middle" font-family="EB Garamond, serif" font-style="italic" font-size="14" fill="#5fd4d4">a.</text>
</svg>`

const CARDS = [
  { svg: SVG_HOOK, num: '01', title: 'The hook', body: 'A question worth answering.' },
  { svg: SVG_ANALOGY, num: '02', title: 'The analogy', body: 'A mental model you already own.' },
  { svg: SVG_VISUAL, num: '03', title: 'The visual', body: 'Drawn fresh for the paper.' },
  { svg: SVG_TAKEAWAY, num: '04', title: 'The takeaway', body: 'One sentence to repeat at dinner.' },
]

export default function How() {
  return (
    <section className="section" id="how">
      <div className="wrap">
        <div className="section_label">How a lesson unfolds</div>
        <h2 className="section_title">
          Every paper, one <em>idea</em>.
        </h2>
        <p className="section_sub">
          Distill abstracts into interactive, concise learning materials.
        </p>

        <div className="unfold_grid">
          {CARDS.map((c) => (
            <div className="unfold_card" key={c.num}>
              <div className="uc_diagram" dangerouslySetInnerHTML={{ __html: c.svg }} />
              <div className="uc_num">{c.num}</div>
              <h3 className="uc_title">{c.title}</h3>
              <p className="uc_body">{c.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
