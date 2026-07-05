//
//  HeadsUpGameView.swift
//  Couch Games
//

import SwiftUI

struct HeadsUpGameView: View {
    @Bindable var viewModel: HeadsUpGameViewModel
    var onExitToHome: () -> Void

    @State private var showLeaveConfirmation = false
    @State private var volumeMonitor = HeadsUpVolumeMonitor()

    var body: some View {
        ZStack {
            CouchTheme.headsUpGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HeadsUpBanner(text: viewModel.moderatorScript)
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

            if viewModel.config.controlMode.usesVolume {
                HiddenVolumeView { volumeView in
                    volumeMonitor.attach(volumeView: volumeView)
                }
                .frame(width: 0, height: 0)
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

            if viewModel.phase == .playing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End") {
                        stopVolumeMonitor()
                        viewModel.endRoundEarly()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .confirmationDialog("Leave this game?", isPresented: $showLeaveConfirmation, titleVisibility: .visible) {
            Button("Leave for Home", role: .destructive) {
                stopVolumeMonitor()
                viewModel.resetToSetup()
                onExitToHome()
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("You'll return to Couch Games to pick another game.")
        }
        .onAppear {
            configureVolumeMonitor()
        }
        .onDisappear {
            stopVolumeMonitor()
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .playing, viewModel.config.controlMode.usesVolume {
                volumeMonitor.start()
            } else {
                stopVolumeMonitor()
            }
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .ready:
            readyContent
        case .playing:
            playingContent
        case .roundSummary:
            roundSummaryContent
        default:
            EmptyView()
        }
    }

    private var readyContent: some View {
        VStack(spacing: 28) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(CouchTheme.gold.opacity(0.85))

            GlassCard {
                VStack(spacing: 14) {
                    if !viewModel.playerName.isEmpty {
                        Text(viewModel.playerName)
                            .font(.title2.bold())
                    }

                    Text("\(viewModel.config.roundDuration)s round")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Put the phone on your forehead", systemImage: "1.circle.fill")
                        Label("Friends see the word — you guess", systemImage: "2.circle.fill")
                        ForEach(Array(readyControlHints.enumerated()), id: \.offset) { index, hint in
                            Label(hint, systemImage: "\(index + 3).circle.fill")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var playingContent: some View {
        VStack(spacing: 20) {
            timerRing

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(CouchTheme.headsUpAccentGradient, lineWidth: 3)
                    }
                    .frame(minHeight: 220)

                if let word = viewModel.currentWord {
                    Text(word)
                        .font(.system(size: wordFontSize(for: word), weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.45)
                        .lineLimit(4)
                        .padding(24)
                } else {
                    Text("No cards left!")
                        .font(.title2.bold())
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            HStack(spacing: 24) {
                statPill(label: "Got it", value: viewModel.correctCount, color: .green)
                statPill(label: "Passed", value: viewModel.passedCount, color: .orange)
            }

            if viewModel.config.controlMode.usesTap {
                tapControls
            }
        }
    }

    private var roundSummaryContent: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 72))

            GlassCard {
                VStack(spacing: 8) {
                    if !viewModel.playerName.isEmpty {
                        Text(viewModel.playerName)
                            .font(.title3.bold())
                    }
                    Text("\(viewModel.correctCount) correct")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(CouchTheme.gold)
                    Text("\(viewModel.passedCount) passed · \(viewModel.roundResults.count) total")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            if !viewModel.roundResults.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This round")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))

                    ForEach(viewModel.roundResults) { result in
                        HStack {
                            Image(systemName: result.wasCorrect ? "checkmark.circle.fill" : "arrow.uturn.forward.circle.fill")
                                .foregroundStyle(result.wasCorrect ? .green : .orange)
                            Text(result.word)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 8)
                .frame(width: 88, height: 88)
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(CouchTheme.headsUpAccentGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 88, height: 88)
            Text("\(viewModel.secondsRemaining)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .monospacedDigit()
        }
    }

    private var tapControls: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                viewModel.markPass()
            } label: {
                Label("Pass", systemImage: "arrow.uturn.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                Haptics.success()
                viewModel.markCorrect()
            } label: {
                Label("Got It", systemImage: "checkmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var pinnedActionButton: some View {
        PinnedActionBar {
            switch viewModel.phase {
            case .ready:
                Button("Start Round") {
                    viewModel.beginRound()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.headsUpAccentGradient))

            case .playing:
                EmptyView()

            case .roundSummary:
                HStack(spacing: 12) {
                    Button("Play Again") {
                        viewModel.playAgain()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.headsUpAccentGradient))

                    Button("Home") {
                        viewModel.resetToSetup()
                        onExitToHome()
                    }
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: GameLayout.actionButtonHeight)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private var readyControlHints: [String] {
        switch viewModel.config.controlMode {
        case .volumeAndTap:
            return ["Volume up = got it · Volume down = pass", "Or tap the on-screen buttons"]
        case .volume:
            return ["Volume up = got it · Volume down = pass"]
        case .tap:
            return ["Tap Pass or Got It on screen"]
        }
    }

    private var timerProgress: CGFloat {
        guard viewModel.config.roundDuration > 0 else { return 0 }
        return CGFloat(viewModel.secondsRemaining) / CGFloat(viewModel.config.roundDuration)
    }

    private func wordFontSize(for word: String) -> CGFloat {
        switch word.count {
        case ...8: return 52
        case ...14: return 42
        case ...20: return 34
        default: return 28
        }
    }

    private func statPill(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(minWidth: 80)
    }

    private func configureVolumeMonitor() {
        volumeMonitor.onVolumeUp = {
            Haptics.success()
            viewModel.markCorrect()
        }
        volumeMonitor.onVolumeDown = {
            Haptics.impact(.light)
            viewModel.markPass()
        }
    }

    private func stopVolumeMonitor() {
        volumeMonitor.stop()
    }
}

private struct HeadsUpBanner: View {
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
        HeadsUpGameView(viewModel: HeadsUpGameViewModel()) {}
    }
}
