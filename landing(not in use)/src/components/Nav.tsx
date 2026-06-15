const TESTFLIGHT = 'https://testflight.apple.com/join/a5BUTYft'

export default function Nav() {
  return (
    <header className="nav">
      <div className="wrap nav_inner">
        <a href="#/" className="brand" aria-label="Aprecis home">
          <img className="brand_mark" src="/assets/aprecis_app_icon.svg" alt="" />
          <span>
            <span className="brand_word">aprecis</span>
            <span className="brand_dot">.</span>
          </span>
        </a>
        <nav className="nav_links">
          <a
            href={TESTFLIGHT}
            target="_blank"
            rel="noopener noreferrer"
            className="nav_cta"
          >
            Get the mobile app <span aria-hidden="true">→</span>
          </a>
        </nav>
      </div>
    </header>
  )
}
