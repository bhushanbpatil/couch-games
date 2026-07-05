//
//  MafiaPlayer.swift
//  Couch Games
//

import Foundation

struct MafiaPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var role: MafiaRole
    var isAlive: Bool

    init(id: UUID = UUID(), name: String, role: MafiaRole, isAlive: Bool = true) {
        self.id = id
        self.name = name
        self.role = role
        self.isAlive = isAlive
    }
}

struct MafiaSetupConfig: Equatable {
    static let minPlayers = 4
    static let maxPlayers = 16

    var totalPlayers: Int
    var mafiaCount: Int
    var policeCount: Int
    var nurseCount: Int
    var playerNames: [String]

    var villagerCount: Int {
        totalPlayers - mafiaCount - policeCount - nurseCount
    }

    var validationError: String? {
        guard totalPlayers >= Self.minPlayers, totalPlayers <= Self.maxPlayers else {
            return "Use \(Self.minPlayers)–\(Self.maxPlayers) players."
        }
        guard mafiaCount >= 1 else { return "You need at least 1 Mafia." }
        guard villagerCount >= 1 else { return "Too many special roles — need at least 1 Villager." }
        guard mafiaCount < (totalPlayers - mafiaCount) else {
            return "Mafia cannot equal or outnumber everyone else at start."
        }
        return nil
    }
}
