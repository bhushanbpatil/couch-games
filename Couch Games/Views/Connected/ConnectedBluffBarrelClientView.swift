//
//  ConnectedBluffBarrelClientView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedBluffBarrelClientView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var room: MultipeerRoomService

    @State private var viewModel = BluffBarrelGameViewModel()
    @State private var started = false

    var body: some View {
        Group {
            if started {
                BluffBarrelGameView(
                    viewModel: viewModel,
                    localPlayerID: room.localPlayer?.id,
                    connectedClientActions: clientActions,
                    onExit: {
                        room.stop()
                        dismiss()
                    }
                )
            } else {
                waitingContent
            }
        }
        .onAppear {
            room.onMessage = handleMessage
        }
    }

    private var clientActions: BluffBarrelClientActions {
        BluffBarrelClientActions(
            play: { cardIDs in sendAction(.play, cardIDs: cardIDs) },
            callLiar: { sendAction(.callLiar) },
            pullTrigger: { sendAction(.pullTrigger) },
            confirmRoundIntro: { sendAction(.confirmRoundIntro) },
            continueToRoulette: { sendAction(.continueToRoulette) },
            acknowledgeRouletteResult: { sendAction(.acknowledgeRouletteResult) }
        )
    }

    private var waitingContent: some View {
        ZStack {
            GameScreenBackground()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Waiting for the host to deal…")
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.bluffAndBarrel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleMessage(_ message: ConnectedMessage) {
        switch message {
        case .bluffBarrelHand(let payload):
            guard let localID = room.localPlayer?.id else { return }
            viewModel.applyRemoteHand(payload.cards, playerID: localID)
            started = true
        case .bluffBarrelPublic(let payload):
            viewModel.applyPublicSnapshot(payload)
            started = true
        default:
            break
        }
    }

    private func sendAction(_ action: ConnectedBluffBarrelActionPayload.Action, cardIDs: [UUID]? = nil) {
        guard let localID = room.localPlayer?.id else { return }
        room.sendToHost(
            .bluffBarrelAction(
                ConnectedBluffBarrelActionPayload(
                    playerID: localID,
                    action: action,
                    cardIDs: cardIDs
                )
            )
        )
    }
}
