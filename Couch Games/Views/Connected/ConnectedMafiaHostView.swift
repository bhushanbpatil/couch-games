//
//  ConnectedMafiaHostView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedMafiaHostView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var room: MultipeerRoomService

    @State private var viewModel = MafiaGameViewModel()
    @State private var started = false

    var body: some View {
        Group {
            if started {
                MafiaGameView(viewModel: viewModel) {
                    room.stop()
                    dismiss()
                }
                .onChange(of: viewModel.phase) { _, _ in
                    ConnectedGameSync.syncMafiaPhase(viewModel, room: room)
                }
            } else {
                ZStack {
                    CouchTheme.mafiaGradient.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Host setup")
                            .font(.title.bold())
                        Text("Roles go to each player's phone. Use this device to run night and day.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.65))
                        Text("\(room.players.count) players")
                            .font(.headline)
                        Button("Start Mafia") {
                            ConnectedGameSync.startMafia(viewModel, room: room)
                            started = true
                        }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
                    }
                    .padding(20)
                }
                .foregroundStyle(.white)
            }
        }
        .navigationTitle("Mafia")
        .navigationBarTitleDisplayMode(.inline)
    }
}
