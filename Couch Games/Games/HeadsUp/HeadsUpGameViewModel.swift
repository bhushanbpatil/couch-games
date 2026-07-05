//
//  HeadsUpGameViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class HeadsUpGameViewModel {
    var phase: HeadsUpPhase = .setup
    var config = HeadsUpSetupConfig(deckIDs: [])
    var playerName = ""

    private var wordQueue: [String] = []
    private var timerTask: Task<Void, Never>?
    private var lastMarkTime = Date.distantPast
    private let markCooldown: TimeInterval = 0.2

    var currentWord: String?
    var secondsRemaining = 60
    var roundResults: [HeadsUpCardResult] = []

    var correctCount: Int {
        roundResults.filter(\.wasCorrect).count
    }

    var passedCount: Int {
        roundResults.filter { !$0.wasCorrect }.count
    }

    var navigationTitle: String {
        switch phase {
        case .ready: return "Get Ready"
        case .playing: return "Heads Up!"
        case .roundSummary: return "Round Over"
        default: return "Heads Up"
        }
    }

    var moderatorScript: String {
        switch phase {
        case .ready:
            return "Hold the phone on your forehead. Friends can see the word — you can't."
        case .playing:
            if config.controlMode.usesVolume {
                return "Volume up = got it · Volume down = pass."
            }
            return "Tap Pass or Got It when you're ready."
        case .roundSummary:
            return "Nice round! Pass the phone to the next player."
        default:
            return ""
        }
    }

    func startGame(config: HeadsUpSetupConfig) {
        guard config.validationError == nil else { return }

        self.config = config
        playerName = config.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        wordQueue = HeadsUpWordBank.shuffledWords(for: config.deckIDs)
        roundResults = []
        currentWord = nil
        secondsRemaining = config.roundDuration
        phase = .ready
    }

    func beginRound() {
        roundResults = []
        currentWord = drawNextWord()
        secondsRemaining = config.roundDuration
        lastMarkTime = .distantPast
        phase = .playing
        startTimer()
    }

    func markCorrect() {
        guard phase == .playing, let word = currentWord else { return }
        guard Date().timeIntervalSince(lastMarkTime) >= markCooldown else { return }
        lastMarkTime = Date()
        roundResults.append(HeadsUpCardResult(word: word, wasCorrect: true))
        advanceWord()
    }

    func markPass() {
        guard phase == .playing, let word = currentWord else { return }
        guard Date().timeIntervalSince(lastMarkTime) >= markCooldown else { return }
        lastMarkTime = Date()
        roundResults.append(HeadsUpCardResult(word: word, wasCorrect: false))
        advanceWord()
    }

    func endRoundEarly() {
        guard phase == .playing else { return }
        stopTimer()
        phase = .roundSummary
    }

    func playAgain() {
        wordQueue = HeadsUpWordBank.shuffledWords(for: config.deckIDs)
        beginRound()
    }

    func resetToSetup() {
        stopTimer()
        phase = .setup
        roundResults = []
        currentWord = nil
    }

    // MARK: - Private

    private func advanceWord() {
        currentWord = drawNextWord()
    }

    private func drawNextWord() -> String? {
        guard !wordQueue.isEmpty else { return nil }
        return wordQueue.removeFirst()
    }

    private func startTimer() {
        stopTimer()
        timerTask = Task {
            while !Task.isCancelled, secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                secondsRemaining -= 1
                if secondsRemaining <= 0 {
                    finishRound()
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func finishRound() {
        stopTimer()
        phase = .roundSummary
    }
}
