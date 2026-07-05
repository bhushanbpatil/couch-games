//
//  FakeArtistSetupView.swift
//  Couch Games
//

import SwiftUI

struct FakeArtistSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FakeArtistGameViewModel()
    @State private var playerCount = 5
    @State private var playerNames: [String] = (1...5).map { "Player \($0)" }
    @State private var navigateToGame = false
    @State private var showRules = false

    private var config: FakeArtistSetupConfig {
        FakeArtistSetupConfig(playerNames: playerNames)
    }

    var body: some View {
        ZStack {
            CouchTheme.fakeArtistGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    FakeArtistSetupSection(title: "Players", icon: "person.3.fill") {
                        FakeArtistStepper(
                            label: "Number of players",
                            value: $playerCount,
                            range: FakeArtistSetupConfig.minPlayers...FakeArtistSetupConfig.maxPlayers
                        )
                        .onChange(of: playerCount) { _, newValue in
                            syncPlayerNames(count: newValue)
                        }

                        ForEach(playerNames.indices, id: \.self) { index in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(FakeArtistColorPalette.ink(for: index).color)
                                    .frame(width: 14, height: 14)

                                FakeArtistTextField(
                                    placeholder: "Player \(index + 1)",
                                    text: $playerNames[index]
                                )
                            }
                        }
                    }

                    FakeArtistSetupSection(title: "Word bank", icon: "text.book.closed.fill") {
                        Text("\(FakeArtistWordBank.promptCount) drawable words across \(FakeArtistWordBank.categories.count) categories.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    FakeArtistSetupSection(title: "How it works", icon: "paintbrush.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Each player gets a unique pencil color", systemImage: "pencil.tip")
                            Label("2 rounds — one stroke per turn", systemImage: "arrow.triangle.2.circlepath")
                            Label("Find who doesn't know the secret word", systemImage: "magnifyingglass")
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
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))
                    .disabled(config.validationError != nil)
                    .opacity(config.validationError == nil ? 1 : 0.5)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.sketchImpostor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rules") { showRules = true }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            FakeArtistGameView(viewModel: viewModel) {
                navigateToGame = false
                dismiss()
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GameRulebookView(books: [.fakeArtist])
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

private struct FakeArtistSetupSection<Content: View>: View {
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

private struct FakeArtistStepper: View {
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

private struct FakeArtistTextField: View {
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
        FakeArtistSetupView()
    }
}
