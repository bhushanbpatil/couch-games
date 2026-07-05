//
//  ConnectedBluffBarrelSync.swift
//  Couch Games
//

import Foundation

enum ConnectedBluffBarrelSync {
    static func start(_ viewModel: BluffBarrelGameViewModel, room: MultipeerRoomService) {
        viewModel.startConnectedGame(roomPlayers: room.players)
        distributeHands(viewModel, room: room)
        syncPublicState(viewModel, room: room)
    }

    static func distributeHands(_ viewModel: BluffBarrelGameViewModel, room: MultipeerRoomService) {
        for player in viewModel.players where player.isAlive {
            room.sendToPlayer(
                .bluffBarrelHand(ConnectedBluffBarrelHandPayload(cards: player.hand)),
                playerID: player.id
            )
        }
    }

    static func syncPublicState(_ viewModel: BluffBarrelGameViewModel, room: MultipeerRoomService) {
        room.broadcast(.bluffBarrelPublic(viewModel.publicSnapshot()))
    }

    static func handleHostAction(_ message: ConnectedMessage, viewModel: BluffBarrelGameViewModel, room: MultipeerRoomService) {
        guard case .bluffBarrelAction(let payload) = message else { return }

        switch payload.action {
        case .play:
            guard let cardIDs = payload.cardIDs else { return }
            viewModel.submitPlay(playerID: payload.playerID, cardIDs: cardIDs)
        case .callLiar:
            viewModel.callLiar(callerID: payload.playerID)
        case .pullTrigger:
            viewModel.pullTrigger()
        case .confirmRoundIntro:
            viewModel.confirmRoundIntro()
        case .continueToRoulette:
            viewModel.continueToRoulette()
        case .acknowledgeRouletteResult:
            viewModel.acknowledgeRouletteResult()
        }

        distributeHands(viewModel, room: room)
        syncPublicState(viewModel, room: room)
    }

    static func handleHostLocalAction(_ viewModel: BluffBarrelGameViewModel, room: MultipeerRoomService) {
        distributeHands(viewModel, room: room)
        syncPublicState(viewModel, room: room)
    }
}
