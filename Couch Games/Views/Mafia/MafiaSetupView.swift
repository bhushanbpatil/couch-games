//
//  MafiaSetupView.swift
//  Couch Games
//

import SwiftUI

struct MafiaSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MafiaGameViewModel()
    @State private var totalPlayers = 6
    @State private var mafiaCount = 2
    @State private var policeCount = 1
    @State private var nurseCount = 1
    @State private var playerNames: [String] = (1...6).map { "Player \($0)" }
    @State private var navigateToGame = false
    @State private var showRules = false

    private var config: MafiaSetupConfig {
        MafiaSetupConfig(
            totalPlayers: totalPlayers,
            mafiaCount: mafiaCount,
            policeCount: policeCount,
            nurseCount: nurseCount,
            playerNames: playerNames
        )
    }

    var body: some View {
        ZStack {
            CouchTheme.mafiaGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    MafiaSetupSection(title: "Players", icon: "person.3.fill") {
                        MafiaStepper(
                            label: "Total players",
                            value: $totalPlayers,
                            range: MafiaSetupConfig.minPlayers...MafiaSetupConfig.maxPlayers
                        )
                        .onChange(of: totalPlayers) { _, newValue in
                            syncPlayerNames(count: newValue)
                            clampRoles()
                        }

                        ForEach(playerNames.indices, id: \.self) { index in
                            MafiaTextField(
                                placeholder: "Player \(index + 1)",
                                text: $playerNames[index],
                                icon: "person.fill"
                            )
                        }
                    }

                    MafiaSetupSection(title: "Roles", icon: "theatermasks.fill") {
                        MafiaStepper(label: GameDisplayNames.traitor, value: $mafiaCount, range: 1...maxMafia)
                            .onChange(of: mafiaCount) { _, _ in clampRoles() }
                        MafiaStepper(label: "Police", value: $policeCount, range: 0...maxSpecialRoles)
                            .onChange(of: policeCount) { _, _ in clampRoles() }
                        MafiaStepper(label: "Nurse", value: $nurseCount, range: 0...maxSpecialRoles)
                            .onChange(of: nurseCount) { _, _ in clampRoles() }

                        HStack {
                            Text("Villagers")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.65))
                            Spacer()
                            Text("\(config.villagerCount)")
                                .font(.title3.bold())
                                .foregroundStyle(CouchTheme.gold)
                        }
                        .padding(.top, 4)
                    }

                    if let error = config.validationError {
                        Text(error)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Pass the phone so each player sees their role privately. One person moderates.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }

                    Button("Start Game") {
                        startGame()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
                    .disabled(config.validationError != nil)
                    .opacity(config.validationError == nil ? 1 : 0.5)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(GameDisplayNames.villageTraitors)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rules") { showRules = true }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            MafiaGameView(viewModel: viewModel) {
                navigateToGame = false
                dismiss()
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GameRulebookView(books: [.mafia])
            }
        }
    }

    private var maxMafia: Int {
        max(1, totalPlayers - policeCount - nurseCount - 1)
    }

    private var maxSpecialRoles: Int {
        max(0, totalPlayers - mafiaCount - 1)
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

    private func clampRoles() {
        mafiaCount = min(mafiaCount, maxMafia)
        let specialCap = maxSpecialRoles
        policeCount = min(policeCount, specialCap)
        nurseCount = min(nurseCount, specialCap)
        if policeCount + nurseCount > totalPlayers - mafiaCount - 1 {
            nurseCount = max(0, totalPlayers - mafiaCount - policeCount - 1)
        }
    }

    private func startGame() {
        guard config.validationError == nil else { return }
        viewModel.startGame(config: config)
        navigateToGame = true
    }
}

private struct MafiaSetupSection<Content: View>: View {
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

private struct MafiaStepper: View {
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
                    .foregroundStyle(CouchTheme.gold)
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
                        .fill(
                            enabled
                                ? CouchTheme.mafiaAccentGradient
                                : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                        )
                }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

private struct MafiaTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.red.opacity(0.75))
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .foregroundStyle(.white)
                .tint(CouchTheme.gold)
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
        MafiaSetupView()
    }
}
