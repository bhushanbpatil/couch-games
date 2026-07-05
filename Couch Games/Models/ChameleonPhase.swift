//
//  ChameleonPhase.swift
//  Couch Games
//

import Foundation

enum ChameleonPhase: Equatable {
    case setup
    case roleReveal
    case discussion
    case voteModeChoice
    case voteCollect
    case voteGod
    case chameleonGuess
    case gameOver
}

enum ChameleonVoteMode: Equatable {
    case passPhone
    case godOverride
}

enum ChameleonIntelMode: String, CaseIterable, Identifiable, Codable {
    case completeBlind
    case categoryOnly
    case wordGrid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completeBlind: return "Complete Blind"
        case .categoryOnly: return "Category Only"
        case .wordGrid: return "Word Grid"
        }
    }

    var subtitle: String {
        switch self {
        case .completeBlind: return "Word Spy knows nothing — pure bluff"
        case .categoryOnly: return "Word Spy sees the topic, not the words"
        case .wordGrid: return "Classic — Word Spy sees all 16 words"
        }
    }
}

enum ChameleonOutcome: Equatable {
    case innocentsWin
    case chameleonUndetected
    case chameleonGuessedWord
}
