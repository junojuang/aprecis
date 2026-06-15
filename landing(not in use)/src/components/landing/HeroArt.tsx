const HERO_SVG = `
<svg viewBox="0 4 460 332" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="paperGrad2" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/>
      <stop offset="1" stop-color="#f1ece2"/>
    </linearGradient>
    <linearGradient id="cardGrad2" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/>
      <stop offset="1" stop-color="#e5f4f4"/>
    </linearGradient>
    <linearGradient id="tealCard2" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#1a8a8a"/>
      <stop offset="1" stop-color="#0e3434"/>
    </linearGradient>
    <filter id="softShadow2" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#0a2a2a" flood-opacity="0.10"/>
    </filter>
    <radialGradient id="deckHalo2" cx="0.5" cy="0.55" r="0.55">
      <stop offset="0" stop-color="#1a8a8a" stop-opacity="0.16"/>
      <stop offset="1" stop-color="#1a8a8a" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <ellipse cx="335" cy="200" rx="135" ry="120" fill="url(#deckHalo2)"/>

  <g filter="url(#softShadow2)">
    <rect x="20" y="44" width="150" height="200" rx="8" fill="url(#paperGrad2)" stroke="rgba(15,17,23,0.08)"/>
    <text x="34" y="60" font-family="Satoshi, sans-serif" font-size="6" fill="#1a8a8a" letter-spacing="1.6" font-weight="700">PREPRINT · 6 H AGO</text>
    <rect x="34" y="68" width="100" height="6" rx="2" fill="#0f1117" opacity="0.82"/>
    <rect x="34" y="80" width="76" height="4" rx="2" fill="#0f1117" opacity="0.44"/>
    <rect x="34" y="92" width="60" height="3" rx="1.5" fill="#1a8a8a" opacity="0.65"/>
    <text x="34" y="110" font-family="Satoshi, sans-serif" font-size="6" fill="#8a8f9a" letter-spacing="1.4" font-weight="700">ABSTRACT</text>
    <g fill="#0f1117" opacity="0.18">
      <rect x="34" y="116" width="122" height="3" rx="1.5"/>
      <rect x="34" y="124" width="118" height="3" rx="1.5"/>
    </g>
    <rect class="hv_hl_band" x="34" y="131" width="110" height="7" rx="2" fill="#fde7a4" opacity="0.85"/>
    <rect x="34" y="132" width="110" height="3" rx="1.5" fill="#0f1117" opacity="0.55"/>
    <g fill="#0f1117" opacity="0.18">
      <rect x="34" y="142" width="124" height="3" rx="1.5"/>
      <rect x="34" y="150" width="80" height="3" rx="1.5"/>
    </g>
    <text x="34" y="168" font-family="Satoshi, sans-serif" font-size="6" fill="#8a8f9a" letter-spacing="1.4" font-weight="700">FIG 1 · ATTENTION</text>
    <g class="hv_eq_glow">
      <rect x="34" y="172" width="122" height="26" rx="3" fill="#0f1117" opacity="0.05"/>
      <circle cx="48" cy="185" r="2.4" fill="#1a8a8a"/>
      <circle cx="58" cy="185" r="2.4" fill="#1a8a8a" opacity="0.65"/>
      <circle cx="68" cy="185" r="2.4" fill="#1a8a8a" opacity="0.4"/>
      <text x="80" y="189" font-family="EB Garamond, serif" font-style="italic" font-size="12" fill="#0f1117" opacity="0.6">softmax(QKᵀ)V</text>
    </g>
    <g fill="#0f1117" opacity="0.18">
      <rect x="34" y="208" width="120" height="3" rx="1.5"/>
      <rect x="34" y="216" width="116" height="3" rx="1.5"/>
      <rect x="34" y="224" width="84" height="3" rx="1.5"/>
    </g>
    <text x="34" y="240" font-family="Satoshi, sans-serif" font-size="7" fill="#8a8f9a" letter-spacing="1.4">arXiv:2511.04823</text>
  </g>

  <g>
    <circle cx="184" cy="150" r="1.6" fill="#1a8a8a" opacity="0.35"/>
    <circle cx="194" cy="160" r="1.6" fill="#1a8a8a" opacity="0.55"/>
    <circle cx="204" cy="170" r="1.6" fill="#1a8a8a" opacity="0.75"/>
    <path d="M 178 145 C 204 150, 204 180, 224 184" stroke="#1a8a8a" stroke-width="1.6" fill="none" class="flow_line" stroke-linecap="round"/>
    <circle cx="224" cy="184" r="3" fill="#1a8a8a"/>
    <circle cx="224" cy="184" r="6" fill="#1a8a8a" opacity="0.18" class="pulse_dot"/>
  </g>

  <g transform="translate(260,40)">
    <g class="hv_card_back" transform="translate(40,16)">
      <g filter="url(#softShadow2)" transform="rotate(8 70 110)">
        <rect width="140" height="208" rx="14" fill="url(#cardGrad2)" stroke="rgba(15,17,23,0.08)"/>
        <text x="14" y="22" font-family="Satoshi, sans-serif" font-size="7" fill="#1a8a8a" letter-spacing="1.6" font-weight="700">DIAGRAM</text>
        <rect x="14" y="32" width="92" height="8" rx="2" fill="#0f1117" opacity="0.7"/>
        <g transform="translate(14,52)">
          <rect width="112" height="22" rx="6" fill="#e5f4f4"/>
          <rect width="3" height="14" x="6" y="4" fill="#1a8a8a"/>
          <rect width="60" height="3" x="14" y="9" rx="1.5" fill="#0f1117" opacity="0.6"/>
          <rect width="40" height="2.5" x="14" y="15" rx="1.25" fill="#0f1117" opacity="0.3"/>
        </g>
        <g transform="translate(14,80)">
          <rect width="112" height="22" rx="6" fill="#e5f4f4"/>
          <rect width="3" height="14" x="6" y="4" fill="#1a8a8a"/>
          <rect width="68" height="3" x="14" y="9" rx="1.5" fill="#0f1117" opacity="0.6"/>
          <rect width="36" height="2.5" x="14" y="15" rx="1.25" fill="#0f1117" opacity="0.3"/>
        </g>
        <g transform="translate(14,108)">
          <rect width="112" height="22" rx="6" fill="#e5f4f4"/>
          <rect width="3" height="14" x="6" y="4" fill="#1a8a8a"/>
          <rect width="52" height="3" x="14" y="9" rx="1.5" fill="#0f1117" opacity="0.6"/>
          <rect width="44" height="2.5" x="14" y="15" rx="1.25" fill="#0f1117" opacity="0.3"/>
        </g>
      </g>
    </g>

    <g class="hv_card_middle" transform="translate(20,8)">
      <g filter="url(#softShadow2)" transform="rotate(-3 70 110)">
        <rect width="140" height="220" rx="14" fill="url(#tealCard2)"/>
        <text x="14" y="32" font-family="Satoshi, sans-serif" font-size="8" fill="#5fd4d4" letter-spacing="1.6" font-weight="700">CORE IDEA</text>
        <text x="14" y="64" font-family="EB Garamond, serif" font-style="italic" font-size="22" fill="white">Attention is</text>
        <text x="14" y="88" font-family="EB Garamond, serif" font-style="italic" font-size="22" fill="white">just a</text>
        <text x="14" y="112" font-family="EB Garamond, serif" font-style="italic" font-size="22" fill="#5fd4d4">weighted</text>
        <text x="14" y="136" font-family="EB Garamond, serif" font-style="italic" font-size="22" fill="#5fd4d4">average.</text>
        <g transform="translate(14,158)">
          <rect width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.18"/>
          <rect x="16" width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.42"/>
          <rect x="32" width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.86"/>
          <rect x="48" width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.32"/>
          <rect x="64" width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.18"/>
          <rect x="80" width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.55"/>
          <rect x="96" width="14" height="14" rx="2" fill="#5fd4d4" opacity="0.24"/>
        </g>
      </g>
    </g>

    <g class="hv_card_front" transform="translate(0,30)">
      <g filter="url(#softShadow2)" transform="rotate(-12 70 110)">
        <rect width="138" height="204" rx="14" fill="url(#cardGrad2)" stroke="rgba(15,17,23,0.08)"/>
        <text x="14" y="26" font-family="Satoshi, sans-serif" font-size="7" fill="#1a8a8a" letter-spacing="1.6" font-weight="700">HOOK</text>
        <text x="14" y="58" font-family="EB Garamond, serif" font-style="italic" font-size="18" fill="#0f1117">Why does a</text>
        <text x="14" y="78" font-family="EB Garamond, serif" font-style="italic" font-size="18" fill="#0f1117">model know</text>
        <text x="14" y="98" font-family="EB Garamond, serif" font-style="italic" font-size="18" fill="#1a8a8a">where to look?</text>
        <path d="M 14 104 C 38 109, 80 100, 122 105" stroke="#e8a020" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.85"/>
        <circle cx="20" cy="142" r="4" fill="#1a8a8a" class="pulse_dot"/>
        <rect x="32" y="138" width="60" height="8" rx="3" fill="#0f1117" opacity="0.14"/>
        <rect x="32" y="152" width="84" height="6" rx="3" fill="#0f1117" opacity="0.10"/>
        <rect x="14" y="172" width="50" height="6" rx="3" fill="#0f1117" opacity="0.10"/>
        <text x="14" y="196" font-family="Satoshi, sans-serif" font-size="6" fill="#8a8f9a" letter-spacing="1.4" font-weight="700">SWIPE →</text>
      </g>
    </g>
  </g>

  <text x="95" y="300" text-anchor="middle" font-family="EB Garamond, serif" font-style="italic" font-size="13" fill="#1a8a8a">Research Paper</text>
  <text x="345" y="300" text-anchor="middle" font-family="EB Garamond, serif" font-style="italic" font-size="13" fill="#1a8a8a">Aprecis</text>
</svg>
`

/**
 * Decorative product still-life that sits below the hero converter. Same SVG
 * used by the original homepage hero, lifted into its own component so the
 * `HeroConverter` can occupy the full top-of-fold real estate while this
 * remains as supporting illustration during the idle / error states.
 */
export default function HeroArt() {
  return (
    <section className="hero_art reveal">
      <div className="wrap">
        <div className="hero_stage" style={{ marginTop: 0 }}>
          <div className="hero_panel" aria-hidden="true">
            <div className="hv_sheen" />
            <div className="hv_caption">abstract to a deck of diagrams</div>
            <div dangerouslySetInnerHTML={{ __html: HERO_SVG }} />
          </div>
        </div>
      </div>
    </section>
  )
}
