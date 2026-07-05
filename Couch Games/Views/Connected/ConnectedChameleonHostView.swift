//
//  ConnectedChameleonHostView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedChameleonHostView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var room: MultipeerRoomService

    @State private var viewModel = ChameleonGameViewModel()
    @State private var intelMode: ChameleonIntelMode = .categoryOnly
    @State private var started = false

    var body: some View {
        Group {
            if started {
                ChameleonGameView(viewModel: viewModel) {
                    room.stop()
                    dismiss()
                }
                .onChange(of: viewModel.phase) { _, _ in
                    ConnectedGameSync.syncChameleonPhase(viewModel, room: room)
                }
            } else {
                setupContent
            }
        }
        .onAppear {
            room.onMessage = { message in
                ConnectedGameSync.handleChameleonHostMessage(message, viewModel: viewModel, room: room)
            }
        }
    }

    private var setupContent: some View {
        ZStack {
            CouchTheme.chameleonGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Host setup")
                        .font(.title.bold())

                    Text("\(room.players.count) players connected")
                        .foregroundStyle(.white.opacity(0.65))

                    VStack(spacing: 10) {
                        ForEach(ChameleonIntelMode.allCases) { mode in
                            Button {
                                intelMode = mode
                            } label: {
                                HStack {
                                    Image(systemName: intelMode == mode ? "checkmark.circle.fill" : "circle")
                                    VStack(alignment: .leading) {
                                        Text(mode.title).font(.headline)
                                        Text(mode.subtitle).font(.caption).foregroundStyle(.white.opacity(0.55))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(intelMode == mode ? .white.opacity(0.12) : .white.opacity(0.05)))
                            }
                        }
                    }

                    Button("Deal Roles & Start") {
                        ConnectedGameSync.startChameleon(viewModel, room: room, intel: intelMode)
                        started = true
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.wordSpy)
        .navigationBarTitleDisplayMode(.inline)
    }
}
