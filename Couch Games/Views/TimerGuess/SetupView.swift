//
//  SetupView.swift
//  Couch Games
//

import SwiftUI

struct SetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TimerGuessViewModel()
    @State private var playerCount = 2
    @State private var roundCount = 3
    @State private var playerNames: [String] = ["Player 1", "Player 2"]
    @State private var navigateToGame = false
    @State private var showLeaderboard = false

    var body: some View {
        ZStack {
            GameScreenBackground()

            ScrollView {
                VStack(spacing: 20) {
                    SetupSection(title: "Players", icon: "person.3.fill") {
                        ThemedStepper(
                            label: "Number of players",
                            value: $playerCount,
                            range: GameConfig.minPlayers...GameConfig.maxPlayers
                        )
                        .onChange(of: playerCount) { _, newValue in
                            syncPlayerNames(count: newValue)
                        }

                        ForEach(playerNames.indices, id: \.self) { index in
                            ThemedTextField(
                                placeholder: "Player \(index + 1)",
                                text: $playerNames[index],
                                icon: "person.fill"
                            )
                        }
                    }

                    SetupSection(title: "Rounds", icon: "arrow.triangle.2.circlepath") {
                        ThemedStepper(
                            label: "Rounds to play",
                            value: $roundCount,
                            range: GameConfig.minRounds...GameConfig.maxRounds
                        )
                    }

                    Text("Same target time for everyone each round. Closest stop wins — a perfect stop earns 200 points.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Button("Start Game") {
                        startGame()
                    }
                    .buttonStyle(CouchPrimaryButton())
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("Timer Guess")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Leaderboard") {
                    showLeaderboard = true
                }
                .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            GameplayView(viewModel: viewModel) {
                navigateToGame = false
                dismiss()
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            NavigationStack {
                LeaderboardView(players: viewModel.leaderboard, turnHistory: viewModel.turnHistory)
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

    private func startGame() {
        let players = playerNames.enumerated().map { index, name in
            Player(name: name.isEmpty ? "Player \(index + 1)" : name)
        }
        let config = GameConfig(roundCount: roundCount, players: players)
        viewModel.startGame(config: config)
        navigateToGame = true
    }
}

private struct SetupSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))

            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            }
        }
    }
}

private struct ThemedStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                Text("\(value)")
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(CouchTheme.cyan)
            }

            Spacer()

            HStack(spacing: 12) {
                stepButton(systemName: "minus", enabled: value > range.lowerBound) {
                    value -= 1
                }
                stepButton(systemName: "plus", enabled: value < range.upperBound) {
                    value += 1
                }
            }
        }
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.bold())
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(enabled ? CouchTheme.accentGradient : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

private struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(CouchTheme.violet)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .foregroundStyle(.white)
                .tint(CouchTheme.cyan)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

#Preview {
    NavigationStack {
        SetupView()
    }
}
