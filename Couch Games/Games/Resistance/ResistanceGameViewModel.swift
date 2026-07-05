//
//  ResistanceGameViewModel.swift
//  Couch Games
//

import Foundation

@MainActor
@Observable
final class ResistanceGameViewModel {
    var phase: ResistancePhase = .setup
    var players: [ResistancePlayer] = []
    var gameMode: ResistanceGameMode = .classic

    var missionNumber = 1
    var leaderIndex = 0
    var resistanceWins = 0
    var spyWins = 0
    var consecutiveRejections = 0

    // Role reveal
    var revealIndex = 0
    var showingRole = false
    var percivalDecoyID: UUID?

    // Team pick
    var proposedTeamIDs: Set<UUID> = []

    // Team vote
    var voteMode: ResistanceVoteMode = .passPhone
    var voteModeLocked = false
    var voteCollectorIndex = 0
    var teamVotes: [UUID: ResistanceTeamVote] = [:]
    var lastTeamApproved = false
    var lastApproveCount = 0
    var lastRejectCount = 0

    // Mission
    var missionPlayerIndex = 0
    var missionCards: [UUID: ResistanceMissionCard] = [:]
    var lastMissionFailCount = 0
    var lastMissionSucceeded = false

    // Assassination
    var assassinationTargetID: UUID?
    var merlinWasAssassinated = false

    var winner: ResistanceWinner?

    var currentTeamSize: Int {
        ResistanceMissionRules.teamSize(playerCount: players.count, mission: missionNumber)
    }

    var failsRequired: Int {
        ResistanceMissionRules.failsRequiredToSabotage(playerCount: players.count, mission: missionNumber)
    }

    var leader: ResistancePlayer? {
        guard players.indices.contains(leaderIndex) else { return nil }
        return players[leaderIndex]
    }

    var currentRevealPlayer: ResistancePlayer? {
        guard players.indices.contains(revealIndex) else { return nil }
        return players[revealIndex]
    }

    var currentVoter: ResistancePlayer? {
        guard players.indices.contains(voteCollectorIndex) else { return nil }
        return players[voteCollectorIndex]
    }

    var proposedTeam: [ResistancePlayer] {
        players.filter { proposedTeamIDs.contains($0.id) }
    }

    var currentMissionPlayer: ResistancePlayer? {
        let team = proposedTeam
        guard team.indices.contains(missionPlayerIndex) else { return nil }
        return team[missionPlayerIndex]
    }

    var evilPlayers: [ResistancePlayer] {
        players.filter { $0.role.isEvil }
    }

    var assassinPlayer: ResistancePlayer? {
        players.first { $0.role == .assassin }
    }

    var assassinationTarget: ResistancePlayer? {
        guard let id = assassinationTargetID else { return nil }
        return players.first { $0.id == id }
    }

    var spiesWinViaAssassination: Bool {
        gameMode == .avalon && merlinWasAssassinated
    }

    var navigationTitle: String {
        switch phase {
        case .roleReveal: return "Roles"
        case .assassination: return "Assassination"
        case .gameOver: return "Game Over"
        default: return "Mission \(missionNumber)"
        }
    }

    func roleRevealIntel(for player: ResistancePlayer) -> RoleRevealIntel? {
        if gameMode == .classic {
            guard player.role == .spy else { return nil }
            let teammates = evilPlayers.filter { $0.id != player.id }.map(\.name).sorted()
            guard !teammates.isEmpty else { return nil }
            return RoleRevealIntel(title: "Your fellow Spies", names: teammates, footnote: nil)
        }
        return ResistanceRoleIntel.revealIntel(for: player, in: players, percivalDecoyID: percivalDecoyID)
    }

    var moderatorScript: String {
        switch phase {
        case .roleReveal:
            return "Pass the phone. Only one player should look."
        case .missionIntro:
            return "\(leader?.name ?? "Leader") is Mission Leader. Pick a team of \(currentTeamSize)."
        case .teamPick:
            return "Leader — select exactly \(currentTeamSize) players for this mission."
        case .voteModeChoice:
            return "How should the group vote on this team?"
        case .teamVoteCollect:
            return "Pass the phone — \(currentVoter?.name ?? "player") votes Approve or Reject."
        case .teamVoteGod:
            return "Moderator — tap whether the group approves or rejects this team."
        case .teamVoteResult:
            return lastTeamApproved
                ? "Team approved. Mission members play their cards secretly."
                : "Team rejected. Leader passes to the next player."
        case .missionPlay:
            return "Pass the phone — \(currentMissionPlayer?.name ?? "player") plays a mission card."
        case .missionResult:
            return lastMissionSucceeded ? "Mission succeeded!" : "Mission failed!"
        case .assassination:
            if let assassin = assassinPlayer {
                return "Good won 3 missions. Pass the phone to \(assassin.name) — pick who you think is Merlin."
            }
            return "Assassin — pick who you think is Merlin."
        case .gameOver:
            if spiesWinViaAssassination {
                return "The Assassin found Merlin. Spies steal the win!"
            }
            return winner == .resistance ? "The good team wins!" : "The Spies win!"
        default:
            return ""
        }
    }

