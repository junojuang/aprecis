import { useEffect } from 'react'
import Nav from '../components/Nav'
import Footer from '../components/Footer'
import Hero from '../components/landing/Hero'
import Why from '../components/landing/Why'
import Closing from '../components/landing/Closing'

export default function Landing() {
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
  }, [])

  return (
    <>
      <Nav />
      <Hero />
      <div className="reveal">
        <Why />
      </div>
      <div className="reveal">
        <Closing />
      </div>
      <Footer />
    </>
  )
}
