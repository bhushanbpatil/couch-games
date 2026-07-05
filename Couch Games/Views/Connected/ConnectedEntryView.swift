//
//  ConnectedEntryView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedEntryView: View {
    let game: ConnectedGameKind

    @State private var room = MultipeerRoomService()
    @State private var displayName = ""
    @State private var navigateToLobby = false
    @State private var lobbyMode: ConnectedLobbyMode = .host

    private enum ConnectedLobbyMode {
        case host
        case join
    }

    var body: some View {
        ZStack {
            GameScreenBackground()

            ScrollView {
                VStack(spacing: 20) {
                    GameHubIcon(assetName: game.iconAsset, size: 88)

                    VStack(spacing: 8) {
                        Text(game.title)
                            .font(.largeTitle.bold())
                        Text("Everyone plays on their own phone")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your name")
                                .font(.headline)
                            TextField("Name on this phone", text: $displayName)
                                .textInputAutocapitalization(.words)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
                                .foregroundStyle(.white)
                            Text("\(game.minPlayers)–\(game.maxPlayers) players needed.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }

                    Button("Host a Room") {
                        startHosting()
                    }
                    .buttonStyle(CouchPrimaryButton())
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Join Nearby Room") {
                        startJoining()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.15)], startPoint: .leading, endPoint: .trailing)))
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear {
            if !navigateToLobby {
                room.stop()
            }
        }
        .navigationDestination(isPresented: $navigateToLobby) {
            ConnectedLobbyView(game: game, room: room)
        }
    }

    private func startHosting() {
        room.hostRoom(game: game, displayName: trimmedName)
        lobbyMode = .host
        navigateToLobby = true
    }

    private func startJoining() {
        room.joinNearby(displayName: trimmedName)
        lobbyMode = .join
        navigateToLobby = true
    }

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    NavigationStack {
        ConnectedEntryView(game: .chameleon)
    }
}
