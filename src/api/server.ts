import express from 'express'
import signalsRouter from './routes/signals'

const app = express()

app.use(express.json())

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'aprecis', ts: new Date().toISOString() })
})

app.use('/signals', signalsRouter)

// 404 fallback
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' })
})

export default app
