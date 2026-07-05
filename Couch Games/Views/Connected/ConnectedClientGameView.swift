//
//  ConnectedClientGameView.swift
//  Couch Games
//

import SwiftUI

struct ConnectedClientGameView: View {
    let game: ConnectedGameKind
    @Bindable var room: MultipeerRoomService

    @State private var phaseTitle = "Waiting"
    @State private var phaseScript = "Waiting for the host to start…"
    @State private var chameleonRole: ConnectedChameleonRolePayload?
    @State private var privateRole: ConnectedPrivateRolePayload?
    @State private var votePromptPlayerID: UUID?
    @State private var guessPrompt: ConnectedChameleonGuessPromptPayload?
    @State private var voteSelection: UUID?

    var body: some View {
        ZStack {
            GameScreenBackground()

            ScrollView {
                VStack(spacing: 16) {
                    ConnectedClientBanner(text: phaseScript)

                    if let chameleonRole {
                        chameleonRoleCard(chameleonRole)
                    } else if let privateRole {
                        privateRoleCard(privateRole)
                    }

                    if votePromptPlayerID == room.localPlayer?.id, let localID = room.localPlayer?.id {
                        voteSection(voterID: localID)
                    }

                    if guessPrompt != nil, chameleonRole?.isChameleon == true {
                        guessSection
                    }
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(phaseTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            room.onMessage = handleMessage
        }
    }

    private func handleMessage(_ message: ConnectedMessage) {
        switch message {
        case .phase(let payload):
            phaseTitle = payload.title
            phaseScript = payload.script
        case .chameleonRole(let payload):
            chameleonRole = payload
        case .privateRole(let payload):
            privateRole = payload
        case .chameleonVotePrompt(let payload):
            votePromptPlayerID = payload.playerID
            voteSelection = nil
        case .chameleonGuessPrompt(let payload):
            guessPrompt = payload
        default:
            break
        }
    }

    @ViewBuilder
    private func chameleonRoleCard(_ role: ConnectedChameleonRolePayload) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                if role.isChameleon {
                    Text("🦎").font(.system(size: 48))
                    Text("Chameleon").font(.title.bold())
                } else {
                    Text(role.category.uppercased()).font(.caption.bold()).foregroundStyle(.white.opacity(0.55))
                    Text(role.secretWord ?? "?").font(.largeTitle.bold()).foregroundStyle(CouchTheme.gold)
                }
                if role.isChameleon, role.intelMode == .wordGrid {
                    ChameleonWordGrid(words: role.gridWords, secretIndex: nil)
                } else if !role.isChameleon {
                    if let word = role.secretWord, let index = role.gridWords.firstIndex(of: word) {
                        ChameleonWordGrid(words: role.gridWords, secretIndex: index)
                    }
                }
            }
        }
    }

    private func privateRoleCard(_ role: ConnectedPrivateRolePayload) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(role.heading).font(.title2.bold())
                ForEach(role.lines, id: \.self) { line in
                    Text(line).foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func voteSection(voterID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your vote").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(room.players) { player in
                    Button {
                        voteSelection = player.id
                    } label: {
                        Text(player.name)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(voteSelection == player.id ? AnyShapeStyle(CouchTheme.chameleonAccentGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                            )
                    }
                }
            }
            if let voteSelection {
                Button("Submit Vote") {
                    room.sendToHost(.vote(ConnectedVotePayload(voterID: voterID, targetID: voteSelection)))
                    votePromptPlayerID = nil
                    self.voteSelection = nil
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
            }
        }
    }

    @ViewBuilder
    private var guessSection: some View {
        if let guessPrompt, chameleonRole?.isChameleon == true {
            VStack(spacing: 12) {
                Text("Guess the secret word").font(.headline)
                ChameleonWordGrid(words: guessPrompt.gridWords, secretIndex: nil)
                Text("Tell the host your guess aloud for now.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

private struct ConnectedClientBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)))
    }
}
