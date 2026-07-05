//
//  GameConfig.swift
//  Couch Games
//

import Foundation

struct GameConfig: Equatable {
    static let minPlayers = 2
    static let maxPlayers = 8
    static let minRounds = 1
    static let maxRounds = 10

    var roundCount: Int
    var players: [Player]

    var playerCount: Int { players.count }
}
