import Foundation

// MARK: - Curated paper catalog
//
// Authoritative ordering of offline interactive loops ships in **data/curated-paper-catalog.json**
// (copied into the app bundle via `project.yml` → Resources). Resolver logic stays Swift;
// ids + ordering stay editable without renumbering scattered arrays.

private struct CuratedPaperCatalogFile: Decodable {
    let version: Int
    let interactiveLoopPaperIds: [String]
}

enum CuratedPaperCatalog {

    /// Same list as bundled JSON; used only if decode fails (previews/tests).
    private static let fallbackInteractiveLoopPaperIds: [String] = [
        "loop:foundational:perceptron",
        "loop:foundational:backprop",
        "loop:foundational:lenet",
        "loop:foundational:alexnet",
        "loop:foundational:word2vec",
        "loop:foundational:seq2seq",
        "loop:foundational:gans",
        "loop:foundational:resnet",
        "loop:foundational:attention",
        "loop:foundational:gpt3",
        "loop:foundational:bert",
        "loop:foundational:instructgpt",
        "loop:foundational:chain-of-thought",
        "loop:foundational:scratchpad",
        "loop:foundational:self-consistency",
        "loop:foundational:tot",
        "loop:foundational:least-to-most",
        "loop:foundational:react",
        "loop:foundational:toolformer",
        "loop:foundational:grokking",
        "loop:foundational:deepseek-r1",
    ]

    private static let bundledInteractiveLoopPaperIds: [String] = {
        let name = "curated-paper-catalog"
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CuratedPaperCatalogFile.self, from: data),
              !file.interactiveLoopPaperIds.isEmpty else {
            return fallbackInteractiveLoopPaperIds
        }
        return file.interactiveLoopPaperIds
    }()

    /// Curated `loop:` ids hidden from every catalog-driven list, the
    /// subway map, and the similarity graph. One source of truth lives in
    /// `HiddenPapers`.
    static var hiddenPaperIds: Set<String> { HiddenPapers.hiddenLoopIds }

    /// Stable `paper_id` values for the full curator-built loop catalog
    /// (ordered), with hidden papers removed.
    static var interactiveLoopPaperIds: [String] {
        bundledInteractiveLoopPaperIds.filter { !hiddenPaperIds.contains($0) }
    }

    /// Pairs for Explore, Discover search, similarity bootstrap (same ordering as IDs).
    static var allPrepared: [(paperId: String, content: DailyLoopContent)] {
        interactiveLoopPaperIds.compactMap { pid in
            guard let content = content(forPaperId: pid) else { return nil }
            return (pid, content)
        }
    }

    /// Curator loop by id. Does not resolve `arxiv:…` aliases—`PaperReadingExperience` handles CoT bridging and blueprints.
    static func content(forPaperId id: String) -> DailyLoopContent? {
        switch id {
        default:
            guard id.hasPrefix("loop:foundational:") else { return nil }
            let slug = String(id.dropFirst("loop:foundational:".count))
            return DailyLoopContent.foundational(slug: slug)
        }
    }
}
