import Foundation
import SwiftData

// Codable structs matching the import JSON schema
struct ImportData: Codable {
    let deck: DeckInfo
    let chapters: [ChapterInfo]
    let words: [WordInfo]

    struct DeckInfo: Codable {
        let title: String
        let language: String
        let glossLanguage: String

        enum CodingKeys: String, CodingKey {
            case title, language
            case glossLanguage = "gloss_language"
        }
    }

    struct ChapterInfo: Codable {
        let index: Int
        let title: String
    }

    struct WordInfo: Codable {
        let lemma: String
        let surfaceForm: String
        let reading: String
        let pos: String
        let meaning: String
        let examples: [ExampleInfo]
        let sourceChapter: Int
        let extra: [String: String]
        let aiGenerated: Bool

        enum CodingKeys: String, CodingKey {
            case lemma, reading, pos, meaning, examples, extra
            case surfaceForm    = "surface_form"
            case sourceChapter  = "source_chapter"
            case aiGenerated    = "ai_generated"
        }

        // Tolerant decoding: all fields except lemma and meaning are optional
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            lemma         = try c.decode(String.self, forKey: .lemma)
            meaning       = try c.decode(String.self, forKey: .meaning)
            surfaceForm   = (try? c.decode(String.self, forKey: .surfaceForm)) ?? lemma
            reading       = (try? c.decode(String.self, forKey: .reading))     ?? ""
            pos           = (try? c.decode(String.self, forKey: .pos))         ?? ""
            examples      = (try? c.decode([ExampleInfo].self, forKey: .examples)) ?? []
            sourceChapter = (try? c.decode(Int.self, forKey: .sourceChapter))  ?? 1
            extra         = (try? c.decode([String: String].self, forKey: .extra)) ?? [:]
            aiGenerated   = (try? c.decode(Bool.self, forKey: .aiGenerated))   ?? false
        }
    }

    struct ExampleInfo: Codable {
        let text: String
        let translation: String
    }
}

enum ImportError: LocalizedError {
    case invalidJSON(String)
    case emptyWordList

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail): return "Invalid JSON: \(detail)"
        case .emptyWordList:           return "No words found in the file."
        }
    }
}

@MainActor
func importDeck(from data: Data, context: ModelContext) throws -> Deck {
    let importData: ImportData
    do {
        importData = try JSONDecoder().decode(ImportData.self, from: data)
    } catch {
        throw ImportError.invalidJSON(error.localizedDescription)
    }

    guard !importData.words.isEmpty else { throw ImportError.emptyWordList }

    let deck = Deck(
        title: importData.deck.title,
        language: importData.deck.language,
        glossLanguage: importData.deck.glossLanguage
    )
    context.insert(deck)

    // Build chapter index
    var chapterMap: [Int: Chapter] = [:]
    for info in importData.chapters {
        let chapter = Chapter(index: info.index, title: info.title)
        chapter.deck = deck
        context.insert(chapter)
        chapterMap[info.index] = chapter
    }

    // Deduplicate by (lemma, pos) and create cards
    var seen = Set<String>()
    for wordInfo in importData.words {
        let key = "\(wordInfo.lemma.lowercased())|\(wordInfo.pos)"
        guard !seen.contains(key) else { continue }
        seen.insert(key)

        let examples = wordInfo.examples.map { Example(text: $0.text, translation: $0.translation) }
        let card = Card(
            lemma: wordInfo.lemma,
            surfaceForm: wordInfo.surfaceForm,
            reading: wordInfo.reading,
            pos: wordInfo.pos,
            meaning: wordInfo.meaning,
            examples: examples,
            extra: wordInfo.extra,
            aiGenerated: wordInfo.aiGenerated
        )
        card.deckID = deck.id
        card.deck = deck
        card.sourceChapter = chapterMap[wordInfo.sourceChapter]
        context.insert(card)
    }

    try context.save()
    return deck
}
