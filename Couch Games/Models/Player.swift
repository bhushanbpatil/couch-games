//
//  Player.swift
//  Couch Games
//

import Foundation

struct Player: Identifiable, Equatable {
    let id: UUID
    var name: String
    var totalScore: Int
    var roundScores: [Int]

    init(id: UUID = UUID(), name: String, totalScore: Int = 0, roundScores: [Int] = []) {
        self.id = id
        self.name = name
        self.totalScore = totalScore
        self.roundScores = roundScores
    }
}
