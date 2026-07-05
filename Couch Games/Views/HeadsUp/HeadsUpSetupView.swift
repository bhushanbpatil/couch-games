//
//  HeadsUpSetupView.swift
//  Couch Games
//

import SwiftUI

struct HeadsUpSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = HeadsUpGameViewModel()
    @State private var selectedDeckIDs: Set<String> = []
    @State private var roundDuration = 60
    @State private var controlMode: HeadsUpControlMode = .volumeAndTap
    @State private var playerName = ""
    @State private var navigateToGame = false
    @State private var showRules = false

    private var config: HeadsUpSetupConfig {
        HeadsUpSetupConfig(
            deckIDs: selectedDeckIDs,
            roundDuration: roundDuration,
            controlMode: controlMode,
            playerName: playerName
        )
    }

    var body: some View {
        ZStack {
            CouchTheme.headsUpGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HeadsUpSetupSection(title: "Player", icon: "person.fill") {
                        HeadsUpTextField(placeholder: "Name (optional)", text: $playerName)
                        Text("Who's holding the phone this round?")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    HeadsUpSetupSection(title: "Decks", icon: "square.stack.3d.up.fill") {
                        Text("\(HeadsUpWordBank.deckCount) decks · \(HeadsUpWordBank.wordCount) cards. Pick one or mix several.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(HeadsUpWordBank.decks) { deck in
                                deckTile(deck)
                            }
                        }
                    }

                    HeadsUpSetupSection(title: "Round length", icon: "timer") {
                        Picker("Seconds", selection: $roundDuration) {
                            ForEach(HeadsUpSetupConfig.roundDurationOptions, id: \.self) { seconds in
                                Text("\(seconds)s").tag(seconds)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HeadsUpSetupSection(title: "Controls", icon: "speaker.wave.2.fill") {
                        VStack(spacing: 10) {
                            ForEach(HeadsUpControlMode.allCases) { mode in
                                Button {
                                    controlMode = mode
                                    Haptics.impact()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: controlMode == mode ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(controlMode == mode ? CouchTheme.gold : .white.opacity(0.35))
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
                                            .fill(controlMode == mode ? .white.opacity(0.12) : .white.opacity(0.05))
                                    }
                                }
                            }
                        }
                    }

                    if let error = config.validationError {
                        Text(error)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.red.opacity(0.9))
                    }

                    Button("Start Game") {
                        startGame()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.headsUpAccentGradient))
                    .disabled(config.validationError != nil)
                    .opacity(config.validationError != nil ? 0.5 : 1)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("Heads Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rules") { showRules = true }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            if selectedDeckIDs.isEmpty, let first = HeadsUpWordBank.decks.first {
                selectedDeckIDs = [first.id]
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            HeadsUpGameView(viewModel: viewModel) {
                navigateToGame = false
                dismiss()
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GameRulebookView(books: [.headsUp])
            }
        }
    }

    private func deckTile(_ deck: HeadsUpDeck) -> some View {
        let selected = selectedDeckIDs.contains(deck.id)
        return Button {
            if selected {
                selectedDeckIDs.remove(deck.id)
            } else {
                selectedDeckIDs.insert(deck.id)
            }
            Haptics.impact()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: deck.icon)
                    .font(.title2)
                    .foregroundStyle(selected ? CouchTheme.gold : .white.opacity(0.7))
                Text(deck.title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("\(deck.words.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AnyShapeStyle(CouchTheme.headsUpAccentGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
            }
        }
    }

    private func startGame() {
        guard config.validationError == nil else { return }
        viewModel.startGame(config: config)
        navigateToGame = true
    }
}

private struct HeadsUpSetupSection<Content: View>: View {
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

private struct HeadsUpTextField: View {
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
        HeadsUpSetupView()
    }
}
