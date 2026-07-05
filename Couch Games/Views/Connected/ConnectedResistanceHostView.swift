//
//  ConnectedResistanceHostView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedResistanceHostView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var room: MultipeerRoomService

    @State private var viewModel = ResistanceGameViewModel()
    @State private var started = false

    var body: some View {
        Group {
            if started {
                ResistanceGameView(viewModel: viewModel) {
                    room.stop()
                    dismiss()
                }
                .onChange(of: viewModel.phase) { _, _ in
                    ConnectedGameSync.syncResistancePhase(viewModel, room: room)
                }
            } else {
                ZStack {
                    CouchTheme.resistanceGradient.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Host setup")
                            .font(.title.bold())
                        Text("Roles go to each player's phone. This device runs missions and votes.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.65))
                        Text("\(room.players.count) players")
                            .font(.headline)
                        Button("Start \(GameDisplayNames.secretMissions)") {
                            ConnectedGameSync.startResistance(viewModel, room: room)
                            started = true
                        }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))
                    }
                    .padding(20)
                }
                .foregroundStyle(.white)
            }
        }
        .navigationTitle(GameDisplayNames.secretMissions)
        .navigationBarTitleDisplayMode(.inline)
    }
}
