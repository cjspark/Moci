import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showFilePicker = false
    @State private var importError: String?
    @State private var showError = false
    @State private var importedDeck: Deck?
    @State private var showSuccess = false
    @State private var promptCopied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 32)

                        Text("Import Word List")
                            .font(.title2.bold())

                        Text("Generate a JSON file with any AI assistant,\nthen import it here to create a deck.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Import button
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Choose JSON File", systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    guideSection
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Import")
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Unknown error")
        }
        .alert("Imported!", isPresented: $showSuccess) {
            Button("Great!") {}
        } message: {
            if let deck = importedDeck {
                Text("'\(deck.title)' — \(deck.cards.count) words added.")
            }
        }
    }

    // MARK: - Guide section

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to use AI to generate your word list")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(steps, id: \.number) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.number)")
                            .font(.caption.bold())
                            .frame(width: 26, height: 26)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.subheadline.bold())
                            Text(step.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)

            Button {
                UIPasteboard.general.string = mociPromptTemplate
                promptCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    promptCopied = false
                }
            } label: {
                Label(
                    promptCopied ? "Copied!" : "Copy AI Prompt",
                    systemImage: promptCopied ? "checkmark" : "doc.on.doc"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: promptCopied)
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var steps: [(number: Int, title: String, description: String)] {
        [
            (1, "Copy the prompt",        "Tap the button below to copy the extraction prompt."),
            (2, "Open an AI assistant",   "Go to claude.ai, ChatGPT, or any AI chat tool."),
            (3, "Paste prompt + text",    "Paste the prompt, then paste your textbook chapter text after it."),
            (4, "Save the JSON output",   "Copy the AI's response, paste it into a text editor, save as .json"),
            (5, "Import here",            "Tap 'Choose JSON File' and select the file you just saved."),
        ]
    }

    // MARK: - File import handler

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                throw ImportError.invalidJSON("Could not access file.")
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)
            let deck = try importDeck(from: data, context: modelContext)
            importedDeck = deck
            showSuccess = true
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Prompt template

let mociPromptTemplate = """
You are a language learning editor. Extract vocabulary from the textbook text below.

Rules:
1. Prioritize words explicitly listed as vocabulary in the text. Then include meaningful content words.
2. lemma = dictionary/base form; surface_form = exact form in text.
3. If the text already has definitions or examples, use them as-is. Otherwise generate them and set ai_generated: true.
4. meaning must be in Chinese (简体中文), concise, up to 3 senses.
5. Return ONLY valid JSON — no markdown fences, no explanation.

JSON schema:
{
  "deck": {"title": "Book Title Here", "language": "ja", "gloss_language": "zh"},
  "chapters": [{"index": 1, "title": "Chapter Name"}],
  "words": [
    {
      "lemma": "", "surface_form": "", "reading": "", "pos": "",
      "meaning": "", "examples": [{"text": "", "translation": ""}],
      "source_chapter": 1, "extra": {}, "ai_generated": false
    }
  ]
}

Language codes: ja=Japanese, en=English, de=German, zh=Chinese, fr=French, ko=Korean
For Japanese extra fields: {"jlpt": "N5", "pitch": "0"}
For German extra fields: {"gender": "der", "plural": "Bücher"}

--- Textbook text to extract from: ---

"""
