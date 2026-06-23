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
        "loop:foundational:perceptron":   [],
        "loop:foundational:backprop":     ["loop:foundational:perceptron"],
        "loop:foundational:lenet":        ["loop:foundational:backprop"],
        "loop:foundational:alexnet":      ["loop:foundational:lenet"],
        "loop:foundational:resnet":       ["loop:foundational:alexnet"],
        "loop:foundational:gans":         ["loop:foundational:backprop"],
        "loop:foundational:word2vec":     ["loop:foundational:backprop"],
        "loop:foundational:seq2seq":      ["loop:foundational:word2vec"],
        "loop:foundational:attention":    ["loop:foundational:seq2seq"],
        "loop:foundational:gpt3":         ["loop:foundational:attention"],
        "loop:foundational:instructgpt":  ["loop:foundational:gpt3"],
        "loop:foundational:chain-of-thought": ["loop:foundational:gpt3"],
        "loop:foundational:scratchpad":   ["loop:foundational:gpt3"],
        "loop:foundational:self-consistency": ["loop:foundational:chain-of-thought"],
        "loop:foundational:tot":          ["loop:foundational:chain-of-thought", "loop:foundational:self-consistency"],
        "loop:foundational:least-to-most": ["loop:foundational:chain-of-thought"],
        "loop:foundational:react":        ["loop:foundational:chain-of-thought"],
        "loop:foundational:toolformer":   ["loop:foundational:react"],
        "loop:foundational:grokking":     ["loop:foundational:backprop"],
        "loop:foundational:deepseek-r1":  ["loop:foundational:instructgpt", "loop:foundational:chain-of-thought", "loop:foundational:tot"],
        "loop:systems:flashattention":    ["loop:foundational:attention"],
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
