//
//  ConnectedGameSync.swift
//  Couch Games
//

import Foundation

enum ConnectedGameSync {
    static func broadcastPhase(title: String, script: String, phaseKey: String, room: MultipeerRoomService) {
        room.broadcast(.phase(ConnectedPhasePayload(title: title, script: script, phaseKey: phaseKey)))
    }

    // MARK: - Chameleon

    static func startChameleon(_ viewModel: ChameleonGameViewModel, room: MultipeerRoomService, intel: ChameleonIntelMode) {
        viewModel.startConnectedGame(roomPlayers: room.players, intel: intel)
        distributeChameleonRoles(viewModel, room: room)
        broadcastPhase(
            title: viewModel.navigationTitle,
            script: viewModel.moderatorScript,
            phaseKey: "discussion",
            room: room
        )
        promptChameleonVoterIfNeeded(viewModel, room: room)
    }

    static func distributeChameleonRoles(_ viewModel: ChameleonGameViewModel, room: MultipeerRoomService) {
        for player in viewModel.players {
            let payload: ConnectedChameleonRolePayload
            if player.isChameleon {
                payload = ConnectedChameleonRolePayload(
                    isChameleon: true,
                    category: viewModel.round.topic.category,
                    secretWord: nil,
                    gridWords: viewModel.gridWords,
                    intelMode: viewModel.chameleonIntel
                )
            } else {
                payload = ConnectedChameleonRolePayload(
                    isChameleon: false,
                    category: viewModel.round.topic.category,
                    secretWord: viewModel.round.secretWord,
                    gridWords: viewModel.gridWords,
                    intelMode: viewModel.chameleonIntel
                )
            }
            room.sendToPlayer(.chameleonRole(payload), playerID: player.id)
        }
    }

    static func syncChameleonPhase(_ viewModel: ChameleonGameViewModel, room: MultipeerRoomService) {
        broadcastPhase(
            title: viewModel.navigationTitle,
            script: viewModel.moderatorScript,
            phaseKey: String(describing: viewModel.phase),
            room: room
        )
        promptChameleonVoterIfNeeded(viewModel, room: room)
        promptChameleonGuessIfNeeded(viewModel, room: room)
    }

    static func promptChameleonVoterIfNeeded(_ viewModel: ChameleonGameViewModel, room: MultipeerRoomService) {
        guard viewModel.phase == .voteCollect, let voter = viewModel.currentVoter else { return }
        room.sendToPlayer(.chameleonVotePrompt(ConnectedChameleonVotePromptPayload(playerID: voter.id)), playerID: voter.id)
    }

    static func promptChameleonGuessIfNeeded(_ viewModel: ChameleonGameViewModel, room: MultipeerRoomService) {
        guard viewModel.phase == .chameleonGuess, let chameleon = viewModel.chameleon else { return }
        room.sendToPlayer(
            .chameleonGuessPrompt(
                ConnectedChameleonGuessPromptPayload(
                    gridWords: viewModel.gridWords,
                    category: viewModel.round.topic.category
                )
            ),
            playerID: chameleon.id
        )
    }

    static func handleChameleonHostMessage(_ message: ConnectedMessage, viewModel: ChameleonGameViewModel, room: MultipeerRoomService) {
        switch message {
        case .vote(let payload):
            viewModel.receiveConnectedVote(voterID: payload.voterID, targetID: payload.targetID)
            syncChameleonPhase(viewModel, room: room)
        default:
            break
        }
    }

    // MARK: - Mafia

    static func defaultMafiaConfig(for roomPlayers: [RoomPlayer]) -> MafiaSetupConfig {
        let count = roomPlayers.count
        let mafia = max(1, count / 4)
        let police = count >= 6 ? 1 : 0
        let nurse = count >= 7 ? 1 : 0
        return MafiaSetupConfig(
            totalPlayers: count,
            mafiaCount: mafia,
            policeCount: police,
            nurseCount: nurse,
            playerNames: roomPlayers.map(\.name)
        )
    }

