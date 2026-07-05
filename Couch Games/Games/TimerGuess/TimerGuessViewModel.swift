//
//  TimerGuessViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class TimerGuessViewModel {
    var phase: GamePhase = .setup
    var config: GameConfig?
    var currentRoundIndex = 0
    var currentPlayerIndex = 0
    var currentTarget: TimeInterval = 0
    var lastTurnResult: TurnResult?
    var turnHistory: [TurnResult] = []
    var showLeaderboard = false

    private var memorizeStart: Date?

    var currentPlayer: Player? {
        guard let config, config.players.indices.contains(currentPlayerIndex) else { return nil }
        return config.players[currentPlayerIndex]
    }

    var leaderboard: [Player] {
        guard let config else { return [] }
        return config.players.sorted { lhs, rhs in
            if lhs.totalScore != rhs.totalScore { return lhs.totalScore > rhs.totalScore }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var roundLabel: String {
        guard let config else { return "" }
        return "Round \(currentRoundIndex + 1) of \(config.roundCount)"
    }

    var passPhoneMessage: String? {
        guard let config, let player = currentPlayer else { return nil }
        if phase == .showTarget {
            return "Pass the phone to \(player.name)"
        }
        return nil
    }

    func makeDefaultConfig(playerCount: Int = 2, roundCount: Int = 3) -> GameConfig {
        let count = clamp(playerCount, GameConfig.minPlayers, GameConfig.maxPlayers)
        let rounds = clamp(roundCount, GameConfig.minRounds, GameConfig.maxRounds)
        let players = (1...count).map { Player(name: "Player \($0)") }
        return GameConfig(roundCount: rounds, players: players)
    }

    func startGame(config: GameConfig) {
        let validated = GameConfig(
            roundCount: clamp(config.roundCount, GameConfig.minRounds, GameConfig.maxRounds),
            players: config.players.enumerated().map { index, player in
                let trimmed = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = trimmed.isEmpty ? "Player \(index + 1)" : trimmed
                return Player(id: player.id, name: name)
            }
        )
        guard validated.players.count >= GameConfig.minPlayers else { return }

        self.config = validated
        currentRoundIndex = 0
        currentPlayerIndex = 0
        turnHistory = []
        lastTurnResult = nil
        beginRound()
    }

    func beginRound() {
        guard config != nil else { return }
        currentPlayerIndex = 0
        currentTarget = randomTarget()
        memorizeStart = nil
        lastTurnResult = nil
        phase = .showTarget
    }

    func ready() {
        guard phase == .showTarget else { return }
        memorizeStart = Date()
        phase = .memorizing
    }

    func stop() {
        guard phase == .memorizing, let start = memorizeStart, var config else { return }

        let guess = Date().timeIntervalSince(start)
        let player = config.players[currentPlayerIndex]
        let error = abs(guess - currentTarget)
        let points = Scoring.points(target: currentTarget, guess: guess)

        let result = TurnResult(
            roundIndex: currentRoundIndex,
            playerID: player.id,
            playerName: player.name,
            target: currentTarget,
            guess: guess,
            error: error,
            points: points
        )

        if let playerIndex = config.players.firstIndex(where: { $0.id == player.id }) {
            config.players[playerIndex].totalScore += points
            config.players[playerIndex].roundScores.append(points)
        }

        self.config = config
        lastTurnResult = result
        turnHistory.append(result)
        memorizeStart = nil
        phase = .turnResult
    }

    func advanceFromTurnResult() {
        guard var config else { return }

        if currentPlayerIndex + 1 < config.players.count {
            currentPlayerIndex += 1
            memorizeStart = nil
            phase = .showTarget
            return
        }

        if currentRoundIndex + 1 < config.roundCount {
            currentRoundIndex += 1
            phase = .roundSummary
            return
        }

        phase = .gameOver
    }

    func advanceFromRoundSummary() {
        beginRound()
    }

    func resetToSetup() {
        config = nil
        currentRoundIndex = 0
        currentPlayerIndex = 0
        currentTarget = 0
        lastTurnResult = nil
        turnHistory = []
        memorizeStart = nil
        phase = .setup
        showLeaderboard = false
    }

    private func randomTarget() -> TimeInterval {
        let hundredths = Int.random(in: 100...1000)
        return TimeInterval(hundredths) / 100.0
    }

    private func clamp(_ value: Int, _ min: Int, _ max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }
}
