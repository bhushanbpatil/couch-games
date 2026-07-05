//
//  ConnectedLobbyView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedLobbyView: View {
    let game: ConnectedGameKind
    @Bindable var room: MultipeerRoomService

    @State private var navigateToHostSetup = false
    @State private var navigateToClientGame = false
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            GameScreenBackground()

            ScrollView {
                VStack(spacing: 20) {
                    GlassCard {
                        VStack(spacing: 10) {
                            Label(room.isHost ? "You're hosting" : "You're in the room", systemImage: room.isHost ? "antenna.radiowaves.left.and.right" : "iphone.gen3.radiowaves.left.and.right")
                                .font(.headline)
                            Text(room.statusText)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Players · \(room.players.count)")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))

                        ForEach(room.players) { player in
                            HStack {
                                Image(systemName: player.isHost ? "star.fill" : "person.fill")
                                    .foregroundStyle(player.isHost ? CouchTheme.gold : .white.opacity(0.6))
                                Text(player.name)
                                    .font(.headline)
                                if player.isLocal {
                                    Text("You")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(.white.opacity(0.12)))
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)))
                        }
                    }

                    if room.isHost {
                        Text("Friends open Couch Games → \(game.title) → Join Nearby Room")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)

                        Button("Start Game") {
                            room.startGame()
                        }
                        .buttonStyle(CouchPrimaryButton())
                        .disabled(!room.canStartGame)
                        .opacity(room.canStartGame ? 1 : 0.5)
                    } else {
                        Text("Waiting for the host to start…")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("Room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            room.onMessage = handleMessage
        }
        .navigationDestination(isPresented: $navigateToHostSetup) {
            connectedHostDestination
        }
        .navigationDestination(isPresented: $navigateToClientGame) {
            connectedClientDestination
        }
    }

    @ViewBuilder
    private var connectedClientDestination: some View {
        switch game {
        case .bluffBarrel:
            ConnectedBluffBarrelClientView(room: room)
        default:
            ConnectedClientGameView(game: game, room: room)
        }
    }

    @ViewBuilder
    private var connectedHostDestination: some View {
        switch game {
        case .mafia:
            ConnectedMafiaHostView(room: room)
        case .resistance:
            ConnectedResistanceHostView(room: room)
        case .chameleon:
            ConnectedChameleonHostView(room: room)
        case .bluffBarrel:
            ConnectedBluffBarrelHostView(room: room)
        }
    }

    private func handleMessage(_ message: ConnectedMessage) {
        guard case .startGame = message else { return }
        guard !gameStarted else { return }
        gameStarted = true
        if room.isHost {
            navigateToHostSetup = true
        } else {
            navigateToClientGame = true
        }
    }
}

#Preview {
    NavigationStack {
        ConnectedLobbyView(game: .chameleon, room: MultipeerRoomService())
    }
}
