import SwiftUI

/// Concept cover image: shows the DALL-E illustration when available,
/// falls back to a styled gradient with the app's color palette.
struct ConceptCoverImage: View {
    let imageUrl: String?
    let colorIndex: Int

    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    fallbackGradient
                case .empty:
                    shimmer
                @unknown default:
                    fallbackGradient
                }
            }
        } else {
            fallbackGradient
        }
    }

    // ── Fallback gradient using app palette ──────────────────────────────────

    private var fallbackGradient: some View {
        ZStack {
            gradient
            // Subtle geometric decoration
            Circle()
                .fill(accentColor.opacity(0.12))
                .frame(width: 80, height: 80)
                .offset(x: 30, y: -10)
            Circle()
                .fill(accentColor.opacity(0.08))
                .frame(width: 50, height: 50)
                .offset(x: -20, y: 15)
            Circle()
                .fill(Color(hex: "e8a020").opacity(0.18))
                .frame(width: 14, height: 14)
                .offset(x: -35, y: -20)
        }
    }

    private var gradient: LinearGradient {
        switch colorIndex % 4 {
        case 0:
            return LinearGradient(
                colors: [Color(hex: "d0eeee"), Color(hex: "e5f4f4")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            return LinearGradient(
                colors: [Color(hex: "fde8c0"), Color(hex: "fef3e2")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(
                colors: [Color(hex: "e4d4f0"), Color(hex: "f0e8f5")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(
                colors: [Color(hex: "d4e8d0"), Color(hex: "e8f5e4")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var accentColor: Color {
        switch colorIndex % 4 {
        case 0: return Color(hex: "1a8a8a")
        case 1: return Color(hex: "c07014")
        case 2: return Color(hex: "7b4ba4")
        default: return Color(hex: "2a7a4a")
        }
    }

    // ── Shimmer loading placeholder ───────────────────────────────────────────

    private var shimmer: some View {
        ShimmerView()
    }
}

private struct ShimmerView: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        ZStack {
            Color(hex: "e8e3da")
            Color.white.opacity(0.45)
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(x: 3)
                        .offset(x: shimmerOffset * 400)
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
}