    static func startMafia(_ viewModel: MafiaGameViewModel, room: MultipeerRoomService) {
        let config = defaultMafiaConfig(for: room.players)
        guard config.validationError == nil else { return }
        viewModel.startGame(config: config)
        viewModel.players = viewModel.players.enumerated().map { index, player in
            MafiaPlayer(id: room.players[index].id, name: player.name, role: player.role, isAlive: player.isAlive)
        }
        distributeMafiaRoles(viewModel, room: room)
        viewModel.phase = .nightIntro
        syncMafiaPhase(viewModel, room: room)
    }

    static func distributeMafiaRoles(_ viewModel: MafiaGameViewModel, room: MultipeerRoomService) {
        for player in viewModel.players {
            let lines = mafiaRoleLines(for: player, viewModel: viewModel)
            room.sendToPlayer(
                .privateRole(ConnectedPrivateRolePayload(heading: player.role.displayName, lines: lines)),
                playerID: player.id
            )
        }
    }

    static func syncMafiaPhase(_ viewModel: MafiaGameViewModel, room: MultipeerRoomService) {
        broadcastPhase(
            title: viewModel.navigationTitle,
            script: viewModel.moderatorScript,
            phaseKey: String(describing: viewModel.phase),
            room: room
        )
    }

    private static func mafiaRoleLines(for player: MafiaPlayer, viewModel: MafiaGameViewModel) -> [String] {
        switch player.role {
        case .mafia:
            let partners = viewModel.players.filter { $0.role == .mafia && $0.id != player.id }.map(\.name)
            if partners.isEmpty {
                return ["You are a Traitor.", "Choose someone to eliminate at night."]
            }
            return ["You are a Traitor.", "Your partners: \(partners.joined(separator: ", "))"]
        case .police:
            return ["You are Police.", "Investigate one player each night."]
        case .nurse:
            return ["You are the Nurse.", "Choose someone to save each night."]
        case .villager:
            return ["You are a Villager.", "Find and vote out the Traitors."]
        }
    }

    // MARK: - Resistance

    static func startResistance(_ viewModel: ResistanceGameViewModel, room: MultipeerRoomService) {
        let config = ResistanceSetupConfig(gameMode: .classic, playerNames: room.players.map(\.name))
        guard config.validationError == nil else { return }
        viewModel.startGame(config: config)
        viewModel.players = viewModel.players.enumerated().map { index, player in
            ResistancePlayer(id: room.players[index].id, name: player.name, role: player.role)
        }
        distributeResistanceRoles(viewModel, room: room)
        viewModel.phase = .teamPick
        syncResistancePhase(viewModel, room: room)
    }

    static func distributeResistanceRoles(_ viewModel: ResistanceGameViewModel, room: MultipeerRoomService) {
        for player in viewModel.players {
            let lines = resistanceRoleLines(for: player, viewModel: viewModel)
            room.sendToPlayer(
                .privateRole(ConnectedPrivateRolePayload(heading: player.role.displayName, lines: lines)),
                playerID: player.id
            )
        }
    }

    static func syncResistancePhase(_ viewModel: ResistanceGameViewModel, room: MultipeerRoomService) {
        broadcastPhase(
            title: viewModel.navigationTitle,
            script: viewModel.moderatorScript,
            phaseKey: String(describing: viewModel.phase),
            room: room
        )
    }

    private static func resistanceRoleLines(for player: ResistancePlayer, viewModel: ResistanceGameViewModel) -> [String] {
        var lines = [player.role.displayName]
        if player.role.isEvil {
            let spies = viewModel.evilPlayers.filter { $0.id != player.id }.map(\.name)
            if spies.isEmpty {
                lines.append("You are alone on the spy team.")
            } else {
                lines.append("Spies: \(spies.joined(separator: ", "))")
            }
        } else {
            lines.append("Help the Agents win three missions.")
        }
        return lines
    }
}
