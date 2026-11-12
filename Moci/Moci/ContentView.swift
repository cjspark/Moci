//
//  ContentView.swift
//  Moci
//
//  Created by ljuan on 2026/11/11.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            ImportView()
                .tabItem {
                    Label("Import", systemImage: "plus.square.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Deck.self, Card.self, Chapter.self, ReviewLog.self, DailyStats.self],
            inMemory: true
        )
}
