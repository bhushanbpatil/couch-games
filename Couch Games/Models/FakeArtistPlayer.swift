//
//  FakeArtistStroke.swift
//  Couch Games
//

import Foundation
import CoreGraphics

struct FakeArtistStroke: Identifiable, Equatable {
    let id: UUID
    let playerID: UUID
    let points: [CGPoint]

    init(id: UUID = UUID(), playerID: UUID, points: [CGPoint]) {
        self.id = id
        self.playerID = playerID
        self.points = points
    }
}

struct FakeArtistPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var inkIndex: Int
    var isFakeArtist: Bool

    init(id: UUID = UUID(), name: String, inkIndex: Int, isFakeArtist: Bool = false) {
        self.id = id
        self.name = name
        self.inkIndex = inkIndex
        self.isFakeArtist = isFakeArtist
    }
}

struct FakeArtistSetupConfig: Equatable {
    static let minPlayers = 4
    static let maxPlayers = 10
    static let drawRounds = 2

    var playerNames: [String]

    var totalPlayers: Int { playerNames.count }

    var validationError: String? {
        guard totalPlayers >= Self.minPlayers, totalPlayers <= Self.maxPlayers else {
            return "Use \(Self.minPlayers)–\(Self.maxPlayers) players."
        }
        return nil
    }
}
