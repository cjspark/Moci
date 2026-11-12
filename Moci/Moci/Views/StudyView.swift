import SwiftUI
import SwiftData

struct StudyView: View {
    let deck: Deck
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [Card] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var sessionNewCount = 0
    @State private var sessionReviewCount = 0

    private let dailyNewLimit = 20

    private var currentCard: Card? {
        currentIndex < queue.count ? queue[currentIndex] : nil
    }

    private var remaining: Int { max(0, queue.count - currentIndex) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                if let card = currentCard {
                    FlashcardView(card: card, isFlipped: $isFlipped, onRate: { rate in
                        processRating(card: card, rating: rate)
                    })
                    .padding(.vertical, 12)
                } else {
                    completionScreen
                }
            }
            .navigationTitle(deck.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(remaining) left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .onAppear(perform: buildQueue)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.secondary.opacity(0.15)
                Color.accentColor
                    .frame(width: geo.size.width * progressFraction)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .frame(height: 3)
    }

    private var progressFraction: Double {
        guard !queue.isEmpty else { return 1 }
        return min(1, Double(currentIndex) / Double(queue.count))
    }

    // MARK: - Completion screen

    private var completionScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Session Complete!")
                .font(.title.bold())

            VStack(spacing: 6) {
                if sessionNewCount > 0 {
                    Text("New words learned: \(sessionNewCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if sessionReviewCount > 0 {
                    Text("Cards reviewed: \(sessionReviewCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Logic

    private func buildQueue() {
        let now = Date()
        var result: [Card] = []

        // Due review cards first, sorted by overdue-ness
        let due = deck.activeCards
            .filter { $0.fsrsState != .new && $0.due <= now }
            .sorted { $0.due < $1.due }
        result.append(contentsOf: due)

        // New cards up to daily limit
        let new = deck.activeCards
            .filter { $0.fsrsState == .new }
            .prefix(dailyNewLimit)
        result.append(contentsOf: new)

        queue = result
    }

    private func processRating(card: Card, rating: Int) {
        let wasNew = card.fsrsState == .new
        let result = FSRS.schedule(card: card, rating: rating)

        // Write review log
        let log = ReviewLog(rating: rating, elapsedDays: result.elapsedDays, scheduledDays: result.scheduledDays)
        log.card = card
        modelContext.insert(log)

        // Apply FSRS result
        card.apply(result)

        // Session counters
        if wasNew { sessionNewCount += 1 }
        else       { sessionReviewCount += 1 }

        // Re-queue "Again" cards at end of session
        if rating == 1 {
            queue.append(card)
        }

        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.2)) {
            isFlipped = false
            currentIndex += 1
        }
    }
}
