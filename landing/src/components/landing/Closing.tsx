const TESTFLIGHT = 'https://testflight.apple.com/join/a5BUTYft'

export default function Closing() {
  return (
    <section className="closing">
      <div className="wrap">
        <div className="closing_card">
          <h2>
            Tomorrow&apos;s paper, <em>already</em> a lesson.
          </h2>
          <p>
            Paste any arXiv link and watch it become an Aprecis deck, or take the
            whole feed with you on iOS.
          </p>
          <div className="btn_row" style={{ justifyContent: 'center', marginBottom: 0 }}>
            <a href="#/convert" className="btn btn_primary">
              Convert a paper <span className="arrow">→</span>
            </a>
            <a
              href={TESTFLIGHT}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn_ghost"
              style={{ background: 'rgba(255,255,255,0.12)', color: 'white', borderColor: 'rgba(255,255,255,0.25)' }}
            >
              Get early access
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
