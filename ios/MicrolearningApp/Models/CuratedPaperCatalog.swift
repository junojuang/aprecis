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
        "perceptron",
        "backprop",
        "lenet",
        "alexnet",
        "word2vec",
        "seq2seq",
        "gans",
        "resnet",
        "attention",
        "gpt3",
        "bert",
        "instructgpt",
        "chain-of-thought",
        "scratchpad",
        "self-consistency",
        "tree-of-thoughts",
        "least-to-most",
        "react",
        "toolformer",
        "grokking",
        "deepseek-r1",
        "vit",
        "ddpm",
        "clip",
        "stable-diffusion",
        "controlnet",
        "sam",
        "t5",
        "chinchilla",
        "llama",
        "palm",
        "mixtral",
        "reflexion",
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

    /// Curated paper ids hidden from every catalog-driven list, the
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

    /// Curator loop by readable paper id. Does not resolve `arxiv:...` aliases,
    /// `PaperReadingExperience` handles CoT bridging and blueprints.
    static func content(forPaperId id: String) -> DailyLoopContent? {
        switch id {
        case "perceptron", "backprop", "lenet", "alexnet", "word2vec",
             "seq2seq", "gans", "resnet", "attention", "gpt3", "bert",
             "instructgpt", "chain-of-thought", "scratchpad",
             "self-consistency", "least-to-most", "react", "toolformer",
             "grokking", "deepseek-r1":
            return DailyLoopContent.foundational(slug: id)
        case "tree-of-thoughts":
            return DailyLoopContent.foundational(slug: "tot")
        case "vit", "ddpm", "clip", "controlnet", "sam", "t5",
             "chinchilla", "llama", "palm", "mixtral", "reflexion":
            return DailyLoopContent.branch(category: "", slug: id)
        case "stable-diffusion":
            return DailyLoopContent.branch(category: "", slug: "sd")
        default:
            let parts = id.split(separator: ":").map(String.init)
            guard parts.count == 3, parts[0] == "loop" else { return nil }
            if parts[1] == "foundational" {
                return DailyLoopContent.foundational(slug: parts[2])
            }
            return DailyLoopContent.branch(category: parts[1], slug: parts[2])
        }
    }
}
