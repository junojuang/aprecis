import Foundation
import CoreGraphics

// MARK: - ForceLayout
//
// Minimal Verlet-style force simulation. Computes node positions for the
// Explore "Neighborhoods" lens by iterating spring + repulsion + cluster
// gravity forces over ~200 ticks. Designed to run once on first appear
// and cache the result, not to animate continuously.

enum ForceLayout {

    struct Input {
        let ids: [String]
        let edges: [(a: String, b: String, weight: Double)]
        let clusters: [String: String]   // node id -> cluster id
        let bounds: CGSize
    }

    struct Result {
        let positions: [String: CGPoint]
        let clusterCentroids: [String: CGPoint]
    }

    /// Cached result keyed by `signature`. Avoids recomputing the
    /// simulation each time the view appears.
    private static var cache: [String: Result] = [:]

    static func cached(signature: String) -> Result? { cache[signature] }

    /// Run the simulation. `signature` is used as a memoization key, so
    /// pass something like `"neighborhoods.v1.\(ids.count)"`.
    @discardableResult
    static func run(_ input: Input,
                    iterations: Int = 240,
                    signature: String) -> Result {
        if let hit = cache[signature] { return hit }

        // Deterministic seed: ring layout per cluster, then jitter.
        var pos: [String: CGPoint] = [:]
        let clusterIds = Array(Set(input.clusters.values)).sorted()
        let center = CGPoint(x: input.bounds.width / 2, y: input.bounds.height / 2)
        let outerRadius = min(input.bounds.width, input.bounds.height) * 0.42

        for (ci, cid) in clusterIds.enumerated() {
            let angle = 2 * .pi * Double(ci) / Double(clusterIds.count)
            let cx = center.x + outerRadius * CGFloat(cos(angle))
            let cy = center.y + outerRadius * CGFloat(sin(angle))
            let members = input.ids.filter { input.clusters[$0] == cid }
            for (mi, id) in members.enumerated() {
                let a = 2 * .pi * Double(mi) / Double(max(members.count, 1))
                pos[id] = CGPoint(
                    x: cx + 55 * CGFloat(cos(a)),
                    y: cy + 55 * CGFloat(sin(a))
                )
            }
        }

        // Edge lookup for spring forces.
        var edgesByNode: [String: [(other: String, weight: Double)]] = [:]
        for e in input.edges {
            edgesByNode[e.a, default: []].append((e.b, e.weight))
            edgesByNode[e.b, default: []].append((e.a, e.weight))
        }

        // Simulation params. Tuned for ~14 nodes on iPhone canvas. Aim
        // is generous whitespace so labels never overlap.
        let repulsion: CGFloat   = 8500     // Coulomb constant
        let springK: CGFloat     = 0.022    // pull along edges
        let restLenBase: CGFloat = 165      // baseline edge length
        let clusterPull: CGFloat = 0.014    // gentle pull to cluster centroid
        let damping: CGFloat     = 0.86
        let centerPull: CGFloat  = 0.003    // very light pull to canvas center
        let minNodeDist: CGFloat = 110      // hard floor for any pair

        var velocity: [String: CGSize] = [:]

        for _ in 0..<iterations {
            // Compute cluster centroids each step.
            var centroidSum: [String: CGPoint] = [:]
            var centroidCount: [String: Int] = [:]
            for id in input.ids {
                guard let cid = input.clusters[id], let p = pos[id] else { continue }
                centroidSum[cid, default: .zero].x += p.x
                centroidSum[cid, default: .zero].y += p.y
                centroidCount[cid, default: 0] += 1
            }
            var centroids: [String: CGPoint] = [:]
            for (cid, sum) in centroidSum {
                let n = CGFloat(centroidCount[cid] ?? 1)
                centroids[cid] = CGPoint(x: sum.x / n, y: sum.y / n)
            }

            // Accumulate forces.
            var force: [String: CGSize] = [:]

            // Repulsion (all pairs).
            for i in 0..<input.ids.count {
                let a = input.ids[i]
                guard let pa = pos[a] else { continue }
                for j in (i+1)..<input.ids.count {
                    let b = input.ids[j]
                    guard let pb = pos[b] else { continue }
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    var dist2 = dx*dx + dy*dy
                    if dist2 < 1 { dist2 = 1 }
                    let dist = sqrt(dist2)
                    let f = repulsion / dist2
                    let fx = (dx / dist) * f
                    let fy = (dy / dist) * f
                    force[a, default: .zero].width  += fx
                    force[a, default: .zero].height += fy
                    force[b, default: .zero].width  -= fx
                    force[b, default: .zero].height -= fy
                }
            }

            // Springs (along edges). Higher weight → shorter rest length.
            for e in input.edges {
                guard let pa = pos[e.a], let pb = pos[e.b] else { continue }
                let restLen = restLenBase * CGFloat(1.0 - min(0.55, e.weight * 0.6))
                let dx = pb.x - pa.x
                let dy = pb.y - pa.y
                let dist = max(1, sqrt(dx*dx + dy*dy))
                let displacement = dist - restLen
                let f = springK * displacement * CGFloat(0.5 + e.weight)
                let fx = (dx / dist) * f
                let fy = (dy / dist) * f
                force[e.a, default: .zero].width  += fx
                force[e.a, default: .zero].height += fy
                force[e.b, default: .zero].width  -= fx
                force[e.b, default: .zero].height -= fy
            }

            // Cluster gravity + center pull.
            for id in input.ids {
                guard let p = pos[id] else { continue }
                if let cid = input.clusters[id], let c = centroids[cid] {
                    force[id, default: .zero].width  += (c.x - p.x) * clusterPull
                    force[id, default: .zero].height += (c.y - p.y) * clusterPull
                }
                force[id, default: .zero].width  += (center.x - p.x) * centerPull
                force[id, default: .zero].height += (center.y - p.y) * centerPull
            }

            // Integrate.
            for id in input.ids {
                var v = velocity[id] ?? .zero
                let f = force[id] ?? .zero
                v.width  = (v.width  + f.width)  * damping
                v.height = (v.height + f.height) * damping
                // Clamp velocity to prevent runaway.
                let speed = sqrt(v.width*v.width + v.height*v.height)
                if speed > 14 {
                    v.width  *= 14 / speed
                    v.height *= 14 / speed
                }
                velocity[id] = v
                var p = pos[id] ?? center
                p.x += v.width
                p.y += v.height
                pos[id] = p
            }

            // Hard minimum-distance pass: any pair closer than
            // `minNodeDist` is pushed apart along their connecting line.
            // Runs every step so the final layout is guaranteed legible.
            for i in 0..<input.ids.count {
                let a = input.ids[i]
                guard var pa = pos[a] else { continue }
                for j in (i+1)..<input.ids.count {
                    let b = input.ids[j]
                    guard var pb = pos[b] else { continue }
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    let dist = sqrt(dx*dx + dy*dy)
                    if dist < minNodeDist {
                        let overlap = (minNodeDist - dist) / 2 + 0.5
                        if dist > 0.01 {
                            pa.x += (dx / dist) * overlap
                            pa.y += (dy / dist) * overlap
                            pb.x -= (dx / dist) * overlap
                            pb.y -= (dy / dist) * overlap
                        } else {
                            pa.x += overlap; pb.x -= overlap
                        }
                        pos[a] = pa
                        pos[b] = pb
                    }
                }
            }
        }

        // Recompute final centroids for caller (used for cluster halo).
        var centroidSum: [String: CGPoint] = [:]
        var centroidCount: [String: Int] = [:]
        for id in input.ids {
            guard let cid = input.clusters[id], let p = pos[id] else { continue }
            centroidSum[cid, default: .zero].x += p.x
            centroidSum[cid, default: .zero].y += p.y
            centroidCount[cid, default: 0] += 1
        }
        var centroids: [String: CGPoint] = [:]
        for (cid, sum) in centroidSum {
            let n = CGFloat(centroidCount[cid] ?? 1)
            centroids[cid] = CGPoint(x: sum.x / n, y: sum.y / n)
        }

        let result = Result(positions: pos, clusterCentroids: centroids)
        cache[signature] = result
        return result
    }

    static func invalidate() { cache.removeAll() }
}
