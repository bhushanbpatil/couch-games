//
//  HeadsUpWordBank.swift
//  Couch Games
//

import Foundation

struct HeadsUpDeck: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let icon: String
    let words: [String]
}

private struct HeadsUpDeckFile: Codable {
    let version: Int
    let decks: [HeadsUpDeck]
}

enum HeadsUpWordBank {
    private static let fallbackDecks: [HeadsUpDeck] = [
        HeadsUpDeck(id: "animals", title: "Animals", icon: "pawprint.fill", words: ["Cat", "Dog", "Elephant", "Giraffe", "Penguin", "Dolphin"])
    ]

    private static var cachedDecks: [HeadsUpDeck]?

    static var decks: [HeadsUpDeck] {
        if let cachedDecks {
            return cachedDecks
        }
        let loaded = loadFromBundle()
        cachedDecks = loaded
        return loaded
    }

    static var deckCount: Int { decks.count }

    static var wordCount: Int {
        decks.reduce(0) { $0 + $1.words.count }
    }

    static func deck(id: String) -> HeadsUpDeck? {
        decks.first { $0.id == id }
    }

    static func shuffledWords(for deckIDs: Set<String>) -> [String] {
        let words = decks
            .filter { deckIDs.contains($0.id) }
            .flatMap(\.words)
        return words.isEmpty ? fallbackDecks.flatMap(\.words).shuffled() : words.shuffled()
    }

    private static func loadFromBundle() -> [HeadsUpDeck] {
        guard let url = Bundle.main.url(forResource: "HeadsUpDecks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(HeadsUpDeckFile.self, from: data),
              !file.decks.isEmpty else {
            return fallbackDecks
        }
        return file.decks
    }
}
