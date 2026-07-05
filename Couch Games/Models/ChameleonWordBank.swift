//
//  ChameleonWordBank.swift
//  Couch Games
//

import Foundation

struct ChameleonTopic: Equatable, Codable {
    let category: String
    let words: [String]
}

struct ChameleonRound: Equatable {
    let topic: ChameleonTopic
    let secretWord: String
    let secretIndex: Int
}

private struct ChameleonTopicFile: Codable {
    let version: Int
    let topics: [ChameleonTopic]
}

enum ChameleonWordBank {
    private static let fallbackTopics: [ChameleonTopic] = [
        ChameleonTopic(
            category: "Pizza Toppings",
            words: ["Pepperoni", "Mushroom", "Olives", "Pineapple", "Sausage", "Bacon", "Onion", "Peppers", "Ham", "Chicken", "Jalapeño", "Basil", "Tomato", "Cheese", "Garlic", "Spinach"]
        )
    ]

    private static var cachedTopics: [ChameleonTopic]?

    static var topicCount: Int {
        allTopics.count
    }

    static var wordCount: Int {
        allTopics.reduce(0) { $0 + $1.words.count }
    }

    static var categories: [String] {
        allTopics.map(\.category).sorted()
    }

    private static var allTopics: [ChameleonTopic] {
        if let cachedTopics {
            return cachedTopics
        }
        let loaded = loadFromBundle()
        cachedTopics = loaded
        return loaded
    }

    static func randomRound() -> ChameleonRound {
        let source = allTopics.randomElement() ?? fallbackTopics[0]
        let grid = Array(source.words.shuffled().prefix(ChameleonSetupConfig.wordsPerTopic))
        let index = Int.random(in: 0..<grid.count)

        return ChameleonRound(
            topic: ChameleonTopic(category: source.category, words: grid),
            secretWord: grid[index],
            secretIndex: index
        )
    }

    private static func loadFromBundle() -> [ChameleonTopic] {
        guard let url = Bundle.main.url(forResource: "ChameleonTopics", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ChameleonTopicFile.self, from: data) else {
            return fallbackTopics
        }

        let valid = file.topics.filter { $0.words.count >= ChameleonSetupConfig.wordsPerTopic }
        return valid.isEmpty ? fallbackTopics : valid
    }
}
