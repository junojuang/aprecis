import Foundation
import SwiftUI

// MARK: - Roadmap
//
// The Learn-tab map of AI research, drawn as a vertical climb. Foundation
// runs as a single trunk from bottom (Perceptron, 1958) to top (GPT-3,
// 2020). Above the trunk, three branches splay: Vision, Language,
// Reasoning. Every node sits in chronological order so each paper
// genuinely builds on the one below it.
//
// Free readers must climb in order, one paper at a time. Aprecis Plus
// members can tap any node directly to skip ahead.
//
// Branch papers are post-trunk in time (>= 2020) so the "builds on"
// claim holds even after the reader walks off the trunk.

enum Roadmap {

    // MARK: types

    struct Node: Identifiable, Hashable {
        let id: String          // matches paperId used by lessons / decks
        let title: String       // short label ("Attention")
        let slug: String        // bundlePaperId slug ("attention")
        let year: Int           // publication year (used in labels)
        let oneLiner: String    // a single sentence on what the paper does

        // Hashable on id only so SwiftUI ForEach stays stable across model
        // mutations.
        static func == (lhs: Node, rhs: Node) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    struct Branch: Identifiable {
        let id: String
        let title: String       // "Vision"
        let blurb: String       // 1–2 sentence positioning
        let accentHex: String
        let nodes: [Node]       // bottom-to-top reading order
        var accent: Color { Color(hex: accentHex) }
    }

    // MARK: trunk
    //
    // Foundation — 11 papers, strict chronological order so each entry
    // genuinely builds on what came before. Every paper here has a
    // bespoke LearningLesson shipped today, so the route always works.

    static let trunk: [Node] = [
        Node(id: "loop:foundational:perceptron", title: "Perceptron", slug: "perceptron", year: 1958,
             oneLiner: "One neuron that teaches itself by its own mistakes."),
        Node(id: "loop:foundational:backprop",   title: "Backprop",   slug: "backprop",   year: 1986,
             oneLiner: "How a network with a middle layer can learn anything."),
        Node(id: "loop:foundational:lenet",      title: "LeNet",      slug: "lenet",      year: 1998,
             oneLiner: "The first network that could really see."),
        Node(id: "loop:foundational:alexnet",    title: "AlexNet",    slug: "alexnet",    year: 2012,
             oneLiner: "Deep learning wins the world by a mile."),
        Node(id: "loop:foundational:word2vec",   title: "Word2Vec",   slug: "word2vec",   year: 2013,
             oneLiner: "Words become places on a map."),
        Node(id: "loop:foundational:gans",       title: "GANs",       slug: "gans",       year: 2014,
             oneLiner: "Two networks in a duel that teaches both."),
        Node(id: "loop:foundational:seq2seq",    title: "Seq2Seq",    slug: "seq2seq",    year: 2014,
             oneLiner: "One sentence in, a different sentence out."),
        Node(id: "loop:foundational:resnet",     title: "ResNet",     slug: "resnet",     year: 2015,
             oneLiner: "Let the signal skip ahead. Depth solved."),
        Node(id: "loop:foundational:attention",  title: "Attention",  slug: "attention",  year: 2017,
             oneLiner: "Every word reads every other word. The Transformer."),
        Node(id: "loop:foundational:bert",       title: "BERT",       slug: "bert",       year: 2018,
             oneLiner: "Read both sides at once."),
        Node(id: "loop:foundational:gpt3",       title: "GPT-3",      slug: "gpt3",       year: 2020,
             oneLiner: "A model so large that examples replace training."),
        Node(id: "loop:foundational:instructgpt", title: "InstructGPT", slug: "instructgpt", year: 2022,
             oneLiner: "Human feedback teaches it to follow what you ask."),
        Node(id: "loop:foundational:deepseek-r1", title: "DeepSeek-R1", slug: "deepseek-r1", year: 2025,
             oneLiner: "Reward right answers, and reasoning grows itself."),
    ]

    static let trunkBranch = Branch(
        id: "trunk",
        title: "Foundation",
        blurb: "Thirteen papers, sixty-seven years. The bedrock of everything you call AI. Start at Perceptron, climb to DeepSeek-R1.",
        accentHex: "1a8a8a",
        nodes: trunk
    )

    // MARK: branches
    //
    // Each branch starts strictly after the trunk's last paper (2020).
    // Six nodes deep so the map feels substantial without overwhelming.
    // None of these have bespoke lessons yet; nodes route through
    // DeckDestination so when the backend ingests them they light up
    // automatically.

    static let visionBranch = Branch(
        id: "vision",
        title: "Vision",
        blurb: "After the Transformer turned to images. From ViT to Stable Diffusion to Segment Anything.",
        accentHex: "7b4ba4",
        nodes: [
            Node(id: "loop:vision:vit",       title: "ViT",              slug: "vit",        year: 2020,
                 oneLiner: "Apply the Transformer to images. Conv nets get a rival."),
            Node(id: "loop:vision:ddpm",      title: "DDPM",             slug: "ddpm",       year: 2020,
                 oneLiner: "Generate images by gradually denoising noise."),
            Node(id: "loop:vision:clip",      title: "CLIP",             slug: "clip",       year: 2021,
                 oneLiner: "One model that knows what images and captions share."),
            Node(id: "loop:vision:sd",        title: "Stable Diffusion", slug: "sd",         year: 2022,
                 oneLiner: "Diffusion at scale, on consumer hardware, open weights."),
            Node(id: "loop:vision:controlnet",title: "ControlNet",       slug: "controlnet", year: 2023,
                 oneLiner: "Pose, sketch, depth: steer the diffusion model on demand."),
            Node(id: "loop:vision:sam",       title: "Segment Anything", slug: "sam",        year: 2023,
                 oneLiner: "One click on any object, in any photo. Universal segmentation."),
        ]
    )

