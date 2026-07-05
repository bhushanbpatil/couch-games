//
//  FakeArtistWordBank.swift
//  Couch Games
//

import Foundation

struct FakeArtistPrompt: Equatable, Codable {
    let category: String
    let word: String
}

private struct FakeArtistWordFile: Codable {
    let version: Int
    let prompts: [FakeArtistPrompt]
}

enum FakeArtistWordBank {
    private static let fallback: [FakeArtistPrompt] = [
        FakeArtistPrompt(category: "Animal", word: "Cat"),
        FakeArtistPrompt(category: "Food", word: "Pizza")
    ]

    private static var cachedPrompts: [FakeArtistPrompt]?

    static var promptCount: Int {
        allPrompts.count
    }

    static var categories: [String] {
        Array(Set(allPrompts.map(\.category))).sorted()
    }

    private static var allPrompts: [FakeArtistPrompt] {
        if let cachedPrompts {
            return cachedPrompts
        }
        let loaded = loadFromBundle()
        cachedPrompts = loaded
        return loaded
    }

    static func randomPrompt() -> FakeArtistPrompt {
        allPrompts.randomElement() ?? fallback[0]
    }

    static func randomPrompt(in category: String) -> FakeArtistPrompt {
        let matches = allPrompts.filter { $0.category == category }
        return matches.randomElement() ?? randomPrompt()
    }

    static func guessOptions(for prompt: FakeArtistPrompt, count: Int = 6) -> [String] {
        let pool = allPrompts
        let sameCategory = pool.filter { $0.category == prompt.category && $0.word != prompt.word }.map(\.word)
        let others = pool.filter { $0.category != prompt.category }.map(\.word)

        var options = Set<String>()
        options.insert(prompt.word)

        for word in sameCategory.shuffled() where options.count < count {
            options.insert(word)
        }
        for word in others.shuffled() where options.count < count {
            options.insert(word)
        }
        return Array(options).shuffled()
    }

    private static func loadFromBundle() -> [FakeArtistPrompt] {
        guard let url = Bundle.main.url(forResource: "FakeArtistWords", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FakeArtistWordFile.self, from: data),
              !file.prompts.isEmpty else {
            return fallback
        }
        return file.prompts
    }
}
