//
//  ChameleonGameView.swift
//  Couch Games
//

import SwiftUI

struct ChameleonGameView: View {
    @Bindable var viewModel: ChameleonGameViewModel
    var onExitToHome: () -> Void

    @State private var showLeaveConfirmation = false
    @State private var voteSelection: UUID?
    @State private var guessSelection: String?

    var body: some View {
        ZStack {
            CouchTheme.chameleonGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ChameleonBanner(text: viewModel.moderatorScript)
                        phaseContent
                    }
                    .padding(.horizontal, GameLayout.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                pinnedActionButton
                    .padding(.horizontal, GameLayout.horizontalPadding)
                    .padding(.bottom, GameLayout.actionBottomPadding)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showLeaveConfirmation = true
                } label: {
                    Label("Home", systemImage: "house.fill")
                }
                .fontWeight(.semibold)
            }
        }
        .confirmationDialog("Leave this game?", isPresented: $showLeaveConfirmation, titleVisibility: .visible) {
            Button("Leave for Home", role: .destructive) {
                viewModel.resetToSetup()
                onExitToHome()
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("You'll return to Couch Games to pick another game.")
        }
        .onChange(of: viewModel.phase) { _, _ in
            voteSelection = nil
            guessSelection = nil
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .roleReveal:
            roleRevealContent
        case .discussion:
            discussionContent
        case .voteModeChoice:
            voteModeContent
        case .voteCollect, .voteGod:
            voteContent
        case .chameleonGuess:
            chameleonGuessContent
        case .gameOver:
            gameOverContent
        default:
            EmptyView()
        }
    }

    private var roleRevealContent: some View {
        VStack(spacing: 24) {
            if viewModel.showingRole, let player = viewModel.currentRevealPlayer {
                GlassCard {
                    VStack(spacing: 16) {
                        Text(player.name)
                            .font(.title2.bold())

                        if player.isChameleon {
                            chameleonRoleContent
                        } else {
                            innocentRoleContent
                        }
                    }
                }
            } else if let player = viewModel.currentRevealPlayer {
                VStack(spacing: 20) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Hand the phone to")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                    PlayerBadge(name: player.name)
                }
                .padding(.top, 24)
            }

            progressPill(current: viewModel.revealIndex + 1, total: viewModel.players.count)
        }
    }

    private var innocentRoleContent: some View {
        Group {
            Text(viewModel.round.topic.category.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.5))

            ChameleonWordGrid(
                words: viewModel.gridWords,
                secretIndex: viewModel.round.secretIndex
            )

            Text("Remember your word — don't make it too obvious when you give a clue.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var chameleonRoleContent: some View {
        Text("🦎")
            .font(.system(size: 56))
        Text(GameDisplayNames.wordSpyRole)
            .font(.largeTitle.bold())
            .foregroundStyle(CouchTheme.chameleonAccentGradient)

        switch viewModel.chameleonIntel {
        case .completeBlind:
            Text("You know nothing — not even the category. Listen to everyone else and bluff.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)

        case .categoryOnly:
            Text(viewModel.round.topic.category.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.5))
            Text("You know the category — not the secret word. Stay vague.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)

        case .wordGrid:
            Text(viewModel.round.topic.category.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.5))
            Text("You don't know which word is secret. Study the grid and blend in.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)

            ChameleonWordGrid(
                words: viewModel.gridWords,
                secretIndex: nil
            )
        }
    }

    private var discussionContent: some View {
        VStack(spacing: 24) {
            if viewModel.showsCategoryDuringGame {
                categoryCard
            } else {
                GlassCard {
                    VStack(spacing: 8) {
                        Text("Category hidden")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("Word Spy is flying blind")
                            .font(.title3.bold())
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }

            if let speaker = viewModel.currentSpeaker {
                VStack(spacing: 12) {
                    Text("Say one word")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.65))
                    PlayerBadge(name: speaker.name)
                }
            }

            progressPill(current: viewModel.discussionIndex + 1, total: viewModel.players.count)
        }
    }

    private var voteModeContent: some View {
        VStack(spacing: 16) {
            voteModeRow(icon: "iphone.and.arrow.forward", title: "Pass the Phone", subtitle: "Private votes") {
                viewModel.chooseVoteMode(.passPhone)
            }
            voteModeRow(icon: "person.fill.checkmark", title: "Moderator Override", subtitle: "God taps the group's pick") {
                viewModel.chooseVoteMode(.godOverride)
            }
        }
    }

    private var voteContent: some View {
        VStack(spacing: 16) {
            if viewModel.showsCategoryDuringGame {
                categoryCard
            }

            if viewModel.phase == .voteCollect, let voter = viewModel.currentVoter {
                PlayerBadge(name: voter.name)
            }

            Text("Who is the Word Spy?")
                .font(.headline)

            playerGrid(selectedID: $voteSelection) { id in
                voteSelection = id
            }
        }
    }

    private var chameleonGuessContent: some View {
        VStack(spacing: 16) {
            Text("Pick the secret word")
                .font(.headline)

            ChameleonWordGrid(
                words: viewModel.gridWords,
                secretIndex: nil,
                selectedWord: guessSelection,
                onSelect: { word in
                    guessSelection = word
                    Haptics.impact()
                }
            )
        }
    }

    private var gameOverContent: some View {
        VStack(spacing: 24) {
            Text("🦎")
                .font(.system(size: 72))

            Text(viewModel.outcomeMessage)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(spacing: 12) {
                    Text("The word was")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(viewModel.round.secretWord)
                        .font(.largeTitle.bold())
                        .foregroundStyle(CouchTheme.gold)
                    Text(viewModel.round.topic.category)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            ChameleonWordGrid(
                words: viewModel.gridWords,
                secretIndex: viewModel.round.secretIndex
            )

            if let chameleon = viewModel.chameleon {
                Text("Word Spy: \(chameleon.name)")
                    .font(.headline)
            }
        }
    }

    @ViewBuilder
    private var pinnedActionButton: some View {
        PinnedActionBar {
            switch viewModel.phase {
            case .roleReveal:
                if viewModel.showingRole {
                    Button("Got it — Hide") { viewModel.confirmRoleSeen() }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
                } else {
                    Button("Show My Role") { viewModel.revealRoleForCurrentPlayer() }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
                }

            case .discussion:
                Button(viewModel.discussionIndex + 1 < viewModel.players.count ? "Next Player" : "Start Voting") {
                    viewModel.advanceDiscussion()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))

            case .voteModeChoice, .chameleonGuess:
                if viewModel.phase == .chameleonGuess, let guessSelection {
                    Button("Submit Guess") {
                        viewModel.submitChameleonGuess(word: guessSelection)
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
                } else if viewModel.phase == .chameleonGuess {
                    disabledPlaceholder("Select a word")
                } else {
                    EmptyView()
                }

            case .voteCollect, .voteGod:
                if let voteSelection {
                    Button(viewModel.phase == .voteGod ? "Accuse Player" : "Submit Vote") {
                        if viewModel.phase == .voteGod {
                            viewModel.submitGodVote(targetID: voteSelection)
                        } else {
                            viewModel.submitVote(targetID: voteSelection)
                        }
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))
                } else {
                    disabledPlaceholder("Select a player")
                }

            case .gameOver:
                Button("Back to Home") {
                    viewModel.resetToSetup()
                    onExitToHome()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.chameleonAccentGradient))

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private var categoryCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Text("Category")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.55))
                Text(viewModel.round.topic.category)
                    .font(.title.bold())
                    .foregroundStyle(CouchTheme.gold)
            }
        }
    }

    private func playerGrid(selectedID: Binding<UUID?>, onSelect: @escaping (UUID) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.players) { player in
                Button {
                    onSelect(player.id)
                    Haptics.impact()
                } label: {
                    Text(player.name)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    selectedID.wrappedValue == player.id
                                        ? AnyShapeStyle(CouchTheme.chameleonAccentGradient)
                                        : AnyShapeStyle(Color.white.opacity(0.08))
                                )
                        }
                }
            }
        }
    }

    private func voteModeRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44)
                    .foregroundStyle(CouchTheme.gold)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.footnote).foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.35))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.08)))
        }
    }

    private func disabledPlaceholder(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .foregroundStyle(.white.opacity(0.35))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.06)))
    }

    private func progressPill(current: Int, total: Int) -> some View {
        Text("Player \(current) of \(total)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.08)))
    }
}

