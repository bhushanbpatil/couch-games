//
//  BluffBarrelPhase.swift
//  Couch Games
//

import Foundation

enum BluffBarrelPhase: Equatable {
    case setup
    case roundIntro
    case mustPlay
    case respond
    case reveal
    case roulette
    case rouletteResult
    case gameOver
}

struct BluffBarrelLastPlay: Equatable {
    let playerID: UUID
    let cards: [BluffBarrelCard]
}

struct BluffBarrelSetupConfig: Equatable {
    static let minPlayers = 2
    static let maxPlayers = 4
    static let handSize = 5
    static let maxPlayCount = 3

    var playerNames: [String]

    var totalPlayers: Int { playerNames.count }

    var validationError: String? {
        guard totalPlayers >= Self.minPlayers, totalPlayers <= Self.maxPlayers else {
            return "Use \(Self.minPlayers)–\(Self.maxPlayers) players."
        }
        return nil
    }
}
