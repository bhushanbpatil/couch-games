//
//  BluffBarrelSetupView.swift
//  Couch Games
//

import SwiftUI

struct BluffBarrelSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BluffBarrelGameViewModel()
    @State private var playerCount = 3
    @State private var playerNames: [String] = (1...3).map { "Player \($0)" }
    @State private var navigateToGame = false
    @State private var showRules = false

    private var config: BluffBarrelSetupConfig {
        BluffBarrelSetupConfig(playerNames: playerNames)
    }

    var body: some View {
        ZStack {
            CouchTheme.bluffBarrelGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    BluffBarrelSetupSection(title: "Players", icon: "person.3.fill") {
                        BluffBarrelStepper(
                            label: "Number of players",
                            value: $playerCount,
                            range: BluffBarrelSetupConfig.minPlayers...BluffBarrelSetupConfig.maxPlayers
                        )
                        .onChange(of: playerCount) { _, newValue in
                            syncPlayerNames(count: newValue)
                        }

                        ForEach(playerNames.indices, id: \.self) { index in
                            BluffBarrelTextField(
                                placeholder: "Player \(index + 1)",
                                text: $playerNames[index]
                            )
                        }
                    }

                    BluffBarrelSetupSection(title: "How it works", icon: "suit.club.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Each player gets 5 cards — Kings, Queens, Aces & Jokers", systemImage: "rectangle.stack")
                            Label("Play 1–3 cards and claim they match the table rank", systemImage: "hand.raised")
                            Label("Next player can bluff back or call Liar!", systemImage: "exclamationmark.bubble")
                            Label("Loser pulls the trigger — last one standing wins", systemImage: "scope")
                        }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                    }

                    if let error = config.validationError {
                        Text(error)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.red.opacity(0.9))
                    }

                    Button("Start Game") {
                        viewModel.startGame(config: config)
                        navigateToGame = true
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
                    .disabled(config.validationError != nil)
                    .opacity(config.validationError == nil ? 1 : 0.5)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.bluffAndBarrel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rules") { showRules = true }
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GameRulebookView(books: [.bluffBarrel], gradient: CouchTheme.bluffBarrelAccentGradient)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            BluffBarrelGameView(viewModel: viewModel) {
                dismiss()
            }
        }
    }

    private func syncPlayerNames(count: Int) {
        if playerNames.count < count {
            for index in playerNames.count..<count {
                playerNames.append("Player \(index + 1)")
            }
        } else if playerNames.count > count {
            playerNames = Array(playerNames.prefix(count))
        }
    }
}

private struct BluffBarrelSetupSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.06)))
    }
}

private struct BluffBarrelStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button { if value > range.lowerBound { value -= 1 } } label: {
                Image(systemName: "minus.circle.fill").font(.title2)
            }
            Text("\(value)").font(.title3.bold()).frame(minWidth: 28)
            Button { if value < range.upperBound { value += 1 } } label: {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
        }
    }
}

private struct BluffBarrelTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.words)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
    }
}

#Preview {
    NavigationStack {
        BluffBarrelSetupView()
    }
}