struct ChameleonWordGrid: View {
    let words: [String]
    let secretIndex: Int?
    var selectedWord: String?
    var onSelect: ((String) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                let isSecret = secretIndex == index
                let isSelected = selectedWord == word

                if let onSelect {
                    Button {
                        onSelect(word)
                    } label: {
                        cell(word: word, isSecret: isSecret, isSelected: isSelected)
                    }
                } else {
                    cell(word: word, isSecret: isSecret, isSelected: isSelected)
                }
            }
        }
    }

    @ViewBuilder
    private func cell(word: String, isSecret: Bool, isSelected: Bool) -> some View {
        Text(word)
            .font(.caption.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 4)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background(forSecret: isSecret, selected: isSelected))
                    .overlay {
                        if isSecret {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(CouchTheme.gold, lineWidth: 2)
                        }
                    }
            }
            .foregroundStyle(isSecret ? CouchTheme.gold : .white.opacity(0.85))
    }

    private func background(forSecret isSecret: Bool, selected: Bool) -> some ShapeStyle {
        if selected {
            return AnyShapeStyle(CouchTheme.chameleonAccentGradient)
        }
        if isSecret {
            return AnyShapeStyle(Color.white.opacity(0.18))
        }
        return AnyShapeStyle(Color.white.opacity(0.06))
    }
}

private struct ChameleonBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.06)))
    }
}

#Preview {
    NavigationStack {
        ChameleonGameView(viewModel: ChameleonGameViewModel()) {}
    }
}
