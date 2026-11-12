import SwiftUI

struct FlashcardView: View {
    let card: Card
    @Binding var isFlipped: Bool
    let onRate: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Card (tap to flip)
            ZStack {
                CardFront(card: card)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 90 : 0), axis: (1, 0, 0), perspective: 0.5)

                CardBack(card: card)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -90), axis: (1, 0, 0), perspective: 0.5)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(duration: 0.35)) {
                    isFlipped.toggle()
                }
            }

            // Rating buttons appear after flip
            if isFlipped {
                RatingBar(card: card, onRate: onRate)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Front

private struct CardFront: View {
    let card: Card

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(card.surfaceForm.isEmpty ? card.lemma : card.surfaceForm)
                .font(.system(size: 54, weight: .bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 24)

            if !card.reading.isEmpty && card.reading != card.lemma && card.reading != card.surfaceForm {
                Text(card.reading)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Tap to reveal")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 14, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Back

private struct CardBack: View {
    let card: Card

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Word header
                VStack(spacing: 6) {
                    Text(card.surfaceForm.isEmpty ? card.lemma : card.surfaceForm)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    if !card.reading.isEmpty && card.reading != card.lemma {
                        Text(card.reading)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // POS chip + meaning
                VStack(alignment: .leading, spacing: 8) {
                    if !card.pos.isEmpty {
                        Text(card.pos)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    Text(card.meaning)
                        .font(.title3.weight(.medium))
                }

                // Extra fields (JLPT, gender, etc.)
                let extraItems = card.extra.sorted { $0.key < $1.key }
                if !extraItems.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(extraItems, id: \.key) { key, value in
                            Text("\(key): \(value)")
                                .font(.caption)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Examples
                let examples = card.examples.prefix(2)
                if !examples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Examples")
                            .font(.caption.uppercaseSmallCaps())
                            .foregroundStyle(.secondary)
                        ForEach(Array(examples)) { ex in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ex.text)
                                    .font(.subheadline)
                                Text(ex.translation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 14, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Rating Bar

private struct RatingBar: View {
    let card: Card
    let onRate: (Int) -> Void

    private struct RatingOption {
        let rating: Int
        let label: String
        let color: Color
    }

    private let options: [RatingOption] = [
        .init(rating: 1, label: "Again",  color: .red),
        .init(rating: 2, label: "Hard",   color: .orange),
        .init(rating: 3, label: "Good",   color: .green),
        .init(rating: 4, label: "Easy",   color: .blue),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.rating) { opt in
                Button {
                    onRate(opt.rating)
                } label: {
                    VStack(spacing: 3) {
                        Text(LocalizedStringKey(opt.label))
                            .font(.subheadline.bold())
                        Text(intervalLabel(rating: opt.rating))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(opt.color.opacity(0.12))
                    .foregroundStyle(opt.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(opt.color.opacity(0.25), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func intervalLabel(rating: Int) -> String {
        let result = FSRS.schedule(card: card, rating: rating)
        let days = result.scheduledDays
        if days == 0 { return "< 10m" }
        if days == 1 { return "1d" }
        if days < 30 { return "\(days)d" }
        let months = days / 30
        return "\(months)mo"
    }
}
