-- Run this AFTER `prisma migrate dev` to set up pgvector support.
-- Usage: psql $DATABASE_URL -f scripts/init-pgvector.sql

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Add vector column to Embedding table (Prisma won't create Unsupported columns)
ALTER TABLE "Embedding" ADD COLUMN IF NOT EXISTS vector vector(1536);

-- Create an IVFFlat index for fast approximate nearest-neighbor search
-- (optional but improves performance at scale)
-- CREATE INDEX IF NOT EXISTS embedding_vector_idx
--   ON "Embedding" USING ivfflat (vector vector_cosine_ops)
--   WITH (lists = 100);
