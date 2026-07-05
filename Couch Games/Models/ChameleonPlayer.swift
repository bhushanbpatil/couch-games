//
//  ChameleonPlayer.swift
//  Couch Games
//

import Foundation

struct ChameleonPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isChameleon: Bool

    init(id: UUID = UUID(), name: String, isChameleon: Bool = false) {
        self.id = id
        self.name = name
        self.isChameleon = isChameleon
    }
}

struct ChameleonSetupConfig: Equatable {
    static let minPlayers = 4
    static let maxPlayers = 10
    static let wordsPerTopic = 16

    var playerNames: [String]
    var chameleonIntel: ChameleonIntelMode = .categoryOnly

    var totalPlayers: Int { playerNames.count }

    var validationError: String? {
        guard totalPlayers >= Self.minPlayers, totalPlayers <= Self.maxPlayers else {
            return "Use \(Self.minPlayers)–\(Self.maxPlayers) players."
        }
        return nil
    }
}
