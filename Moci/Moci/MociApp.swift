//
//  MociApp.swift
//  Moci
//
//  Created by ljuan on 2026/11/11.
//

import SwiftUI
import SwiftData

@main
struct MociApp: App {
    let container: ModelContainer = {
        let schema = Schema([Deck.self, Card.self, Chapter.self, ReviewLog.self, DailyStats.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
