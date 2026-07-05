//
//  GameplayView.swift
//  Couch Games
//

import SwiftUI

struct GameplayView: View {
    @Bindable var viewModel: TimerGuessViewModel
    var onExitToHome: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var resultRevealed = false
    @State private var showLeaveConfirmation = false

    private let middleZoneHeight: CGFloat = 220

    var body: some View {
        ZStack {
            GameScreenBackground()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    phaseContent
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
        .navigationTitle(viewModel.roundLabel)
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
            ToolbarItem(placement: .topBarTrailing) {
                Button("Leaderboard") {
                    viewModel.showLeaderboard = true
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
        .sheet(isPresented: $viewModel.showLeaderboard) {
            NavigationStack {
                LeaderboardView(
                    players: viewModel.leaderboard,
                    turnHistory: viewModel.turnHistory
                )
            }
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .turnResult {
                resultRevealed = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if viewModel.lastTurnResult?.points ?? 0 >= Scoring.perfectPoints {
                        Haptics.success()
                    } else {
                        Haptics.impact()
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        resultRevealed = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .showTarget, .memorizing:
            activeTurnContent
        case .turnResult:
            if let result = viewModel.lastTurnResult {
                TurnResultContent(result: result, reveal: resultRevealed)
            }
        case .roundSummary:
            roundSummaryContent
        case .gameOver:
            GameOverContent(viewModel: viewModel)
        case .setup:
            EmptyView()
        }
    }

    @ViewBuilder
    private var pinnedActionButton: some View {
        PinnedActionBar {
            switch viewModel.phase {
            case .showTarget:
                Button {
                    Haptics.impact()
                    viewModel.ready()
                } label: {
                    Text("Ready")
                }
                .buttonStyle(CouchPrimaryButton())
                .accessibilityLabel("Ready to start counting")

            case .memorizing:
                Button {
                    Haptics.impact(.heavy)
                    viewModel.stop()
                } label: {
                    Text("Stop")
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.stopGradient))
                .accessibilityLabel("Stop timer")

            case .turnResult:
                Button {
                    viewModel.advanceFromTurnResult()
                } label: {
                    Text("Next")
                }
                .buttonStyle(CouchPrimaryButton())

            case .roundSummary:
                Button {
                    viewModel.advanceFromRoundSummary()
                } label: {
                    Text("Next Round")
                }
                .buttonStyle(CouchPrimaryButton())

            case .gameOver:
                Button {
                    viewModel.resetToSetup()
                    dismiss()
                } label: {
                    Text("Play Again")
                }
                .buttonStyle(CouchPrimaryButton())

            case .setup:
                EmptyView()
            }
        }
    }

    private var activeTurnContent: some View {
        VStack(spacing: 16) {
            if let message = viewModel.passPhoneMessage {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1), in: Capsule())
            }

            if let player = viewModel.currentPlayer {
                PlayerBadge(name: player.name)
            }

            ZStack {
                if viewModel.phase == .showTarget {
                    targetPhaseContent
                        .transition(.opacity)
                } else {
                    ConfusionMascotView()
                        .transition(.opacity)
                }
            }
            .frame(height: middleZoneHeight)
            .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
        }
    }

    private var targetPhaseContent: some View {
        VStack(spacing: 12) {
            Text("Memorize this time")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))

            BigTimeDisplay(
                label: "Target",
                seconds: viewModel.currentTarget,
                size: .hero,
                accent: .white
            )
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(CouchTheme.accentGradient, lineWidth: 2)
                }
        }
    }

    private var roundSummaryContent: some View {
        VStack(spacing: 16) {
            Text("Round \(viewModel.currentRoundIndex + 1) Complete")
                .font(.title2.bold())

            BigTimeDisplay(
                label: "Round target",
                seconds: viewModel.currentTarget,
                size: .companion,
                accent: .white.opacity(0.85)
            )

            LeaderboardPreview(players: viewModel.leaderboard)
        }
    }
}

private struct LeaderboardPreview: View {
    let players: [Player]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                HStack {
                    Text("\(index + 1).")
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 24, alignment: .leading)
                    Text(player.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(player.totalScore)")
                        .monospacedDigit()
                        .font(.title3.bold())
                        .foregroundStyle(CouchTheme.cyan)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.1))
        }
    }
}

#Preview {
    NavigationStack {
        GameplayView(viewModel: {
            let vm = TimerGuessViewModel()
            vm.startGame(config: vm.makeDefaultConfig())
            return vm
        }(), onExitToHome: {})
    }
}
