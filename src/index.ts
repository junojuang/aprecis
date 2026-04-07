import 'dotenv/config'
import app from './api/server'
import { startCronJobs } from './cron/jobs'

const PORT = Number(process.env.PORT ?? 3000)

app.listen(PORT, () => {
  console.log(`Aprecis API running on http://localhost:${PORT}`)
  console.log(`  GET /health`)
  console.log(`  GET /signals`)
  console.log(`  GET /signals/:id`)
  startCronJobs()
})
