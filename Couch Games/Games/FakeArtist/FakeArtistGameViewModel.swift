//
//  FakeArtistGameViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class FakeArtistGameViewModel {
    var phase: FakeArtistPhase = .setup
    var players: [FakeArtistPlayer] = []
    var prompt = FakeArtistWordBank.randomPrompt()
    var strokes: [FakeArtistStroke] = []
    var strokeIndex = 0

    // Role reveal
    var revealIndex = 0
    var showingRole = false

    // Vote
    var voteMode: FakeArtistVoteMode = .passPhone
    var voteModeLocked = false
    var voteCollectorIndex = 0
    var votes: [UUID: UUID] = [:]
    var accusedPlayerID: UUID?
    var guessOptions: [String] = []
    var outcome: FakeArtistOutcome?

    var totalStrokes: Int {
        players.count * FakeArtistSetupConfig.drawRounds
    }

    var currentRound: Int {
        guard !players.isEmpty else { return 1 }
        return strokeIndex / players.count + 1
    }

    var currentDrawer: FakeArtistPlayer? {
        guard !players.isEmpty, strokeIndex < totalStrokes else { return nil }
        return players[strokeIndex % players.count]
    }

    var currentRevealPlayer: FakeArtistPlayer? {
        guard players.indices.contains(revealIndex) else { return nil }
        return players[revealIndex]
    }

    var currentVoter: FakeArtistPlayer? {
        guard players.indices.contains(voteCollectorIndex) else { return nil }
        return players[voteCollectorIndex]
    }

    var fakeArtist: FakeArtistPlayer? {
        players.first { $0.isFakeArtist }
    }

    var accusedPlayer: FakeArtistPlayer? {
        guard let id = accusedPlayerID else { return nil }
        return players.first { $0.id == id }
    }

    var navigationTitle: String {
        switch phase {
        case .roleReveal: return "Roles"
        case .drawHandoff, .drawing: return "Round \(currentRound)"
        case .revealDrawing: return "The Drawing"
        case .fakeGuess: return "Final Guess"
        case .gameOver: return "Game Over"
        default: return "Fake Artist"
        }
    }

    var moderatorScript: String {
        switch phase {
        case .roleReveal:
            return "Pass the phone. Each player sees the secret word — except one Fake Artist."
        case .drawHandoff:
            return "Pass the phone to \(currentDrawer?.name ?? "the next artist")."
        case .drawing:
            return "Draw your line, then tap End Turn when you're finished."
        case .revealDrawing:
            return "Study the drawing. Each color belongs to one player. Who doesn't know the word?"
        case .voteModeChoice:
            return "How should you vote for the Fake Artist?"
        case .voteCollect:
            return "Pass the phone — \(currentVoter?.name ?? "player") votes privately."
        case .voteGod:
            return "Moderator — tap who the group thinks is the Fake Artist."
        case .fakeGuess:
            return "You were caught! Guess the secret word to steal the win."
        case .gameOver:
            return outcomeMessage
        default:
            return ""
        }
    }

    var outcomeMessage: String {
        switch outcome {
        case .artistsWin:
            return "The Fake Artist was caught and guessed wrong. Artists win!"
        case .fakeArtistUndetected:
            return "Wrong person accused. The Fake Artist wins!"
        case .fakeArtistGuessedWord:
            return "The Fake Artist guessed the word. They win!"
        case .none:
            return ""
        }
    }

    func ink(for player: FakeArtistPlayer) -> FakeArtistColorPalette.Ink {
        FakeArtistColorPalette.ink(for: player.inkIndex)
    }

    func startGame(config: FakeArtistSetupConfig) {
        guard config.validationError == nil else { return }

        prompt = FakeArtistWordBank.randomPrompt()
        guessOptions = FakeArtistWordBank.guessOptions(for: prompt)

        let fakeIndex = Int.random(in: 0..<config.totalPlayers)

        players = config.playerNames.enumerated().map { index, rawName in
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? "Player \(index + 1)" : trimmed
            return FakeArtistPlayer(
                name: name,
                inkIndex: index,
                isFakeArtist: index == fakeIndex
            )
        }

        strokes = []
        strokeIndex = 0
        revealIndex = 0
        showingRole = false
        votes = [:]
        voteCollectorIndex = 0
        voteModeLocked = false
        accusedPlayerID = nil
        outcome = nil
        phase = .roleReveal
    }

    func revealRoleForCurrentPlayer() {
        showingRole = true
    }

    func confirmRoleSeen() {
        showingRole = false
        if revealIndex + 1 < players.count {
            revealIndex += 1
        } else {
            phase = .drawHandoff
        }
    }

    func beginDrawingTurn() {
        phase = .drawing
    }

    func commitStroke(points: [CGPoint]) {
        guard let drawer = currentDrawer, points.count >= 2 else { return }

        strokes.append(FakeArtistStroke(playerID: drawer.id, points: points))
        strokeIndex += 1

        if strokeIndex >= totalStrokes {
            phase = .revealDrawing
        } else {
            phase = .drawHandoff
        }
    }

    func continueFromReveal() {
        votes = [:]
        voteCollectorIndex = 0
        phase = voteModeLocked ? (voteMode == .godOverride ? .voteGod : .voteCollect) : .voteModeChoice
    }

    func chooseVoteMode(_ mode: FakeArtistVoteMode) {
        voteMode = mode
        voteModeLocked = true
        voteCollectorIndex = 0
        votes = [:]
        phase = mode == .godOverride ? .voteGod : .voteCollect
    }

    func submitVote(targetID: UUID) {
        guard let voter = currentVoter else { return }
        votes[voter.id] = targetID
        if voteCollectorIndex + 1 < players.count {
            voteCollectorIndex += 1
        } else {
            finishVoting()
        }
    }

    func submitGodVote(targetID: UUID) {
        accusedPlayerID = targetID
        resolveAccusation()
    }

    func submitGuess(word: String) {
        if word == prompt.word {
            outcome = .fakeArtistGuessedWord
        } else {
            outcome = .artistsWin
        }
        phase = .gameOver
    }

    func resetToSetup() {
        players = []
        strokes = []
        phase = .setup
        outcome = nil
    }

    // MARK: - Private

    private func finishVoting() {
        var tally: [UUID: Int] = [:]
        for targetID in votes.values {
            tally[targetID, default: 0] += 1
        }
        accusedPlayerID = tally.max(by: { $0.value < $1.value })?.key
        resolveAccusation()
    }

    private func resolveAccusation() {
        guard let accused = accusedPlayer else {
            outcome = .fakeArtistUndetected
            phase = .gameOver
            return
        }

        if accused.isFakeArtist {
            phase = .fakeGuess
        } else {
            outcome = .fakeArtistUndetected
            phase = .gameOver
        }
    }
}
