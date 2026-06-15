/**
 * Landing hero. Pure type, no panel art. Leads with the positioning
 * ("the paper club anyone can attend") and the recurring promise
 * ("stay close to the frontier"). The live converter is demoted to a
 * quiet tertiary link and its own /convert page.
 */
export default function Hero() {
  return (
    <section className="hero">
      <div className="wrap">
        <div className="hero_head">
          <div className="eyebrow">Designed for kids to understand</div>
          <h1 className="headline">
            <span className="hl_line">
              <span className="hl_inner">The paper club</span>
            </span>
            <span className="hl_line">
              <span className="hl_inner">
                <span className="hl">anyone</span> can attend.
              </span>
            </span>
          </h1>
          <p className="lede">
            <em>AI research for everyone</em>. Keep up with the frontier of
            where AI is moving, whether you are a student, researcher, engineer,
            or a hairdresser learning about AI.
          </p>
        </div>
      </div>
    </section>
  )
}
