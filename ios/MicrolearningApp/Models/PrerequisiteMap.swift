import Foundation

/// Static prerequisite graph for curated papers. Each entry lists the
/// paper IDs that should be read first. Used by the Explore graph view
/// and the prereq-order sort.
///
/// Edges are directional: `prereqs[X]` returns papers that lead INTO X.
/// The graph is acyclic by construction; if a cycle ever sneaks in, the
/// topo-sort helper degrades to a stable input order.
enum PrerequisiteMap {

    /// `child : [parent_ids]`. Parents must be read before child.
    static let prereqs: [String: [String]] = [
        // Foundational chain
        "perceptron":   [],
        "backprop":     ["perceptron"],
        "lenet":        ["backprop"],
        "alexnet":      ["lenet"],
        "resnet":       ["alexnet"],
        "gans":         ["backprop"],
        "word2vec":     ["backprop"],
        "seq2seq":      ["word2vec"],
        "attention":    ["seq2seq"],
        "gpt3":         ["attention"],
        "instructgpt":  ["gpt3"],
        "chain-of-thought": ["gpt3"],
        "scratchpad":   ["gpt3"],
        "self-consistency": ["chain-of-thought"],
        "tree-of-thoughts":          ["chain-of-thought", "self-consistency"],
        "least-to-most": ["chain-of-thought"],
        "react":        ["chain-of-thought"],
        "toolformer":   ["react"],
        "grokking":     ["backprop"],
        "deepseek-r1":  ["instructgpt", "chain-of-thought", "tree-of-thoughts"],
        "vit":                ["attention", "resnet"],
        "ddpm":               ["gans"],
        "clip":               ["vit", "gpt3"],
        "stable-diffusion":                 ["ddpm", "clip"],
        "controlnet":         ["stable-diffusion"],
        "sam":                ["vit"],
        "t5":               ["attention", "bert"],
        "chinchilla":       ["gpt3"],
        "palm":             ["gpt3"],
        "llama":            ["chinchilla"],
        "mixtral":          ["llama"],
        "reflexion":       ["react"],
        "flashattention":    ["attention"],
    ]

    /// All paper IDs that participate in the DAG.
    static let nodes: Set<String> = {
        var s = Set(prereqs.keys)
        for parents in prereqs.values { s.formUnion(parents) }
        return s
    }()

    static func parents(of id: String) -> [String] { prereqs[id] ?? [] }

    /// Layer index = longest path from a root (in-degree 0) to this node.
    /// Roots sit at layer 0. Returns 0 for nodes outside the DAG.
    static func layer(of id: String) -> Int {
        guard nodes.contains(id) else { return 0 }
        let parents = parents(of: id)
        if parents.isEmpty { return 0 }
        return 1 + (parents.map { layer(of: $0) }.max() ?? 0)
    }

    /// Topological order (parents first). Items not in the DAG are
    /// appended at the end in their original order, so callers can pass
    /// the full deck list and get a stable arrangement.
    static func topoSort<T>(_ items: [T], id: (T) -> String) -> [T] {
        let known   = items.filter { nodes.contains(id($0)) }
        let unknown = items.filter { !nodes.contains(id($0)) }
        let sorted  = known.sorted { a, b in
            let la = layer(of: id(a)), lb = layer(of: id(b))
            if la != lb { return la < lb }
            return id(a) < id(b)
        }
        return sorted + unknown
    }

    /// Nodes grouped by layer, parents-first. Used by the graph layout
    /// to place rows of papers.
    static func layered() -> [[String]] {
        let grouped = Dictionary(grouping: nodes) { layer(of: $0) }
        return grouped.keys.sorted().map { key in
            (grouped[key] ?? []).sorted()
        }
    }
}
