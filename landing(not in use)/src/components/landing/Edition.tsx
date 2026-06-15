type Entry = {
  serial: string
  title: string
  meta: string
  take: string
}

// The marketing centerpiece: a single, finite "issue" of the paper club.
// Mirrors the in-app Editions concept and a real YC Paper Club session theme.
const ENTRIES: Entry[] = [
  {
    serial: '01',
    title: 'Test-time compute beats parameter count',
    meta: 'Inference scaling · 2025',
    take: 'Let a model think for longer at answer time and a small model can match a giant one. The lever moved from training size to thinking time.',
  },
  {
    serial: '02',
    title: 'Diffusion comes for language',
    meta: 'Diffusion language models · 2025',
    take: 'Draft a whole answer at once, then refine it in parallel instead of one word at a time. Faster, and it can revise itself.',
  },
  {
    serial: '03',
    title: 'World models you can act inside',
    meta: 'World models · 2025',
    take: 'Train a model that imagines how a scene will change, so an agent can plan by rehearsing in its head before it acts.',
  },
]

export default function Edition() {
  return (
    <section className="edition" id="edition">
      <div className="wrap">
        <div className="ed_card">
          <div className="ed_masthead">
            <span>This week&apos;s edition</span>
            <span className="ed_issue">No. 03</span>
          </div>

          <h2 className="ed_thesis">After bigger models</h2>
          <p className="ed_standfirst">
            Where AI goes once scaling slows: inference, diffusion, and world
            models.
          </p>

          <div className="ed_list">
            {ENTRIES.map((e) => (
              <div className="ed_row" key={e.serial}>
                <div className="ed_serial">{e.serial}</div>
                <div>
                  <p className="ed_paper_title">{e.title}</p>
                  <p className="ed_paper_meta">{e.meta}</p>
                  <p className="ed_take">
                    <span className="ed_take_label">The take</span>
                    {e.take}
                  </p>
                </div>
              </div>
            ))}
          </div>

          <p className="ed_synthesis">
            <span className="ed_take_label">The synthesis</span>
            The next jump in AI looks less like a bigger model and more like a
            smarter one: thinking for longer, drafting in parallel, and planning
            ahead.
          </p>
        </div>
      </div>
    </section>
  )
}
