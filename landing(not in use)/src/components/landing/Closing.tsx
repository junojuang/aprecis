const TESTFLIGHT = 'https://testflight.apple.com/join/a5BUTYft'

export default function Closing() {
  return (
    <section className="closing">
      <div className="wrap">
        <div className="closing_card">
          <h2>
            Pull up a <em>chair</em>.
          </h2>
          <p>Stay close to the frontier, one edition at a time.</p>
          <div
            className="btn_row"
            style={{ justifyContent: 'center', marginBottom: 0 }}
          >
            <a
              href={TESTFLIGHT}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn_primary"
            >
              Get the mobile app <span className="arrow">→</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
