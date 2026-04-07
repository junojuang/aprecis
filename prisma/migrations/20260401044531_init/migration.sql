-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "vector";

-- CreateTable
CREATE TABLE "Item" (
    "id" TEXT NOT NULL,
    "externalId" TEXT NOT NULL,
    "title" TEXT,
    "content" TEXT NOT NULL,
    "author" TEXT,
    "source" TEXT NOT NULL,
    "publishedAt" TIMESTAMP(3) NOT NULL,
    "embedded" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Embedding" (
    "id" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "vector" vector(1536) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Embedding_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Signal" (
    "id" TEXT NOT NULL,
    "topic" TEXT NOT NULL,
    "sourceCount" INTEGER NOT NULL,
    "totalMentions" INTEGER NOT NULL,
    "timeSpanHours" DOUBLE PRECISION NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "strength" TEXT NOT NULL,
    "hook" TEXT,
    "coreIdea" TEXT,
    "eli5" TEXT,
    "whyItMatters" TEXT,
    "detectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Signal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SignalItem" (
    "id" TEXT NOT NULL,
    "signalId" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,

    CONSTRAINT "SignalItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Item_externalId_key" ON "Item"("externalId");

-- CreateIndex
CREATE UNIQUE INDEX "Embedding_itemId_key" ON "Embedding"("itemId");

-- CreateIndex
CREATE UNIQUE INDEX "SignalItem_signalId_itemId_key" ON "SignalItem"("signalId", "itemId");

-- AddForeignKey
ALTER TABLE "Embedding" ADD CONSTRAINT "Embedding_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "Item"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SignalItem" ADD CONSTRAINT "SignalItem_signalId_fkey" FOREIGN KEY ("signalId") REFERENCES "Signal"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SignalItem" ADD CONSTRAINT "SignalItem_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "Item"("id") ON DELETE CASCADE ON UPDATE CASCADE;
