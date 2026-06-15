const CARDS = [
  { num: '01', title: 'The hook', body: 'A question worth answering, in one line.' },
  { num: '02', title: 'The analogy', body: 'A mental model you already own.' },
  { num: '03', title: 'The visual', body: 'One diagram, drawn for this paper.' },
  { num: '04', title: 'The takeaway', body: 'One sentence to repeat at dinner.' },
]

export default function How() {
  return (
    <section className="section" id="how">
      <div className="wrap">
        <div className="section_label">How a paper is made simple</div>
        <h2 className="section_title">
          Every paper, <em>one idea</em> at a time.
        </h2>
        <p className="section_sub">
          No 40 page slog. Each paper becomes a short, guided read you finish in
          a few minutes.
        </p>

        <div className="unfold_grid">
          {CARDS.map((c) => (
            <div className="unfold_card" key={c.num}>
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
