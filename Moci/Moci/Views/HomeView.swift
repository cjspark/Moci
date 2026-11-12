import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]
    @State private var studyDeck: Deck?
    @State private var showStudy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryHeader
                    if decks.isEmpty {
                        emptyState
                    } else {
                        ForEach(decks) { deck in
                            DeckCardView(deck: deck) {
                                studyDeck = deck
                                showStudy = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("墨词")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showStudy) {
            if let deck = studyDeck {
                StudyView(deck: deck)
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 0) {
            let totalNew = decks.reduce(0) { $0 + min($1.newCardsCount, 20) }
            let totalDue = decks.reduce(0) { $0 + $1.dueCardsCount }

            StatTile(value: totalNew, label: "New", color: .blue)
            Divider().frame(height: 40)
            StatTile(value: totalDue, label: "Review", color: .orange)
            Divider().frame(height: 40)
            StatTile(value: totalNew + totalDue, label: "Today", color: .purple)
        }
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)
                .padding(.top, 60)
            Text("No decks yet")
                .font(.title3.bold())
            Text("Go to Import tab to add your first deck")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

struct StatTile: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(color)
            Text(LocalizedStringKey(label))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DeckCardView: View {
    let deck: Deck
    let onStudy: () -> Void

    private var newCount: Int  { min(deck.newCardsCount, 20) }
    private var dueCount: Int  { deck.dueCardsCount }
    private var totalStudy: Int { newCount + dueCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text("\(deck.cards.count) words · \(deck.language.uppercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                LanguageBadge(language: deck.language)
            }

            HStack(spacing: 16) {
                Label("\(newCount) new", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Label("\(dueCount) review", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button(action: onStudy) {
                HStack {
                    Image(systemName: totalStudy > 0 ? "play.fill" : "checkmark.circle.fill")
                    Text(totalStudy > 0 ? "Start Study (\(totalStudy))" : "All done today!")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .disabled(totalStudy == 0)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct LanguageBadge: View {
    let language: String

    var body: some View {
        Text(language.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }
}
