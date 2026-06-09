import { useEffect, useState } from 'react'
import Landing from './pages/Landing'
import Convert from './pages/Convert'

function routeFromHash(): 'landing' | 'convert' {
  return window.location.hash.startsWith('#/convert') ? 'convert' : 'landing'
}

export default function App() {
  const [route, setRoute] = useState<'landing' | 'convert'>(routeFromHash())

  useEffect(() => {
    const onChange = () => {
      const next = routeFromHash()
      setRoute(next)
      if (next === 'convert') window.scrollTo({ top: 0 })
    }
    window.addEventListener('hashchange', onChange)
    return () => window.removeEventListener('hashchange', onChange)
  }, [])

  return route === 'convert' ? <Convert /> : <Landing />
}
