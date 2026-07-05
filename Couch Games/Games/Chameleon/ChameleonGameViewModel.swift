//
//  ChameleonGameViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class ChameleonGameViewModel {
    var phase: ChameleonPhase = .setup
    var players: [ChameleonPlayer] = []
    var round = ChameleonWordBank.randomRound()
    var chameleonIntel: ChameleonIntelMode = .categoryOnly
    var isConnectedHost = false

    // Role reveal
    var revealIndex = 0
    var showingRole = false

    // Discussion
    var discussionIndex = 0

    // Vote
    var voteMode: ChameleonVoteMode = .passPhone
    var voteModeLocked = false
    var voteCollectorIndex = 0
    var votes: [UUID: UUID] = [:]
    var accusedPlayerID: UUID?
    var outcome: ChameleonOutcome?

    var currentRevealPlayer: ChameleonPlayer? {
        guard players.indices.contains(revealIndex) else { return nil }
        return players[revealIndex]
    }

    var currentSpeaker: ChameleonPlayer? {
        guard players.indices.contains(discussionIndex) else { return nil }
        return players[discussionIndex]
    }

    var currentVoter: ChameleonPlayer? {
        guard players.indices.contains(voteCollectorIndex) else { return nil }
        return players[voteCollectorIndex]
    }

    var chameleon: ChameleonPlayer? {
        players.first { $0.isChameleon }
    }

    var accusedPlayer: ChameleonPlayer? {
        guard let id = accusedPlayerID else { return nil }
        return players.first { $0.id == id }
    }

    var gridWords: [String] {
        Array(round.topic.words.prefix(ChameleonSetupConfig.wordsPerTopic))
    }

    var showsCategoryDuringGame: Bool {
        chameleonIntel != .completeBlind
    }

    var navigationTitle: String {
        switch phase {
        case .roleReveal: return "Roles"
        case .discussion: return "Discussion"
        case .chameleonGuess: return "Final Guess"
        case .gameOver: return "Game Over"
        default: return GameDisplayNames.wordSpy
        }
    }

    var moderatorScript: String {
        switch phase {
        case .roleReveal:
            return "Pass the phone. Everyone sees the secret word — except one Word Spy."
        case .discussion:
            if showsCategoryDuringGame {
                return "Say ONE word related to the secret. Don't make it too obvious."
            }
            return "Say ONE word based on what others say. Don't give yourself away."
        case .voteModeChoice:
            return "How should you vote for the Word Spy?"
        case .voteCollect:
            if isConnectedHost {
                return "Waiting for \(currentVoter?.name ?? "player") to vote on their phone."
            }
            return "Pass the phone — \(currentVoter?.name ?? "player") votes privately."
        case .voteGod:
            return "Moderator — tap who the group thinks is the Word Spy."
        case .chameleonGuess:
            return "You were caught! Pick the secret word from the grid to steal the win."
        case .gameOver:
            return outcomeMessage
        default:
            return ""
        }
    }

    var outcomeMessage: String {
        switch outcome {
        case .innocentsWin:
            return "The Word Spy was caught and guessed wrong. Everyone else wins!"
        case .chameleonUndetected:
            return "Wrong person accused. The Word Spy wins!"
        case .chameleonGuessedWord:
            return "The Word Spy guessed the word. They win!"
        case .none:
            return ""
        }
    }

    func startGame(config: ChameleonSetupConfig) {
        guard config.validationError == nil else { return }

        round = ChameleonWordBank.randomRound()
        chameleonIntel = config.chameleonIntel
        let chameleonIndex = Int.random(in: 0..<config.totalPlayers)

        players = config.playerNames.enumerated().map { index, rawName in
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? "Player \(index + 1)" : trimmed
            return ChameleonPlayer(
                name: name,
                isChameleon: index == chameleonIndex
            )
        }

        revealIndex = 0
        showingRole = false
        discussionIndex = 0
        votes = [:]
        voteCollectorIndex = 0
        voteModeLocked = false
        accusedPlayerID = nil
        outcome = nil
        phase = .roleReveal
    }

    func startConnectedGame(roomPlayers: [RoomPlayer], intel: ChameleonIntelMode) {
        guard roomPlayers.count >= ChameleonSetupConfig.minPlayers else { return }

        round = ChameleonWordBank.randomRound()
        chameleonIntel = intel
        isConnectedHost = true
        let chameleonIndex = Int.random(in: 0..<roomPlayers.count)

        players = roomPlayers.enumerated().map { index, roomPlayer in
            ChameleonPlayer(
                id: roomPlayer.id,
                name: roomPlayer.name,
                isChameleon: index == chameleonIndex
            )
        }

        revealIndex = 0
        showingRole = false
        discussionIndex = 0
        votes = [:]
        voteCollectorIndex = 0
        voteModeLocked = true
        accusedPlayerID = nil
        outcome = nil
        phase = .discussion
    }

    func beginConnectedVoting() {
        votes = [:]
        voteCollectorIndex = 0
        voteMode = .passPhone
        phase = .voteCollect
    }

    func receiveConnectedVote(voterID: UUID, targetID: UUID) {
        votes[voterID] = targetID
        if voteCollectorIndex + 1 < players.count {
            voteCollectorIndex += 1
        } else {
            finishVoting()
        }
    }

    func revealRoleForCurrentPlayer() {
        showingRole = true
    }

    func confirmRoleSeen() {
        showingRole = false
        if revealIndex + 1 < players.count {
            revealIndex += 1
        } else {
            discussionIndex = 0
            phase = .discussion
        }
    }

    func advanceDiscussion() {
        if discussionIndex + 1 < players.count {
            discussionIndex += 1
        } else if isConnectedHost {
            votes = [:]
            voteCollectorIndex = 0
            beginConnectedVoting()
        } else {
            votes = [:]
            voteCollectorIndex = 0
            phase = voteModeLocked
                ? (voteMode == .godOverride ? .voteGod : .voteCollect)
                : .voteModeChoice
        }
    }

    func chooseVoteMode(_ mode: ChameleonVoteMode) {
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

    func submitChameleonGuess(word: String) {
        if word == round.secretWord {
            outcome = .chameleonGuessedWord
        } else {
            outcome = .innocentsWin
        }
        phase = .gameOver
    }

    func resetToSetup() {
        players = []
        phase = .setup
        outcome = nil
        isConnectedHost = false
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
            outcome = .chameleonUndetected
            phase = .gameOver
            return
        }

        if accused.isChameleon {
            phase = .chameleonGuess
        } else {
            outcome = .chameleonUndetected
            phase = .gameOver
        }
    }
}
