//
//  BluffBarrelGameViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class BluffBarrelGameViewModel {
    var phase: BluffBarrelPhase = .setup
    var players: [BluffBarrelPlayer] = []
    var tableRank: BluffBarrelRank = .king
    var activePlayerIndex = 0
    var lastPlay: BluffBarrelLastPlay?
    var lastPlayCount = 0
    var revealedCards: [BluffBarrelCard] = []
    var accusedPlayerID: UUID?
    var callerPlayerID: UUID?
    var lied: Bool?
    var rouletteTargetID: UUID?
    var lastRouletteHit = false
    var winnerID: UUID?
    var isConnectedHost = false

    var alivePlayers: [BluffBarrelPlayer] {
        players.filter(\.isAlive)
    }

    var activePlayer: BluffBarrelPlayer? {
        guard players.indices.contains(activePlayerIndex) else { return nil }
        let player = players[activePlayerIndex]
        return player.isAlive ? player : nil
    }

    var rouletteTarget: BluffBarrelPlayer? {
        guard let id = rouletteTargetID else { return nil }
        return players.first { $0.id == id }
    }

    var navigationTitle: String {
        switch phase {
        case .roundIntro: return "New Round"
        case .reveal: return "Reveal"
        case .roulette: return "Barrel"
        case .rouletteResult: return "Result"
        case .gameOver: return "Game Over"
        default: return GameDisplayNames.bluffAndBarrel
        }
    }

    var moderatorScript: String {
        switch phase {
        case .roundIntro:
            return "\(tableRank.displayName)'s table — play 1–3 cards and claim they match."
        case .mustPlay:
            return "\(activePlayer?.name ?? "Player") — play 1–3 cards face down."
        case .respond:
            if let last = lastPlay, let name = players.first(where: { $0.id == last.playerID })?.name {
                return "\(activePlayer?.name ?? "Player") — call \(name) a liar, or play 1–3 cards."
            }
            return "\(activePlayer?.name ?? "Player") — your turn."
        case .reveal:
            if let lied {
                return lied ? "Liar caught! The play wasn't honest." : "Bad call — every card was valid."
            }
            return "Cards revealed."
        case .roulette:
            return "\(rouletteTarget?.name ?? "Player") — pull the trigger."
        case .rouletteResult:
            if let target = rouletteTarget {
                return lastRouletteHit
                    ? "\(target.name) didn't make it."
                    : "\(target.name) survives!"
            }
            return "Trigger pulled."
        case .gameOver:
            if let winner = players.first(where: { $0.id == winnerID }) {
                return "\(winner.name) is the last one standing!"
            }
            return "Game over."
        default:
            return ""
        }
    }

    func startGame(config: BluffBarrelSetupConfig) {
        guard config.validationError == nil else { return }

        players = config.playerNames.enumerated().map { index, rawName in
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? "Player \(index + 1)" : trimmed
            return BluffBarrelPlayer(name: name)
        }

        winnerID = nil
        beginRound(startingAt: 0)
    }

    func startConnectedGame(roomPlayers: [RoomPlayer]) {
        guard roomPlayers.count >= BluffBarrelSetupConfig.minPlayers else { return }
        isConnectedHost = true
        players = roomPlayers.map { roomPlayer in
            BluffBarrelPlayer(id: roomPlayer.id, name: roomPlayer.name)
        }
        winnerID = nil
        beginRound(startingAt: 0)
    }

    func player(with id: UUID) -> BluffBarrelPlayer? {
        players.first { $0.id == id }
    }

    func hand(for playerID: UUID) -> [BluffBarrelCard] {
        players.first { $0.id == playerID }?.hand ?? []
    }

    func applyRemoteHand(_ cards: [BluffBarrelCard], playerID: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[index].hand = cards
    }

    func confirmRoundIntro() {
        guard phase == .roundIntro else { return }
        phase = .mustPlay
    }

    func submitPlay(playerID: UUID, cardIDs: [UUID]) {
        guard phase == .mustPlay || phase == .respond else { return }
        guard activePlayer?.id == playerID else { return }
        guard (1...BluffBarrelSetupConfig.maxPlayCount).contains(cardIDs.count) else { return }
        guard let playerIndex = players.firstIndex(where: { $0.id == playerID }) else { return }

        let selected = cardIDs.compactMap { id in players[playerIndex].hand.first { $0.id == id } }
        guard selected.count == cardIDs.count else { return }

        players[playerIndex].hand.removeAll { cardIDs.contains($0.id) }
        lastPlay = BluffBarrelLastPlay(playerID: playerID, cards: selected)
        lastPlayCount = selected.count

        advanceAfterPlay()
    }

    func callLiar(callerID: UUID) {
        guard phase == .respond else { return }
        guard activePlayer?.id == callerID else { return }
        guard let last = lastPlay else { return }

        accusedPlayerID = last.playerID
        callerPlayerID = callerID
        revealedCards = last.cards
        lied = last.cards.contains { !$0.isValid(for: tableRank) }
        rouletteTargetID = lied == true ? last.playerID : callerID
        phase = .reveal
    }

    func continueToRoulette() {
        guard phase == .reveal else { return }
        phase = .roulette
    }

    func pullTrigger() {
        guard phase == .roulette, let targetID = rouletteTargetID else { return }
        guard let index = players.firstIndex(where: { $0.id == targetID && $0.isAlive }) else { return }

        let hit = resolvesHit(for: players[index])
        lastRouletteHit = hit

        if hit {
            players[index].isAlive = false
        } else {
            players[index].safeTriggerPulls += 1
        }

        phase = .rouletteResult
    }

    func acknowledgeRouletteResult() {
        guard phase == .rouletteResult else { return }

        if alivePlayers.count <= 1 {
            winnerID = alivePlayers.first?.id
            phase = .gameOver
            return
        }

        guard let targetID = rouletteTargetID,
              let index = players.firstIndex(where: { $0.id == targetID }) else { return }

        let nextStart = nextAliveIndex(after: index)
        beginRound(startingAt: nextStart)
    }

    func publicSnapshot() -> ConnectedBluffBarrelPublicPayload {
        ConnectedBluffBarrelPublicPayload(
            tableRank: tableRank,
            phaseKey: String(describing: phase),
            activePlayerID: activePlayer?.id,
            lastPlayPlayerID: lastPlay?.playerID,
            lastPlayCount: lastPlayCount,
            canCallLiar: phase == .respond,
            mustPlay: phase == .mustPlay,
            revealedCards: phase == .reveal || phase == .roulette ? revealedCards : nil,
            lied: lied,
            rouletteTargetID: rouletteTargetID,
            players: players.map {
                ConnectedBluffBarrelPlayerSnapshot(
                    id: $0.id,
                    name: $0.name,
                    isAlive: $0.isAlive,
                    safeTriggerPulls: $0.safeTriggerPulls,
                    handCount: $0.hand.count
                )
            },
            title: navigationTitle,
            script: moderatorScript,
            lastRouletteHit: lastRouletteHit,
            winnerID: winnerID
        )
    }

    func applyPublicSnapshot(_ snapshot: ConnectedBluffBarrelPublicPayload) {
        if players.isEmpty {
            players = snapshot.players.map {
                BluffBarrelPlayer(
                    id: $0.id,
                    name: $0.name,
                    isAlive: $0.isAlive,
                    safeTriggerPulls: $0.safeTriggerPulls
                )
            }
        }

        tableRank = snapshot.tableRank
        if let activeID = snapshot.activePlayerID,
           let index = players.firstIndex(where: { $0.id == activeID }) {
            activePlayerIndex = index
        }
        if let lastID = snapshot.lastPlayPlayerID, snapshot.lastPlayCount > 0 {
            lastPlayCount = snapshot.lastPlayCount
            let cards = snapshot.revealedCards ?? []
            lastPlay = BluffBarrelLastPlay(playerID: lastID, cards: cards)
        } else {
            lastPlay = nil
            lastPlayCount = 0
        }
        revealedCards = snapshot.revealedCards ?? []
        lied = snapshot.lied
        rouletteTargetID = snapshot.rouletteTargetID
        lastRouletteHit = snapshot.lastRouletteHit
        winnerID = snapshot.winnerID

        for snapshotPlayer in snapshot.players {
            guard let index = players.firstIndex(where: { $0.id == snapshotPlayer.id }) else { continue }
            players[index].name = snapshotPlayer.name
            players[index].isAlive = snapshotPlayer.isAlive
            players[index].safeTriggerPulls = snapshotPlayer.safeTriggerPulls
        }

        switch snapshot.phaseKey {
        case "roundIntro": phase = .roundIntro
        case "mustPlay": phase = .mustPlay
        case "respond": phase = .respond
        case "reveal": phase = .reveal
        case "roulette": phase = .roulette
        case "rouletteResult": phase = .rouletteResult
        case "gameOver":
            phase = .gameOver
            winnerID = snapshot.winnerID ?? snapshot.players.first(where: { $0.isAlive })?.id
        default: break
        }
    }

    private func beginRound(startingAt index: Int) {
        tableRank = BluffBarrelRank.tableRanks.randomElement() ?? .king
        var deck = BluffBarrelDeck.shuffled()

        for playerIndex in players.indices where players[playerIndex].isAlive {
            let deal = Array(deck.prefix(BluffBarrelSetupConfig.handSize))
            deck.removeFirst(min(BluffBarrelSetupConfig.handSize, deck.count))
            players[playerIndex].hand = deal
        }

        lastPlay = nil
        lastPlayCount = 0
        revealedCards = []
        accusedPlayerID = nil
        callerPlayerID = nil
        lied = nil
        rouletteTargetID = nil
        lastRouletteHit = false
        activePlayerIndex = nextAliveIndex(from: index)
        phase = .roundIntro
    }

    private func advanceAfterPlay() {
        activePlayerIndex = nextAliveIndex(after: activePlayerIndex)
        phase = .respond
    }

    private func nextAliveIndex(from index: Int) -> Int {
        guard !alivePlayers.isEmpty else { return 0 }
        var cursor = index % players.count
        for _ in 0..<players.count {
            if players[cursor].isAlive { return cursor }
            cursor = (cursor + 1) % players.count
        }
        return index
    }

    private func nextAliveIndex(after index: Int) -> Int {
        nextAliveIndex(from: (index + 1) % players.count)
    }

    private func resolvesHit(for player: BluffBarrelPlayer) -> Bool {
        if player.safeTriggerPulls >= 5 { return true }
        let remaining = 6 - player.safeTriggerPulls
        return Int.random(in: 0..<remaining) == 0
    }
}
