import { useEffect, useState } from 'react'
import Nav from '../components/Nav'
import Footer from '../components/Footer'
import HeroConverter from '../components/landing/HeroConverter'
import HeroArt from '../components/landing/HeroArt'
import LivePreview from '../components/landing/LivePreview'
import Why from '../components/landing/Why'
import How from '../components/landing/How'
import Closing from '../components/landing/Closing'

type ConvStatus = 'idle' | 'loading' | 'done' | 'error'

export default function Landing() {
  const [convStatus, setConvStatus] = useState<ConvStatus>('idle')

  useEffect(() => {
    const els = Array.from(document.querySelectorAll<HTMLElement>('.reveal'))
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add('in')
            io.unobserve(e.target)
          }
        }
      },
      { threshold: 0.12 },
    )
    els.forEach((el) => io.observe(el))
    return () => io.disconnect()
  }, [convStatus])

  // Once we have a rendered deck we hide the marketing sections so the deck
  // owns the page. Until then the homepage is hero + supporting sections.
  const showMarketing = convStatus !== 'done'

  return (
    <>
      <Nav />
      <HeroConverter onStatusChange={setConvStatus} />
      {showMarketing && (
        <>
          <HeroArt />
          <div className="reveal">
            <LivePreview />
          </div>
          <div className="reveal">
            <Why />
          </div>
          <div className="reveal">
            <How />
          </div>
          <div className="reveal">
            <Closing />
          </div>
        </>
      )}
      <Footer />
    </>
  )
}
