//
//  BluffBarrelGameView.swift
//  Couch Games
//

import SwiftUI

struct BluffBarrelClientActions {
    let play: ([UUID]) -> Void
    let callLiar: () -> Void
    let pullTrigger: () -> Void
    let confirmRoundIntro: () -> Void
    let continueToRoulette: () -> Void
    let acknowledgeRouletteResult: () -> Void
}

struct BluffBarrelGameView: View {
    @Bindable var viewModel: BluffBarrelGameViewModel
    var localPlayerID: UUID?
    var connectedClientActions: BluffBarrelClientActions?
    var onConnectedAction: (() -> Void)?
    var onExit: () -> Void

    @State private var selectedCardIDs: Set<UUID> = []
    @State private var showLeaveConfirm = false
    @State private var passAndPlayHandRevealed = false

    private var isPassAndPlay: Bool {
        localPlayerID == nil && connectedClientActions == nil
    }

    var body: some View {
        ZStack {
            CouchTheme.bluffBarrelGradient.ignoresSafeArea()

            if viewModel.phase == .rouletteResult {
                rouletteResultScreen
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        BluffBarrelBanner(text: viewModel.moderatorScript)

                        tableRankBadge

                        if shouldShowLastPlay {
                            BluffBarrelLastPlayDisplay(
                                playerName: lastPlayPlayerName,
                                cardCount: viewModel.lastPlayCount,
                                claimedRank: viewModel.tableRank
                            )
                        }

                        playerStatusList

                        phaseContent
                    }
                    .padding(20)
                }
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Leave") { showLeaveConfirm = true }
            }
        }
        .confirmationDialog("Leave game?", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
            Button("Leave Game", role: .destructive, action: onExit)
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            selectedCardIDs = []
            passAndPlayHandRevealed = false
            if newPhase == .rouletteResult {
                if viewModel.lastRouletteHit {
                    Haptics.error()
                } else {
                    Haptics.success()
                }
            }
        }
        .onChange(of: viewModel.activePlayer?.id) { _, _ in
            selectedCardIDs = []
            passAndPlayHandRevealed = false
        }
    }

    private var shouldShowLastPlay: Bool {
        guard viewModel.lastPlay != nil, viewModel.lastPlayCount > 0 else { return false }
        switch viewModel.phase {
        case .respond, .reveal, .roulette: return true
        default: return false
        }
    }

    private var lastPlayPlayerName: String {
        guard let last = viewModel.lastPlay else { return "Player" }
        return viewModel.player(with: last.playerID)?.name ?? "Player"
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .roundIntro:
            if canModerate {
                Button("Deal & Start Round") {
                    performConfirmRoundIntro()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
            } else {
                Text("Waiting for the host…")
                    .foregroundStyle(.white.opacity(0.65))
            }

        case .mustPlay, .respond:
            if canAct {
                if isPassAndPlay && !passAndPlayHandRevealed {
                    passAndPlayTurnBuffer
                } else {
                    actionSection
                }
            } else if localPlayerID != nil {
                Text("Waiting for \(viewModel.activePlayer?.name ?? "another player")…")
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                passAndPlayWaitingSection
            }

        case .reveal:
            revealSection
            if canModerate {
                Button("Continue") {
                    performContinueToRoulette()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
            }

        case .roulette:
            rouletteSection

        case .gameOver:
            gameOverSection

        default:
            EmptyView()
        }
    }

    private var passAndPlayWaitingSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.45))

            Text("Pass the phone to")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))

            Text(viewModel.activePlayer?.name ?? "the active player")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Their cards stay hidden until they tap Show My Hand.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    private var passAndPlayTurnBuffer: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(CouchTheme.gold.opacity(0.85))

                Text("Your turn, \(viewModel.activePlayer?.name ?? "Player")")
                    .font(.title2.bold())

                Text("Cards are hidden. Only you should tap below.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)

            if viewModel.phase == .respond, viewModel.lastPlay != nil {
                Button("Call Liar!") {
                    performCallLiar()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.stopGradient))
            }

            Button("Show My Hand") {
                passAndPlayHandRevealed = true
            }
            .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
        }
    }

    private var actionSection: some View {
        VStack(spacing: 14) {
            if isPassAndPlay {
                HStack {
                    Text("Your hand — don't let others peek.")
                        .font(.footnote)
                        .foregroundStyle(CouchTheme.gold.opacity(0.9))
                    Spacer()
                    Button("Hide Hand") {
                        passAndPlayHandRevealed = false
                        selectedCardIDs = []
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(.white.opacity(0.75))
                }
            } else if localPlayerID == nil {
                Text("Only \(viewModel.activePlayer?.name ?? "you") should look.")
                    .font(.footnote)
                    .foregroundStyle(CouchTheme.gold.opacity(0.9))
            }

            if let playerID = actingPlayerID {
                handGrid(for: playerID)
            }

            if viewModel.phase == .respond, viewModel.lastPlay != nil {
                Button("Call Liar!") {
                    performCallLiar()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.stopGradient))
            }

            if !selectedCardIDs.isEmpty {
                Button("Play \(selectedCardIDs.count) Card\(selectedCardIDs.count == 1 ? "" : "s")") {
                    performPlay(Array(selectedCardIDs))
                    selectedCardIDs = []
                    passAndPlayHandRevealed = false
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
            }
        }
    }

    private var revealSection: some View {
        VStack(spacing: 12) {
            if !viewModel.revealedCards.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(3, viewModel.revealedCards.count)), spacing: 8) {
                    ForEach(viewModel.revealedCards) { card in
                        BluffBarrelCardTile(card: card, tableRank: viewModel.tableRank, isRevealed: true)
                    }
                }
            }
            if let lied = viewModel.lied {
                Text(lied ? "Liar!" : "Honest play!")
                    .font(.title2.bold())
                    .foregroundStyle(lied ? Color.red.opacity(0.9) : CouchTheme.gold)
            }
        }
    }

    private var rouletteSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "scope")
                .font(.system(size: 56))
                .foregroundStyle(CouchTheme.bluffBarrelAccentGradient)

            if let target = viewModel.rouletteTarget {
                Text("\(target.name) — \(target.rouletteChambersRemaining) chamber\(target.rouletteChambersRemaining == 1 ? "" : "s") left")
                    .font(.headline)
            }

            if canPullTrigger {
                Button("Pull Trigger") {
                    performPullTrigger()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.stopGradient))
            } else if localPlayerID != nil {
                Text("Waiting for \(viewModel.rouletteTarget?.name ?? "player")…")
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                Text("Pass the phone to \(viewModel.rouletteTarget?.name ?? "the player").")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private var rouletteResultScreen: some View {
        let target = viewModel.rouletteTarget
        let survived = !viewModel.lastRouletteHit

        return VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text(survived ? "CLICK!" : "BANG!")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(survived ? CouchTheme.gold : Color.red.opacity(0.95))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

                Text(survived ? "SURVIVED" : "ELIMINATED")
                    .font(.title.bold())
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.85))

                if let target {
                    Text(target.name)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    if survived {
                        Text("Empty chamber — lives to bluff another day.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            Image(systemName: "scope")
                            Text("\(target.rouletteChambersRemaining) chamber\(target.rouletteChambersRemaining == 1 ? "" : "s") left")
                                .font(.title3.bold())
                        }
                        .foregroundStyle(CouchTheme.gold)
                        .padding(.top, 4)
                    } else {
                        Text("Out of the game.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.65))

                        Text("💀")
                            .font(.system(size: 56))
                            .padding(.top, 4)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.black.opacity(0.35))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                survived ? CouchTheme.gold.opacity(0.45) : Color.red.opacity(0.35),
                                lineWidth: 2
                            )
                    }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Text("Show this screen to the group")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))

                if canModerate {
                    Button("Continue") {
                        performAcknowledgeRouletteResult()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
                } else {
                    Text("Waiting for the host…")
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .foregroundStyle(.white)
    }

    private var gameOverSection: some View {
        VStack(spacing: 16) {
            if let winner = viewModel.players.first(where: { $0.id == viewModel.winnerID }) {
                Text("🏆")
                    .font(.system(size: 64))
                Text("\(winner.name) wins!")
                    .font(.title.bold())
            }
            Button("Done") { onExit() }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.bluffBarrelAccentGradient))
        }
    }

    private var tableRankBadge: some View {
        VStack(spacing: 6) {
            Text("TABLE")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))
            Text(viewModel.tableRank.displayName.uppercased())
                .font(.largeTitle.bold())
                .foregroundStyle(CouchTheme.gold)
        }
        .padding(.vertical, 8)
    }

    private var playerStatusList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.players.filter(\.isAlive)) { player in
                HStack {
                    Text(player.name)
                        .font(.headline)
                    if player.id == viewModel.activePlayer?.id {
                        Text("Turn")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(CouchTheme.gold.opacity(0.25)))
                    }
                    Spacer()
                    Text("\(player.hand.count) cards")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                    Text("🔫 \(player.rouletteChambersRemaining)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
            }
        }
    }

    @ViewBuilder
    private func handGrid(for playerID: UUID) -> some View {
        let hand = viewModel.hand(for: playerID)
        if hand.isEmpty {
            Text("No cards left")
                .foregroundStyle(.white.opacity(0.55))
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(hand) { card in
                    Button {
                        toggleSelection(card.id)
                    } label: {
                        BluffBarrelCardTile(
                            card: card,
                            tableRank: viewModel.tableRank,
                            isRevealed: true,
                            isSelected: selectedCardIDs.contains(card.id)
                        )
                    }
                }
            }
        }
    }

    private var actingPlayerID: UUID? {
        if let localPlayerID { return localPlayerID }
        return viewModel.activePlayer?.id
    }

    private var canAct: Bool {
        guard let active = viewModel.activePlayer?.id else { return false }
        if let localPlayerID { return active == localPlayerID }
        return true
    }

    private var canPullTrigger: Bool {
        guard let target = viewModel.rouletteTargetID else { return false }
        if let localPlayerID { return localPlayerID == target }
        return true
    }

    private var canModerate: Bool {
        if localPlayerID == nil { return true }
        return viewModel.isConnectedHost
    }

    private func performConfirmRoundIntro() {
        if let connectedClientActions {
            connectedClientActions.confirmRoundIntro()
        } else {
            viewModel.confirmRoundIntro()
            onConnectedAction?()
        }
    }

    private func performContinueToRoulette() {
        if let connectedClientActions {
            connectedClientActions.continueToRoulette()
        } else {
            viewModel.continueToRoulette()
            onConnectedAction?()
        }
    }

    private func performPlay(_ cardIDs: [UUID]) {
        if let connectedClientActions {
            connectedClientActions.play(cardIDs)
        } else if let id = actingPlayerID {
            viewModel.submitPlay(playerID: id, cardIDs: cardIDs)
            passAndPlayHandRevealed = false
            onConnectedAction?()
        }
    }

    private func performCallLiar() {
        if let connectedClientActions {
            connectedClientActions.callLiar()
        } else if let id = actingPlayerID {
            viewModel.callLiar(callerID: id)
            passAndPlayHandRevealed = false
            onConnectedAction?()
        }
    }

    private func performPullTrigger() {
        if let connectedClientActions {
            connectedClientActions.pullTrigger()
        } else {
            viewModel.pullTrigger()
            onConnectedAction?()
        }
    }

    private func performAcknowledgeRouletteResult() {
        if let connectedClientActions {
            connectedClientActions.acknowledgeRouletteResult()
        } else {
            viewModel.acknowledgeRouletteResult()
            onConnectedAction?()
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedCardIDs.contains(id) {
            selectedCardIDs.remove(id)
        } else if selectedCardIDs.count < BluffBarrelSetupConfig.maxPlayCount {
            selectedCardIDs.insert(id)
        }
    }
}

