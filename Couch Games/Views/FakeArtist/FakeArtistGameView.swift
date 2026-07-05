//
//  FakeArtistGameView.swift
//  Couch Games
//

import SwiftUI

struct FakeArtistGameView: View {
    @Bindable var viewModel: FakeArtistGameViewModel
    var onExitToHome: () -> Void

    @State private var showLeaveConfirmation = false
    @State private var voteSelection: UUID?
    @State private var activeStrokePoints: [CGPoint] = []

    var body: some View {
        ZStack {
            CouchTheme.fakeArtistGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        FakeArtistBanner(text: viewModel.moderatorScript)

                        if showsColorLegend {
                            colorLegend
                        }

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
        .onChange(of: viewModel.phase) { _, newPhase in
            voteSelection = nil
            if newPhase != .drawing {
                activeStrokePoints = []
            }
        }
        .onChange(of: viewModel.strokeIndex) { _, _ in
            activeStrokePoints = []
        }
    }

    private var showsColorLegend: Bool {
        switch viewModel.phase {
        case .revealDrawing, .voteModeChoice, .voteCollect, .voteGod, .gameOver:
            return true
        default:
            return false
        }
    }

    private var colorLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.players) { player in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.ink(for: player).color)
                            .frame(width: 12, height: 12)
                        Text(player.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.08)))
                }
            }
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .roleReveal:
            roleRevealContent
        case .drawHandoff:
            drawHandoffContent
        case .drawing:
            drawingContent
        case .revealDrawing:
            revealDrawingContent
        case .voteModeChoice:
            voteModeContent
        case .voteCollect, .voteGod:
            voteContent
        case .fakeGuess:
            fakeGuessContent
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

                        HStack(spacing: 8) {
                            Circle()
                                .fill(viewModel.ink(for: player).color)
                                .frame(width: 20, height: 20)
                            Text("\(viewModel.ink(for: player).name) pencil")
                                .font(.headline)
                                .foregroundStyle(viewModel.ink(for: player).color)
                        }

                        if player.isFakeArtist {
                            Text("?")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(GameDisplayNames.sketchImpostorRole)
                                .font(.largeTitle.bold())
                                .foregroundStyle(CouchTheme.fakeArtistAccentGradient)
                            Text("You don't know the word. Blend in when it's your turn to draw.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                        } else {
                            Text(viewModel.prompt.category.uppercased())
                                .font(.caption.weight(.bold))
                                .tracking(1.2)
                                .foregroundStyle(.white.opacity(0.5))
                            Text(viewModel.prompt.word)
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(CouchTheme.gold)
                            Text("Remember this — but don't make it too obvious when you draw.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
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

    private var drawHandoffContent: some View {
        VStack(spacing: 24) {
            if let drawer = viewModel.currentDrawer {
                ReadOnlyDrawingCanvas(strokes: viewModel.strokes) { playerID in
                    colorForPlayerID(playerID)
                }

                VStack(spacing: 12) {
                    Text("Stroke \(viewModel.strokeIndex + 1) of \(viewModel.totalStrokes)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))

                    PlayerBadge(name: drawer.name)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.ink(for: drawer).color)
                            .frame(width: 16, height: 16)
                        Text("Draw with your \(viewModel.ink(for: drawer).name) pencil")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.ink(for: drawer).color)
                    }
                }
            }
        }
    }

    private var drawingContent: some View {
        VStack(spacing: 12) {
            if let drawer = viewModel.currentDrawer {
                HStack {
                    Circle()
                        .fill(viewModel.ink(for: drawer).color)
                        .frame(width: 14, height: 14)
                    Text("\(drawer.name) — one stroke")
                        .font(.subheadline.weight(.semibold))
                }

                InteractiveDrawingCanvas(
                    strokes: viewModel.strokes,
                    activePoints: $activeStrokePoints,
                    strokeColor: viewModel.ink(for: drawer).color,
                    inkLookup: colorForPlayerID
                )

                Text("Tap End Turn when you're done drawing.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var revealDrawingContent: some View {
        VStack(spacing: 16) {
            ReadOnlyDrawingCanvas(strokes: viewModel.strokes) { playerID in
                colorForPlayerID(playerID)
            }

            Text("Category: \(viewModel.prompt.category)")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
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
            ReadOnlyDrawingCanvas(strokes: viewModel.strokes) { playerID in
                colorForPlayerID(playerID)
            }
            .frame(maxHeight: 220)

            if viewModel.phase == .voteCollect, let voter = viewModel.currentVoter {
                PlayerBadge(name: voter.name)
                Text("Who is the Impostor?")
                    .font(.headline)
            } else {
                Text("Who is the Impostor?")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            playerGrid(selectedID: $voteSelection) { id in
                voteSelection = id
            }
        }
    }

    private var fakeGuessContent: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 8) {
                    Text("Category")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(viewModel.prompt.category)
                        .font(.title.bold())
                        .foregroundStyle(CouchTheme.gold)
                }
            }

            Text("Guess the secret word")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.guessOptions, id: \.self) { word in
                    Button {
                        viewModel.submitGuess(word: word)
                    } label: {
                        Text(word)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.white.opacity(0.08))
                            }
                    }
                }
            }
        }
    }

    private var gameOverContent: some View {
        VStack(spacing: 24) {
            Text("🎨")
                .font(.system(size: 72))

            Text(viewModel.outcomeMessage)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(spacing: 8) {
                    Text("The word was")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(viewModel.prompt.word)
                        .font(.largeTitle.bold())
                        .foregroundStyle(CouchTheme.gold)
                }
            }

            ReadOnlyDrawingCanvas(strokes: viewModel.strokes) { playerID in
                colorForPlayerID(playerID)
            }
            .frame(maxHeight: 240)

            if let fake = viewModel.fakeArtist {
                HStack(spacing: 8) {
                    Circle().fill(viewModel.ink(for: fake).color).frame(width: 12, height: 12)
                    Text("Impostor: \(fake.name)")
                        .font(.headline)
                }
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
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))
                } else {
                    Button("Show My Role") { viewModel.revealRoleForCurrentPlayer() }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))
                }

            case .drawHandoff:
                Button("I'm Ready to Draw") {
                    activeStrokePoints = []
                    viewModel.beginDrawingTurn()
                }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))

            case .drawing:
                if activeStrokePoints.count >= 2 {
                    Button("End Turn") {
                        Haptics.impact()
                        viewModel.commitStroke(points: activeStrokePoints)
                        activeStrokePoints = []
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))
                } else {
                    disabledPlaceholder("Draw something first")
                }

            case .revealDrawing:
                Button("Start Voting") { viewModel.continueFromReveal() }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))

            case .voteModeChoice, .fakeGuess:
                EmptyView()

            case .voteCollect, .voteGod:
                if let voteSelection {
                    Button(viewModel.phase == .voteGod ? "Accuse Player" : "Submit Vote") {
                        if viewModel.phase == .voteGod {
                            viewModel.submitGodVote(targetID: voteSelection)
                        } else {
                            viewModel.submitVote(targetID: voteSelection)
                        }
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))
                } else {
                    disabledPlaceholder("Select a player")
                }

            case .gameOver:
                Button("Back to Home") {
                    viewModel.resetToSetup()
                    onExitToHome()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.fakeArtistAccentGradient))

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private func colorForPlayerID(_ id: UUID) -> Color {
        guard let player = viewModel.players.first(where: { $0.id == id }) else {
            return .black
        }
        return viewModel.ink(for: player).color
    }

    private func playerGrid(selectedID: Binding<UUID?>, onSelect: @escaping (UUID) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.players) { player in
                Button {
                    onSelect(player.id)
                    Haptics.impact()
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.ink(for: player).color)
                            .frame(width: 12, height: 12)
                        Text(player.name)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                selectedID.wrappedValue == player.id
                                    ? AnyShapeStyle(CouchTheme.fakeArtistAccentGradient)
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

private struct FakeArtistBanner: View {
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
        FakeArtistGameView(viewModel: FakeArtistGameViewModel()) {}
    }
}
