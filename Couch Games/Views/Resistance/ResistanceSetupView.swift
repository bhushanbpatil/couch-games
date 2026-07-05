//
//  ResistanceSetupView.swift
//  Couch Games
//

import SwiftUI

struct ResistanceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ResistanceGameViewModel()
    @State private var gameMode: ResistanceGameMode = .classic
    @State private var playerCount = 6
    @State private var playerNames: [String] = (1...6).map { "Player \($0)" }
    @State private var navigateToGame = false
    @State private var showRules = false

    private var config: ResistanceSetupConfig {
        ResistanceSetupConfig(gameMode: gameMode, playerNames: playerNames)
    }

    var body: some View {
        ZStack {
            CouchTheme.resistanceGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    ResistanceSetupSection(title: "Game Mode", icon: "slider.horizontal.3") {
                        ForEach(ResistanceGameMode.allCases) { mode in
                            Button {
                                gameMode = mode
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.displayName)
                                            .font(.headline)
                                        Text(mode.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.white.opacity(0.55))
                                    }
                                    Spacer()
                                    Image(systemName: gameMode == mode ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(gameMode == mode ? CouchTheme.cyan : .white.opacity(0.3))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    ResistanceSetupSection(title: "Players", icon: "person.3.fill") {
                        ResistanceStepper(
                            label: "Number of players",
                            value: $playerCount,
                            range: ResistanceSetupConfig.minPlayers...ResistanceSetupConfig.maxPlayers
                        )
                        .onChange(of: playerCount) { _, newValue in
                            syncPlayerNames(count: newValue)
                        }

                        ForEach(playerNames.indices, id: \.self) { index in
                            ResistanceTextField(
                                placeholder: "Player \(index + 1)",
                                text: $playerNames[index],
                                icon: "person.fill"
                            )
                        }
                    }

                    ResistanceSetupSection(title: "Roles", icon: "shield.lefthalf.filled") {
                        if gameMode == .classic {
                            HStack {
                                Text("Spies")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                                Spacer()
                                Text("\(config.spyCount)")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color.red.opacity(0.85))
                            }
                            HStack {
                                Text("Agents")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                                Spacer()
                                Text("\(config.totalPlayers - config.spyCount)")
                                    .font(.title3.bold())
                                    .foregroundStyle(CouchTheme.cyan)
                            }
                        } else {
                            Text(AvalonRoleRules.roleSummary(for: playerCount))
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let error = config.validationError {
                        Text(error)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    Button("Start Game") {
                        startGame()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))
                    .disabled(config.validationError != nil)
                    .opacity(config.validationError == nil ? 1 : 0.5)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.secretMissions)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rules") { showRules = true }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            ResistanceGameView(viewModel: viewModel) {
                navigateToGame = false
                dismiss()
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GameRulebookView(books: CouchGameRulebook.resistanceBooks(for: gameMode))
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
        guard config.validationError == nil else { return }
        viewModel.startGame(config: config)
        navigateToGame = true
    }
}

private struct ResistanceSetupSection<Content: View>: View {
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
                    .fill(.white.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            }
        }
    }
}

private struct ResistanceStepper: View {
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
                stepButton(systemName: "minus", enabled: value > range.lowerBound) { value -= 1 }
                stepButton(systemName: "plus", enabled: value < range.upperBound) { value += 1 }
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
                        .fill(
                            enabled
                                ? CouchTheme.resistanceAccentGradient
                                : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                        )
                }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

private struct ResistanceTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(CouchTheme.cyan.opacity(0.85))
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
                .fill(.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

#Preview {
    NavigationStack {
        ResistanceSetupView()
    }
}
