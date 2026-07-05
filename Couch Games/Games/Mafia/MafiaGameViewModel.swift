//
//  MafiaGameViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class MafiaGameViewModel {
    var phase: MafiaPhase = .setup
    var players: [MafiaPlayer] = []
    var roundNumber = 1

    // Role reveal
    var revealIndex = 0
    var showingRole = false

    // Night actions
    var nightKillTargetID: UUID?
    var nightSaveTargetID: UUID?
    var nightPoliceTargetID: UUID?
    var lastNightDeathName: String?
    var lastNightWasSaved = false
    var lastPoliceWasMafia = false
    var lastPoliceTargetName: String?

    // Day / vote
    var voteMode: MafiaVoteMode = .passPhone
    var voteCollectorIndex = 0
    var initialVotes: [UUID: UUID] = [:]
    var revoteVotes: [UUID: UUID] = [:]
    var finalVotes: [UUID: UUID] = [:]
    var accusedPlayerID: UUID?
    var eliminatedPlayerID: UUID?
    var winner: MafiaWinner?

    var alivePlayers: [MafiaPlayer] {
        players.filter(\.isAlive)
    }

    var aliveMafiaCount: Int {
        alivePlayers.filter { $0.role == .mafia }.count
    }

    var aliveNonMafiaCount: Int {
        alivePlayers.filter { $0.role != .mafia }.count
    }

    var currentRevealPlayer: MafiaPlayer? {
        guard players.indices.contains(revealIndex) else { return nil }
        return players[revealIndex]
    }

    var currentVoter: MafiaPlayer? {
        let voters = alivePlayers
        guard voters.indices.contains(voteCollectorIndex) else { return nil }
        return voters[voteCollectorIndex]
    }

    var accusedPlayer: MafiaPlayer? {
        guard let id = accusedPlayerID else { return nil }
        return players.first { $0.id == id }
    }

    var eliminatedPlayer: MafiaPlayer? {
        guard let id = eliminatedPlayerID else { return nil }
        return players.first { $0.id == id }
    }

    var navigationTitle: String {
        switch phase {
        case .roleReveal: return "Roles"
        case .nightIntro, .nightMafia, .nightNurse, .nightPolice, .nightPoliceResult:
            return "Night \(roundNumber)"
        case .dawn, .dayDiscussion, .voteModeChoice, .dayVoteCollect, .dayDefense, .dayRevote, .dayFinalVote, .eliminationReveal:
            return "Day \(roundNumber)"
        case .gameOver: return "Game Over"
        default: return "Mafia"
        }
    }

    var moderatorScript: String {
        switch phase {
        case .roleReveal:
            return "Pass the phone. Only one player should look."
        case .nightIntro:
            return "Everyone close your eyes."
        case .nightMafia:
            return aliveMafiaCount > 1
                ? "Mafia — open your eyes. Agree on ONE person to eliminate."
                : "Mafia — open your eyes. Choose someone to eliminate."
        case .nightNurse:
            return "Mafia — close your eyes.\nNurse — open your eyes. Choose someone to save."
        case .nightPolice:
            return "Nurse — close your eyes.\nPolice — open your eyes. Choose someone to investigate."
        case .nightPoliceResult:
            return "Moderator — show the result (nod yes/no in real life too)."
        case .dawn:
            return "Everyone — open your eyes."
        case .dayDiscussion:
            return "Discuss what happened. Who seems suspicious?"
        case .voteModeChoice:
            return "How should the town vote?"
        case .dayVoteCollect, .dayRevote, .dayFinalVote:
            return voteMode == .passPhone
                ? "Pass the phone — \(currentVoter?.name ?? "player") votes privately."
                : "Moderator (God) — tap the player the group votes for."
        case .dayDefense:
            return "\(accusedPlayer?.name ?? "They") — defend yourself. Others may change their minds."
        case .eliminationReveal:
            return "The town has spoken."
        case .gameOver:
            return winner == .mafia ? "Mafia take the town." : "The town survives!"
        default:
            return ""
        }
    }

    func startGame(config: MafiaSetupConfig) {
        guard config.validationError == nil else { return }

        var roles: [MafiaRole] = []
        roles += Array(repeating: .mafia, count: config.mafiaCount)
        roles += Array(repeating: .police, count: config.policeCount)
        roles += Array(repeating: .nurse, count: config.nurseCount)
        roles += Array(repeating: .villager, count: config.villagerCount)
        roles.shuffle()

        players = roles.enumerated().map { index, role in
            let rawName = config.playerNames.indices.contains(index)
                ? config.playerNames[index]
                : "Player \(index + 1)"
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            return MafiaPlayer(
                name: name.isEmpty ? "Player \(index + 1)" : name,
                role: role
            )
        }

        resetRoundState()
        revealIndex = 0
        showingRole = false
        roundNumber = 1
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
            phase = .nightIntro
        }
    }

    func beginNight() {
        resetNightState()
        if hasAliveRole(.mafia) {
            phase = .nightMafia
        } else if hasAliveRole(.nurse) {
            phase = .nightNurse
        } else if hasAliveRole(.police) {
            phase = .nightPolice
        } else {
            phase = .dawn
        }
    }

    func selectNightKill(_ playerID: UUID) {
        nightKillTargetID = playerID
    }

    func confirmNightKill() {
        guard nightKillTargetID != nil else { return }
        if hasAliveRole(.nurse) {
            phase = .nightNurse
        } else if hasAliveRole(.police) {
            phase = .nightPolice
        } else {
            resolveNight()
            phase = .dawn
        }
    }

    func selectNightSave(_ playerID: UUID) {
        nightSaveTargetID = playerID
    }

    func confirmNightSave() {
        guard nightSaveTargetID != nil else { return }
        if hasAliveRole(.police) {
            phase = .nightPolice
        } else {
            resolveNight()
            phase = .dawn
        }
    }

    func selectPoliceCheck(_ playerID: UUID) {
        nightPoliceTargetID = playerID
    }

    func confirmPoliceCheck() {
        guard let id = nightPoliceTargetID,
              let target = players.first(where: { $0.id == id }) else { return }
        lastPoliceTargetName = target.name
        lastPoliceWasMafia = target.role == .mafia
        phase = .nightPoliceResult
    }

    func finishPoliceResult() {
        resolveNight()
        phase = .dawn
    }

    func continueFromDawn() {
        if checkWin() { return }
        phase = .dayDiscussion
    }

    func continueFromDiscussion() {
        resetVoteState()
        phase = .voteModeChoice
    }

    func chooseVoteMode(_ mode: MafiaVoteMode) {
        voteMode = mode
        voteCollectorIndex = 0
        phase = .dayVoteCollect
    }

    func castVote(voterID: UUID, targetID: UUID, isFinal: Bool) {
        if isFinal {
            finalVotes[voterID] = targetID
        } else if phase == .dayRevote {
            revoteVotes[voterID] = targetID
        } else {
            initialVotes[voterID] = targetID
        }
    }

    func castGodVote(targetID: UUID) {
        switch phase {
        case .dayVoteCollect:
            accusedPlayerID = targetID
            phase = .dayDefense
        case .dayFinalVote:
            eliminatedPlayerID = targetID
            phase = .eliminationReveal
        default:
            break
        }
    }

    func submitCurrentVote(targetID: UUID) {
        switch phase {
        case .dayVoteCollect:
            guard let voter = currentVoter else { return }
            initialVotes[voter.id] = targetID
            advanceVoteCollector(initialVotes) {
                accusedPlayerID = self.leadingCandidate(from: self.initialVotes)
                self.phase = .dayDefense
            }
        case .dayRevote:
            guard let voter = currentVoter else { return }
            revoteVotes[voter.id] = targetID
            advanceVoteCollector(revoteVotes) {
                self.accusedPlayerID = self.leadingCandidate(from: self.revoteVotes)
                self.phase = .dayFinalVote
            }
        case .dayFinalVote:
            guard let voter = currentVoter else { return }
            finalVotes[voter.id] = targetID
            advanceVoteCollector(finalVotes) {
                self.eliminatedPlayerID = self.leadingCandidate(from: self.finalVotes)
                self.phase = .eliminationReveal
            }
        default:
            break
        }
    }

    func continueFromDefense() {
        voteCollectorIndex = 0
        revoteVotes = [:]
        finalVotes = [:]
        phase = voteMode == .godOverride ? .dayFinalVote : .dayRevote
    }

    func confirmElimination() {
        guard let id = eliminatedPlayerID,
              let index = players.firstIndex(where: { $0.id == id }) else { return }
        players[index].isAlive = false
        lastNightDeathName = nil
        if checkWin() { return }
        roundNumber += 1
        resetNightState()
        resetVoteState()
        accusedPlayerID = nil
        eliminatedPlayerID = nil
        phase = .nightIntro
    }

    func resetToSetup() {
        players = []
        phase = .setup
        winner = nil
        resetRoundState()
    }

    // MARK: - Private

    private func resetRoundState() {
        resetNightState()
        resetVoteState()
        winner = nil
        eliminatedPlayerID = nil
        accusedPlayerID = nil
    }

    private func resetNightState() {
        nightKillTargetID = nil
        nightSaveTargetID = nil
        nightPoliceTargetID = nil
        lastNightWasSaved = false
        lastPoliceWasMafia = false
        lastPoliceTargetName = nil
    }

    private func resetVoteState() {
        voteCollectorIndex = 0
        initialVotes = [:]
        revoteVotes = [:]
        finalVotes = [:]
    }

    private func hasAliveRole(_ role: MafiaRole) -> Bool {
        alivePlayers.contains { $0.role == role }
    }

    private func resolveNight() {
        guard let killID = nightKillTargetID else {
            lastNightDeathName = nil
            return
        }

        if nightSaveTargetID == killID {
            lastNightWasSaved = true
            lastNightDeathName = players.first { $0.id == killID }?.name
            return
        }

        lastNightWasSaved = false
        if let index = players.firstIndex(where: { $0.id == killID }) {
            players[index].isAlive = false
            lastNightDeathName = players[index].name
        }
    }

    private func advanceVoteCollector(_ votes: [UUID: UUID], onComplete: () -> Void) {
        let voters = alivePlayers
        if voteCollectorIndex + 1 < voters.count {
            voteCollectorIndex += 1
        } else {
            onComplete()
        }
    }

    private func leadingCandidate(from votes: [UUID: UUID]) -> UUID? {
        var tally: [UUID: Int] = [:]
        for targetID in votes.values {
            tally[targetID, default: 0] += 1
        }
        return tally.max(by: { $0.value < $1.value })?.key
    }

    @discardableResult
    private func checkWin() -> Bool {
        if aliveMafiaCount == 0 {
            winner = .villagers
            phase = .gameOver
            return true
        }
        if aliveMafiaCount >= aliveNonMafiaCount {
            winner = .mafia
            phase = .gameOver
            return true
        }
        return false
    }
}
