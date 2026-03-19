import SwiftUI

// MARK: - CardView (router)

struct CardView: View {
    let card: Card
    let deck: CardDeck

    var body: some View {
        switch card.type {
        case .hook:     HookCard(card: card, deck: deck)
        case .coreIdea: CoreIdeaCard(card: card)
        case .eli5:     ELI5Card(card: card)
        case .analogy:  AnalogyCard(card: card)
        case .visual:   VisualCard(card: card)
        case .takeaway: TakeawayCard(card: card)
        }
    }
}

// MARK: - Shared

private struct CardBackground: View {
    let colors: [Color]

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06)
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.85)
        }
        .ignoresSafeArea()
    }
}

private struct TypeLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(color.opacity(0.7))
            .kerning(2)
    }
}

// MARK: - Hook Card

private struct HookCard: View {
    let card: Card
    let deck: CardDeck
    @State private var appeared = false

    var body: some View {
        ZStack {
            CardBackground(colors: [
                Color(red: 0.18, green: 0.06, blue: 0.40),
                Color(red: 0.06, green: 0.04, blue: 0.12)
            ])
            RadialGradient(colors: [Color.purple.opacity(0.25), .clear],
                           center: .top, startRadius: 0, endRadius: 320)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                TypeLabel(text: "New Paper", color: .purple)
                    .padding(.bottom, 20)

                Text(card.text ?? "")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(5)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Spacer()
                Spacer()

                HStack {
                    if let src = deck.source {
                        Text(src.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.25))
                            .kerning(1.5)
                    }
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("swipe up")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 52)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Core Idea Card

private struct CoreIdeaCard: View {
    let card: Card
    @State private var appeared = false

    private var ideas: [String] {
        (card.text ?? "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression) }
    }

    var body: some View {
        ZStack {
            CardBackground(colors: [
                Color(red: 0.08, green: 0.06, blue: 0.30),
                Color(red: 0.04, green: 0.04, blue: 0.10)
            ])
            RadialGradient(colors: [Color.indigo.opacity(0.2), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 350)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                TypeLabel(text: "Core Ideas", color: .indigo)
                    .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 22) {
                    ForEach(Array(ideas.enumerated()), id: \.offset) { i, idea in
                        HStack(alignment: .top, spacing: 18) {
                            Text("\(i + 1)")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundStyle(Color.indigo.opacity(0.5))
                                .frame(width: 38, alignment: .leading)
                            Text(idea)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.8).delay(0.08 + Double(i) * 0.08),
                            value: appeared
                        )
                    }
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 52)
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

// MARK: - ELI5 Card

private struct ELI5Card: View {
    let card: Card
    @State private var appeared = false

    var body: some View {
        ZStack {
            CardBackground(colors: [
                Color(red: 0.22, green: 0.12, blue: 0.00),
                Color(red: 0.07, green: 0.05, blue: 0.03)
            ])
            RadialGradient(colors: [Color.orange.opacity(0.18), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 380)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack(spacing: 12) {
                    Text("🧠").font(.system(size: 30))
                    TypeLabel(text: "ELI5", color: .orange)
                }
                .padding(.bottom, 22)

                Text(card.text ?? card.description ?? "")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 52)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Analogy Card

private struct AnalogyCard: View {
    let card: Card
    @State private var appeared = false

    var body: some View {
        ZStack {
            CardBackground(colors: [
                Color(red: 0.00, green: 0.14, blue: 0.22),
                Color(red: 0.03, green: 0.05, blue: 0.09)
            ])
            RadialGradient(colors: [Color.cyan.opacity(0.18), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 350)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack(spacing: 12) {
                    Text("💡").font(.system(size: 28))
                    TypeLabel(text: "Analogy", color: .cyan)
                }
                .padding(.bottom, 16)

                Text("\u{201C}")
                    .font(.system(size: 72, weight: .black, design: .serif))
                    .foregroundStyle(Color.cyan.opacity(0.12))
                    .padding(.bottom, -28)

                Text(card.text ?? card.description ?? "")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 52)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Visual Card

private struct VisualCard: View {
    let card: Card

    var body: some View {
        ZStack {
            CardBackground(colors: [
                Color(red: 0.00, green: 0.10, blue: 0.20),
                Color(red: 0.03, green: 0.05, blue: 0.09)
            ])
            RadialGradient(colors: [Color.blue.opacity(0.15), .clear],
                           center: .center, startRadius: 0, endRadius: 400)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                TypeLabel(text: "Visual", color: .blue)

                if let visual = card.visual {
                    VisualRendererView(schema: visual)
                        .frame(maxHeight: 340)
                } else if let desc = card.description {
                    Text(desc)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 52)
        }
    }
}

// MARK: - Takeaway Card

private struct TakeawayCard: View {
    let card: Card
    @State private var appeared = false

    var body: some View {
        ZStack {
            CardBackground(colors: [
                Color(red: 0.02, green: 0.18, blue: 0.09),
                Color(red: 0.03, green: 0.06, blue: 0.04)
            ])
            RadialGradient(colors: [Color.green.opacity(0.2), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 380)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.green.opacity(0.8))
                    TypeLabel(text: "Why It Matters", color: .green)
                }
                .padding(.bottom, 22)

                Text(card.text ?? card.description ?? "")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)

                Spacer()

                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.18))
                        Text("Swipe sideways for next paper")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.18))
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 52)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}