    static let languageBranch = Branch(
        id: "language",
        title: "Language",
        blurb: "After GPT-3. The race to align, scale, and open the large language model.",
        accentHex: "2d7abf",
        nodes: [
            Node(id: "loop:language:t5",          title: "T5",          slug: "t5",          year: 2020,
                 oneLiner: "Every NLP task as text-to-text. One model, many jobs."),
            Node(id: "loop:language:chinchilla",  title: "Chinchilla",  slug: "chinchilla",  year: 2022,
                 oneLiner: "We were training models too big and too short. Here's the fix."),
            Node(id: "loop:language:palm",        title: "PaLM",        slug: "palm",        year: 2022,
                 oneLiner: "Scale to 540 billion parameters. New abilities emerge."),
            Node(id: "loop:language:llama",       title: "LLaMA",       slug: "llama",       year: 2023,
                 oneLiner: "Frontier capability at open-source weights."),
            Node(id: "loop:language:mixtral",     title: "Mixtral",     slug: "mixtral",     year: 2023,
                 oneLiner: "Mixture of experts: run a 47B model at the speed of 13B."),
        ]
    )

    static let reasoningBranch = Branch(
        id: "reasoning",
        title: "Reasoning",
        blurb: "After the model can talk. Teaching it to think, plan, and use tools.",
        accentHex: "c07014",
        nodes: [
            Node(id: "loop:reasoning:cot",         title: "Chain-of-Thought", slug: "cot",        year: 2022,
                 oneLiner: "Add 'let's think step by step' and accuracy jumps."),
            Node(id: "loop:reasoning:selfconsist", title: "Self-Consistency", slug: "selfconsist", year: 2022,
                 oneLiner: "Sample many reasoning paths, take the majority vote."),
            Node(id: "loop:reasoning:react",       title: "ReAct",            slug: "react",      year: 2022,
                 oneLiner: "Interleave thinking and acting in a tight loop."),
            Node(id: "loop:reasoning:toolformer",  title: "Toolformer",       slug: "toolformer", year: 2023,
                 oneLiner: "Models that decide for themselves when to call a tool."),
            Node(id: "loop:reasoning:tot",         title: "Tree of Thoughts", slug: "tot",        year: 2023,
                 oneLiner: "Branch on every reasoning step. Search the tree."),
            Node(id: "loop:reasoning:reflexion",   title: "Reflexion",        slug: "reflexion",  year: 2023,
                 oneLiner: "After a failure, write the lesson down. Try again."),
        ]
    )

    static let branches: [Branch] = [visionBranch, languageBranch, reasoningBranch]

    // MARK: lookup

    static func branch(withID id: String) -> Branch? {
        if id == trunkBranch.id { return trunkBranch }
        return branches.first { $0.id == id }
    }

    static func node(withID id: String) -> Node? {
        if let n = trunk.first(where: { $0.id == id }) { return n }
        for b in branches {
            if let n = b.nodes.first(where: { $0.id == id }) { return n }
        }
        return nil
    }

    static func branch(containing nodeId: String) -> Branch? {
        if trunk.contains(where: { $0.id == nodeId }) { return trunkBranch }
        return branches.first { $0.nodes.contains(where: { $0.id == nodeId }) }
    }
}

// MARK: - Access

enum RoadmapNodeState {
    case completed      // reader has read the paper
    case current        // the next chronological node for this reader
    case unlocked       // tappable for Plus members
    case lockedAhead    // skipping requires Plus
    case comingSoon     // node defined but no shipped content
}

@MainActor
enum RoadmapAccess {

    static func state(
        of node: Roadmap.Node,
        in branch: Roadmap.Branch,
        isPlus: Bool,
        progressStore: ReadingProgressStore
    ) -> RoadmapNodeState {

        let alreadyRead = progressStore.progress(for: node.id) >= 0.98
        if alreadyRead { return .completed }

        let hasContent = bundlePaperId(slug: node.slug) != nil
        if !hasContent {
            return .comingSoon
        }

        if isPlus { return .unlocked }

        if branch.id == Roadmap.trunkBranch.id {
            return isFirstUnreadInBranch(node, in: branch, store: progressStore)
                ? .current : .lockedAhead
        }

        if !isTrunkComplete(store: progressStore) { return .lockedAhead }

        return isFirstUnreadInBranch(node, in: branch, store: progressStore)
            ? .current : .lockedAhead
    }

    static func isTrunkComplete(store: ReadingProgressStore) -> Bool {
        Roadmap.trunk.allSatisfy { store.progress(for: $0.id) >= 0.98 }
    }

    static func doneCount(in branch: Roadmap.Branch, store: ReadingProgressStore) -> Int {
        branch.nodes.reduce(into: 0) { acc, n in
            if store.progress(for: n.id) >= 0.98 { acc += 1 }
        }
    }

    private static func isFirstUnreadInBranch(
        _ node: Roadmap.Node,
        in branch: Roadmap.Branch,
        store: ReadingProgressStore
    ) -> Bool {
        for n in branch.nodes {
            if store.progress(for: n.id) < 0.98 {
                return n.id == node.id
            }
        }
        return false
    }
}
