import Foundation

// MARK: - Paper reading experience
//
// Resolves `CardDeck` → `DailyLoopContent` (shown in DailyLoopView) or legacy PaperDetailView.
//
// Order of precedence:
// 1. Curator `loop:` id → [`CuratedPaperCatalog`](CuratedPaperCatalog)
// 2. Chain-of-thought arXiv / title heuristic (matches canonical CoT interactive loop)
// 3. `deck.blueprint` → fused `DailyLoopContent(deck:blueprint:)`
// 4. Legacy concept cards (`PaperDetailView`)

enum PaperReadingExperience {
    case webLesson(URL)
    case dailyLoop(DailyLoopContent)
    case legacy(CardDeck)

    static func resolve(_ deck: CardDeck) -> PaperReadingExperience {
        // A web-bundle lesson (server-driven, no app update) wins over every
        // native reader, so any paper can be replaced with a premium web lesson.
        if let webURL = WebLessonRegistry.url(for: deck) {
            return .webLesson(webURL)
        }
        if deck.paperId.hasPrefix("loop:"),
           let base = CuratedPaperCatalog.content(forPaperId: deck.paperId) {
            return .dailyLoop(base.withPaperId(deck.paperId))
        }
        if isChainOfThoughtBridge(deck) {
            return .dailyLoop(.chainOfThought.withPaperId(deck.paperId))
        }
        if let bp = deck.blueprint {
            return .dailyLoop(DailyLoopContent(deck: deck, blueprint: bp).withPaperId(deck.paperId))
        }
        return .legacy(deck)
    }

    private static func isChainOfThoughtBridge(_ deck: CardDeck) -> Bool {
        let haystack = "\(deck.paperId) \(deck.title ?? "")".lowercased()
        return haystack.contains("2201.11903")
            || haystack.contains("chain-of-thought")
            || haystack.contains("chain of thought")
    }
}