    func startGame(config: ResistanceSetupConfig) {
        guard config.validationError == nil else { return }

        gameMode = config.gameMode
        var roles: [ResistanceRole]

        switch config.gameMode {
        case .classic:
            roles = Array(repeating: .spy, count: config.spyCount)
            roles += Array(repeating: .resistance, count: config.totalPlayers - config.spyCount)
        case .avalon:
            roles = AvalonRoleRules.roles(for: config.totalPlayers)
        }

        roles.shuffle()

        players = roles.enumerated().map { index, role in
            let rawName = config.playerNames.indices.contains(index)
                ? config.playerNames[index]
                : "Player \(index + 1)"
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            return ResistancePlayer(
                name: name.isEmpty ? "Player \(index + 1)" : name,
                role: role
            )
        }

        if config.gameMode == .avalon,
           !players.contains(where: { $0.role == .morgana }),
           let decoy = players.first(where: { $0.role == .loyalServant }) {
            percivalDecoyID = decoy.id
        } else {
            percivalDecoyID = nil
        }

        resetRoundState()
        revealIndex = 0
        showingRole = false
        missionNumber = 1
        leaderIndex = 0
        resistanceWins = 0
        spyWins = 0
        consecutiveRejections = 0
        voteModeLocked = false
        assassinationTargetID = nil
        merlinWasAssassinated = false
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
            phase = .missionIntro
        }
    }

    func continueFromMissionIntro() {
        proposedTeamIDs = []
        phase = .teamPick
    }

    func toggleTeamMember(_ playerID: UUID) {
        if proposedTeamIDs.contains(playerID) {
            proposedTeamIDs.remove(playerID)
        } else if proposedTeamIDs.count < currentTeamSize {
            proposedTeamIDs.insert(playerID)
        }
    }

    func confirmTeamPick() {
        guard proposedTeamIDs.count == currentTeamSize else { return }
        teamVotes = [:]
        voteCollectorIndex = 0
        if voteModeLocked {
            phase = voteMode == .godOverride ? .teamVoteGod : .teamVoteCollect
        } else {
            phase = .voteModeChoice
        }
    }

    func chooseVoteMode(_ mode: ResistanceVoteMode) {
        voteMode = mode
        voteModeLocked = true
        voteCollectorIndex = 0
        teamVotes = [:]
        phase = mode == .godOverride ? .teamVoteGod : .teamVoteCollect
    }

    func submitTeamVote(_ vote: ResistanceTeamVote) {
        guard let voter = currentVoter else { return }
        teamVotes[voter.id] = vote
        if voteCollectorIndex + 1 < players.count {
            voteCollectorIndex += 1
        } else {
            resolveTeamVote()
        }
    }

    func submitGodTeamVote(approved: Bool) {
        lastTeamApproved = approved
        lastApproveCount = approved ? players.count : 0
        lastRejectCount = approved ? 0 : players.count
        phase = .teamVoteResult
    }

    func continueFromTeamVoteResult() {
        if lastTeamApproved {
            consecutiveRejections = 0
            missionCards = [:]
            missionPlayerIndex = 0
            phase = .missionPlay
        } else {
            consecutiveRejections += 1
            if consecutiveRejections >= ResistanceMissionRules.maxRejections {
                winner = .resistance
                phase = .gameOver
                return
            }
            advanceLeader()
            proposedTeamIDs = []
            phase = .missionIntro
        }
    }

    func playMissionCard(_ card: ResistanceMissionCard) {
        guard let player = currentMissionPlayer else { return }
        missionCards[player.id] = card
        if missionPlayerIndex + 1 < proposedTeam.count {
            missionPlayerIndex += 1
        } else {
            resolveMission()
            phase = .missionResult
        }
    }

    func continueFromMissionResult() {
        if checkWin() { return }
        missionNumber += 1
        advanceLeader()
        proposedTeamIDs = []
        phase = .missionIntro
    }

    func confirmAssassination(targetID: UUID) {
        assassinationTargetID = targetID
        let target = players.first { $0.id == targetID }
        merlinWasAssassinated = target?.role == .merlin
        winner = merlinWasAssassinated ? .spies : .resistance
        phase = .gameOver
    }

    func resetToSetup() {
        players = []
        phase = .setup
        winner = nil
        resetRoundState()
    }

    // MARK: - Private

    private func resetRoundState() {
        proposedTeamIDs = []
        teamVotes = [:]
        missionCards = [:]
        winner = nil
        assassinationTargetID = nil
        merlinWasAssassinated = false
    }

    private func resolveTeamVote() {
        lastApproveCount = teamVotes.values.filter { $0 == .approve }.count
        lastRejectCount = teamVotes.values.filter { $0 == .reject }.count
        lastTeamApproved = lastApproveCount > lastRejectCount
        phase = .teamVoteResult
    }

    private func resolveMission() {
        lastMissionFailCount = missionCards.values.filter { $0 == .fail }.count
        lastMissionSucceeded = lastMissionFailCount < failsRequired
        if lastMissionSucceeded {
            resistanceWins += 1
        } else {
            spyWins += 1
        }
    }

    private func advanceLeader() {
        leaderIndex = (leaderIndex + 1) % players.count
    }

    @discardableResult
    private func checkWin() -> Bool {
        if spyWins >= ResistanceMissionRules.winsNeeded {
            winner = .spies
            phase = .gameOver
            return true
        }
        if resistanceWins >= ResistanceMissionRules.winsNeeded {
            if gameMode == .avalon {
                phase = .assassination
                return true
            }
            winner = .resistance
            phase = .gameOver
            return true
        }
        return false
    }
}
