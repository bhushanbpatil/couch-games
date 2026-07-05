//
//  ChameleonSetupView.swift
//  Couch Games
//

import SwiftUI

struct ChameleonSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChameleonGameViewModel()
    @State private var playerCount = 5
    @State private var playerNames: [String] = (1...5).map { "Player \($0)" }
    @State private var chameleonIntel: ChameleonIntelMode = .categoryOnly
    @State private var navigateToGame = false
    @State private var showRules = false

    private var config: ChameleonSetupConfig {
        ChameleonSetupConfig(playerNames: playerNames, chameleonIntel: chameleonIntel)
    }

    var body: some View {
        ZStack {
            CouchTheme.chameleonGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    ChameleonSetupSection(title: "Players", icon: "person.3.fill") {
                        ChameleonStepper(
                            label: "Number of players",
                            value: $playerCount,
                            range: ChameleonSetupConfig.minPlayers...ChameleonSetupConfig.maxPlayers
                        )
                        .onChange(of: playerCount) { _, newValue in
                            syncPlayerNames(count: newValue)
                        }

                        ForEach(playerNames.indices, id: \.self) { index in
                            ChameleonTextField(
                                placeholder: "Player \(index + 1)",
                                text: $playerNames[index]
                            )
                        }
                    }

                    ChameleonSetupSection(title: "Word bank", icon: "square.grid.3x3.fill") {
                        Text("\(ChameleonWordBank.topicCount) curated topics · \(ChameleonWordBank.wordCount) words — 16 shuffled per round.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    ChameleonSetupSection(title: "Chameleon knows", icon: "eye.trianglebadge.exclamationmark.fill") {
                        VStack(spacing: 10) {
                            ForEach(ChameleonIntelMode.allCases) { mode in
                                Button {
                                    chameleonIntel = mode
                                    Haptics.impact()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: chameleonIntel == mode ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(chameleonIntel == mode ? CouchTheme.gold : .white.opacity(0.35))

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(mode.title)
                                                .font(.subheadline.weight(.semibold))
                                            Text(mode.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.55))
                                        }

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(chameleonIntel == mode ? .white.opacity(0.12) : .white.opacity(0.05))
                                    }
                                }
                            }
                        }
                    }

                    ChameleonSetupSection(title: "How it works", icon: "text.bubble.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Everyone sees the secret word except one Chameleon", systemImage: "eye.slash")
                            Label("Take turns saying one related word", systemImage: "text.bubble")
                            Label("Vote out the Chameleon — or bluff your way out", systemImage: "hand.raised")
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
                        startGame()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
                    .disabled(config.validationError != nil)
                    .opacity(config.validationError == nil ? 1 : 0.5)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("Chameleon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rules") { showRules = true }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            ChameleonGameView(viewModel: viewModel) {
                navigateToGame = false
                dismiss()
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GameRulebookView(books: [.chameleon])
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

private struct ChameleonSetupSection<Content: View>: View {
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

private struct ChameleonStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            HStack(spacing: 12) {
                stepButton(systemName: "minus", enabled: value > range.lowerBound) { value -= 1 }
                Text("\(value)")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .frame(minWidth: 28)
                stepButton(systemName: "plus", enabled: value < range.upperBound) { value += 1 }
            }
        }
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.bold())
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(enabled ? 0.15 : 0.06)))
        }
        .disabled(!enabled)
    }
}

private struct ChameleonTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.words)
            .foregroundStyle(.white)
            .tint(CouchTheme.gold)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
    }
}

#Preview {
    NavigationStack {
        ChameleonSetupView()
    }
}
