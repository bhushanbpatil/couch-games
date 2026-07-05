//
//  ResistancePlayer.swift
//  Couch Games
//

import Foundation

struct ResistancePlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var role: ResistanceRole

    init(id: UUID = UUID(), name: String, role: ResistanceRole) {
        self.id = id
        self.name = name
        self.role = role
    }
}

struct ResistanceSetupConfig: Equatable {
    static let minPlayers = 5
    static let maxPlayers = 10

    var gameMode: ResistanceGameMode
    var playerNames: [String]

    var totalPlayers: Int { playerNames.count }

    var spyCount: Int {
        ResistanceMissionRules.spyCount(for: totalPlayers)
    }

    var validationError: String? {
        guard totalPlayers >= Self.minPlayers, totalPlayers <= Self.maxPlayers else {
            return "Use \(Self.minPlayers)–\(Self.maxPlayers) players."
        }
        return nil
    }
}