struct BluffBarrelCardTile: View {
    let card: BluffBarrelCard
    let tableRank: BluffBarrelRank
    var isRevealed: Bool = false
    var isSelected: Bool = false

    var body: some View {
        let valid = card.isValid(for: tableRank)
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor(valid: valid))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? CouchTheme.gold : .clear, lineWidth: 3)
                }
            Text(card.rank.shortLabel)
                .font(.title2.bold())
                .foregroundStyle(textColor(valid: valid))
        }
        .frame(height: 72)
    }

    private func backgroundColor(valid: Bool) -> Color {
        if !isRevealed { return .white.opacity(0.12) }
        if !valid { return Color.red.opacity(0.35) }
        switch card.rank {
        case .king: return Color(red: 0.35, green: 0.22, blue: 0.55)
        case .queen: return Color(red: 0.55, green: 0.22, blue: 0.42)
        case .ace: return Color(red: 0.45, green: 0.35, blue: 0.12)
        case .joker: return Color(red: 0.15, green: 0.45, blue: 0.28)
        }
    }

    private func textColor(valid: Bool) -> Color {
        valid ? .white : .white.opacity(0.9)
    }
}

private struct BluffBarrelLastPlayDisplay: View {
    let playerName: String
    let cardCount: Int
    let claimedRank: BluffBarrelRank

    var body: some View {
        VStack(spacing: 16) {
            Text("ON THE TABLE")
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            Text(playerName)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text("played \(cardCount) card\(cardCount == 1 ? "" : "s") face down")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))

            Text("Claimed: all \(claimedRank.displayName)s")
                .font(.headline)
                .foregroundStyle(CouchTheme.gold)

            HStack(spacing: 14) {
                ForEach(0..<cardCount, id: \.self) { _ in
                    BluffBarrelFaceDownCard()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(CouchTheme.gold.opacity(0.35), lineWidth: 1.5)
                }
        }
    }
}

private struct BluffBarrelFaceDownCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.14, blue: 0.08), Color(red: 0.14, green: 0.09, blue: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                }

            VStack(spacing: 6) {
                Image(systemName: "suit.club.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.25))
                Text("?")
                    .font(.title.bold())
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(width: 88, height: 120)
    }
}

private struct BluffBarrelBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)))
    }
}

#Preview {
    NavigationStack {
        BluffBarrelGameView(viewModel: BluffBarrelGameViewModel()) {}
    }
}
