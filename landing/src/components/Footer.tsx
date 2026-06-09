export default function Footer() {
  return (
    <footer>
      <div className="wrap foot">
        <div className="foot_brand">
          <img src="/assets/aprecis_app_icon.svg" alt="Aprecis" />
          <span>
            <span className="brand_word">aprecis</span>
            <span className="brand_dot" style={{ fontStyle: 'italic', color: 'var(--ink)' }}>
              .
            </span>
          </span>
          <span
            style={{
              color: 'var(--muted)',
              fontFamily: "'Satoshi', sans-serif",
              fontSize: 13,
            }}
          >
            &nbsp;© 2026 · an AI-native learning system for AI research
          </span>
        </div>
        <div className="socials">
          <a
            href="https://www.instagram.com/aprecis.app/"
            target="_blank"
            rel="noopener"
            className="social_link"
            aria-label="Instagram"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <rect x="2" y="2" width="20" height="20" rx="5.5" stroke="currentColor" strokeWidth="1.8" />
              <circle cx="12" cy="12" r="4.2" stroke="currentColor" strokeWidth="1.8" />
              <circle cx="17.5" cy="6.5" r="1" fill="currentColor" />
            </svg>
          </a>
          <a
            href="https://x.com/aprecis_app"
            target="_blank"
            rel="noopener"
            className="social_link"
            aria-label="X"
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.746l7.73-8.835L1.254 2.25H8.08l4.253 5.622 5.911-5.622Zm-1.161 17.52h1.833L7.084 4.126H5.117L17.083 19.77Z" />
            </svg>
          </a>
          <a
            href="https://www.linkedin.com/company/aprecis/"
            target="_blank"
            rel="noopener"
            className="social_link"
            aria-label="LinkedIn"
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
              <path d="M20.45 20.45h-3.55v-5.57c0-1.33-.02-3.04-1.85-3.04-1.85 0-2.13 1.45-2.13 2.94v5.67H9.37V9h3.41v1.56h.05c.48-.9 1.63-1.85 3.36-1.85 3.6 0 4.26 2.37 4.26 5.45v6.29ZM5.34 7.43a2.06 2.06 0 1 1 0-4.12 2.06 2.06 0 0 1 0 4.12ZM7.12 20.45H3.56V9h3.56v11.45ZM22.22 0H1.77C.79 0 0 .77 0 1.72v20.56C0 23.23.79 24 1.77 24h20.45C23.2 24 24 23.23 24 22.28V1.72C24 .77 23.2 0 22.22 0Z" />
            </svg>
          </a>
        </div>
      </div>
    </footer>
  )
}
