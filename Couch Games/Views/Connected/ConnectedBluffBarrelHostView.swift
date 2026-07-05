//
//  ConnectedBluffBarrelHostView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedBluffBarrelHostView: View {
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
                    onConnectedAction: {
                        ConnectedBluffBarrelSync.handleHostLocalAction(viewModel, room: room)
                    },
                    onExit: {
                        room.stop()
                        dismiss()
                    }
                )
            } else {
                hostStartContent
            }
        }
        .onAppear {
            room.onMessage = { message in
                ConnectedBluffBarrelSync.handleHostAction(message, viewModel: viewModel, room: room)
            }
        }
    }

    private var hostStartContent: some View {
        ZStack {
            CouchTheme.bluffBarrelGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Host setup")
                        .font(.title.bold())

                    Text("\(room.players.count) players connected")
                        .foregroundStyle(.white.opacity(0.65))

                    Text("Each player sees their own hand. You run the table and sync plays.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)

                    Button("Deal Cards & Start") {
                        ConnectedBluffBarrelSync.start(viewModel, room: room)
                        started = true
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
                    .disabled(room.players.count < BluffBarrelSetupConfig.minPlayers)
                    .opacity(room.players.count < BluffBarrelSetupConfig.minPlayers ? 0.5 : 1)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.bluffAndBarrel)
        .navigationBarTitleDisplayMode(.inline)
    }
}
