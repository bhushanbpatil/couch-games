//
//  TurnResult.swift
//  Couch Games
//

import Foundation

struct TurnResult: Identifiable, Equatable {
    let id: UUID
    let roundIndex: Int
    let playerID: UUID
    let playerName: String
    let target: TimeInterval
    let guess: TimeInterval
    let error: TimeInterval
    let points: Int

    init(
        id: UUID = UUID(),
        roundIndex: Int,
        playerID: UUID,
        playerName: String,
        target: TimeInterval,
        guess: TimeInterval,
        error: TimeInterval,
        points: Int
    ) {
        self.id = id
        self.roundIndex = roundIndex
        self.playerID = playerID
        self.playerName = playerName
        self.target = target
        self.guess = guess
        self.error = error
        self.points = points
    }
}
