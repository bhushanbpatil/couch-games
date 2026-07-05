//
//  MafiaGameView.swift
//  Couch Games
//

import SwiftUI

struct MafiaGameView: View {
    @Bindable var viewModel: MafiaGameViewModel
    var onExitToHome: () -> Void

    @State private var selectedPlayerID: UUID?
    @State private var showLeaveConfirmation = false

    var body: some View {
        ZStack {
            CouchTheme.mafiaGradient
                .ignoresSafeArea()

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
            selectedPlayerID = nil
        }
    }

    // MARK: - Phase content

    @ViewBuilder
    private var phaseContent: some View {
        ModeratorBanner(text: viewModel.moderatorScript)

        switch viewModel.phase {
        case .roleReveal:
            roleRevealContent
        case .nightIntro:
            nightIntroContent
        case .nightMafia:
            nightActionContent(
                title: "Who does the Mafia eliminate?",
                players: viewModel.alivePlayers.filter { $0.role != .mafia },
                selection: $selectedPlayerID,
                onSelect: viewModel.selectNightKill
            )
        case .nightNurse:
            nightActionContent(
                title: "Who does the Nurse save?",
                players: viewModel.alivePlayers,
                selection: $selectedPlayerID,
                onSelect: viewModel.selectNightSave
            )
        case .nightPolice:
            nightActionContent(
                title: "Who does the Police investigate?",
                players: viewModel.alivePlayers,
                selection: $selectedPlayerID,
                onSelect: viewModel.selectPoliceCheck
            )
        case .nightPoliceResult:
            policeResultContent
        case .dawn:
            dawnContent
        case .dayDiscussion:
            aliveRosterContent
        case .voteModeChoice:
            voteModeContent
        case .dayVoteCollect, .dayRevote, .dayFinalVote:
            voteContent
        case .dayDefense:
            defenseContent
        case .eliminationReveal:
            eliminationContent
        case .gameOver:
            gameOverContent
        default:
            EmptyView()
        }
    }

    // MARK: - Sections

    private var roleRevealContent: some View {
        VStack(spacing: 24) {
            if viewModel.showingRole, let player = viewModel.currentRevealPlayer {
                GlassCard {
                    VStack(spacing: 16) {
                        Text(player.name)
                            .font(.title2.bold())

                        Text(player.role.emoji)
                            .font(.system(size: 72))

                        Text(player.role.displayName)
                            .font(.largeTitle.bold())
                            .foregroundStyle(CouchTheme.gold)

                        Text(player.role.instruction)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
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

                    Text("Tap when you're ready — only they should look.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
            }

            progressPill(current: viewModel.revealIndex + 1, total: viewModel.players.count, label: "Player")
        }
    }

    private var nightIntroContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72))
                .foregroundStyle(CouchTheme.gold.opacity(0.8))

            Text("The town falls asleep…")
                .font(.title2.bold())

            aliveRosterContent
        }
        .padding(.top, 16)
    }

    private func nightActionContent(
        title: String,
        players: [MafiaPlayer],
        selection: Binding<UUID?>,
        onSelect: @escaping (UUID) -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)

            playerPickerGrid(players: players, selection: selection, onSelect: onSelect)
        }
    }

    private var policeResultContent: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 16) {
                    Text("Investigation")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.6))

                    if let name = viewModel.lastPoliceTargetName {
                        Text(name)
                            .font(.title.bold())
                    }

                    HStack(spacing: 12) {
                        Image(systemName: viewModel.lastPoliceWasMafia ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(viewModel.lastPoliceWasMafia ? Color.green : Color.red.opacity(0.85))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.lastPoliceWasMafia ? "Yes — Mafia" : "No — Not Mafia")
                                .font(.title3.bold())
                            Text("Show the Police privately. Nod in real life too.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
            }
        }
    }

    private var dawnContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 64))
                .foregroundStyle(CouchTheme.gold)

            if viewModel.lastNightWasSaved, let name = viewModel.lastNightDeathName {
                GlassCard {
                    VStack(spacing: 8) {
                        Text("Someone tried to eliminate \(name)…")
                            .font(.headline)
                        Text("The Nurse saved them!")
                            .font(.title3.bold())
                            .foregroundStyle(Color.green)
                    }
                }
            } else if let name = viewModel.lastNightDeathName {
                GlassCard {
                    VStack(spacing: 8) {
                        Text("\(name) was eliminated last night.")
                            .font(.title3.bold())
                            .foregroundStyle(Color.red.opacity(0.9))
                        Text("Say your goodbyes.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            } else {
                GlassCard {
                    Text("Everyone survived the night.")
                        .font(.title3.bold())
                }
            }

            aliveRosterContent
        }
    }

    private var voteModeContent: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.chooseVoteMode(.passPhone)
            } label: {
                voteModeRow(
                    icon: "iphone.and.arrow.forward",
                    title: "Pass the Phone",
                    subtitle: "Each player votes privately"
                )
            }

            Button {
                viewModel.chooseVoteMode(.godOverride)
            } label: {
                voteModeRow(
                    icon: "person.fill.checkmark",
                    title: "Moderator Override",
                    subtitle: "God taps the group's choice — no passing"
                )
            }
        }
    }

    private var voteContent: some View {
        VStack(spacing: 16) {
            if viewModel.voteMode == .passPhone, let voter = viewModel.currentVoter {
                VStack(spacing: 8) {
                    Text(votePhaseLabel)
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.55))
                    PlayerBadge(name: voter.name)
                    Text("Only you should look.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                Text(votePhaseLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            playerPickerGrid(
                players: viewModel.alivePlayers,
                selection: $selectedPlayerID,
                onSelect: { id in selectedPlayerID = id }
            )
        }
    }

    private var defenseContent: some View {
        VStack(spacing: 20) {
            if let accused = viewModel.accusedPlayer {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("Accused")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(accused.name)
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.orange)
                        Text("Make your case. The town may change their minds before the final vote.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                }
            }

            aliveRosterContent
        }
    }

    private var eliminationContent: some View {
        VStack(spacing: 20) {
            if let eliminated = viewModel.eliminatedPlayer {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("Eliminated")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(eliminated.name)
                            .font(.largeTitle.bold())
                        Text("\(eliminated.role.emoji) \(eliminated.role.displayName)")
                            .font(.title2.bold())
                            .foregroundStyle(eliminated.role == .mafia ? Color.red.opacity(0.9) : CouchTheme.gold)
                    }
                }
            }

            aliveRosterContent
        }
    }

    private var gameOverContent: some View {
        VStack(spacing: 24) {
            Text(viewModel.winner == .mafia ? "🕶️" : "🏠")
                .font(.system(size: 72))

            Text(viewModel.winner == .mafia ? "Mafia Win!" : "Town Wins!")
                .font(.largeTitle.bold())
                .foregroundStyle(viewModel.winner == .mafia ? Color.red.opacity(0.9) : CouchTheme.gold)

            VStack(spacing: 10) {
                ForEach(viewModel.players) { player in
                    HStack {
                        Text(player.role.emoji)
                        Text(player.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(player.role.displayName)
                            .foregroundStyle(.white.opacity(0.6))
                        if !player.isAlive {
                            Text("OUT")
                                .font(.caption.bold())
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(player.isAlive ? 0.08 : 0.04))
                    }
                }
            }
        }
    }

    private var aliveRosterContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Still in the game")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.5))

            FlowLayout(spacing: 8) {
                ForEach(viewModel.alivePlayers) { player in
                    Text(player.name)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(.white.opacity(0.1))
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action button

    @ViewBuilder
    private var pinnedActionButton: some View {
        PinnedActionBar {
            switch viewModel.phase {
            case .roleReveal:
                if viewModel.showingRole {
                    Button("Got it — Hide") {
                        viewModel.confirmRoleSeen()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
                } else {
                    Button("Show My Role") {
                        viewModel.revealRoleForCurrentPlayer()
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
                }

            case .nightIntro:
                Button("Begin Night") {
                    viewModel.beginNight()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            case .nightMafia:
                confirmNightButton(enabled: viewModel.nightKillTargetID != nil) {
                    viewModel.confirmNightKill()
                }

            case .nightNurse:
                confirmNightButton(enabled: viewModel.nightSaveTargetID != nil) {
                    viewModel.confirmNightSave()
                }

            case .nightPolice:
                confirmNightButton(enabled: viewModel.nightPoliceTargetID != nil) {
                    viewModel.confirmPoliceCheck()
                }

            case .nightPoliceResult:
                Button("Continue to Dawn") {
                    viewModel.finishPoliceResult()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            case .dawn:
                Button("Start Discussion") {
                    viewModel.continueFromDawn()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            case .dayDiscussion:
                Button("Begin Voting") {
                    viewModel.continueFromDiscussion()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            case .voteModeChoice:
                EmptyView()

            case .dayVoteCollect, .dayRevote, .dayFinalVote:
                if let selectedPlayerID {
                    Button(voteButtonTitle) {
                        if viewModel.voteMode == .godOverride {
                            viewModel.castGodVote(targetID: selectedPlayerID)
                        } else {
                            viewModel.submitCurrentVote(targetID: selectedPlayerID)
                        }
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
                } else {
                    disabledActionPlaceholder("Select a player")
                }

            case .dayDefense:
                Button("Open Final Vote") {
                    viewModel.continueFromDefense()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            case .eliminationReveal:
                Button("Continue") {
                    viewModel.confirmElimination()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            case .gameOver:
                Button("Back to Home") {
                    viewModel.resetToSetup()
                    onExitToHome()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private var votePhaseLabel: String {
        switch viewModel.phase {
        case .dayVoteCollect: return "First Vote"
        case .dayRevote: return "Revote"
        case .dayFinalVote: return "Final Vote"
        default: return "Vote"
        }
    }

    private var voteButtonTitle: String {
        switch viewModel.phase {
        case .dayVoteCollect:
            return viewModel.voteMode == .godOverride ? "Accuse This Player" : "Submit Vote"
        case .dayRevote:
            return "Submit Revote"
        case .dayFinalVote:
            return viewModel.voteMode == .godOverride ? "Eliminate This Player" : "Submit Final Vote"
        default:
            return "Submit Vote"
        }
    }

    private func confirmNightButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if enabled {
                Button("Confirm Choice", action: action)
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
            } else {
                disabledActionPlaceholder("Select a player")
            }
        }
    }

    private func disabledActionPlaceholder(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .foregroundStyle(.white.opacity(0.35))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
    }

    private func playerPickerGrid(
        players: [MafiaPlayer],
        selection: Binding<UUID?>,
        onSelect: @escaping (UUID) -> Void
    ) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(players) { player in
                Button {
                    selection.wrappedValue = player.id
                    onSelect(player.id)
                    Haptics.impact()
                } label: {
                    VStack(spacing: 6) {
                        Text(player.name)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selection.wrappedValue == player.id ? AnyShapeStyle(CouchTheme.mafiaAccentGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(selection.wrappedValue == player.id ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                            }
                    }
                }
            }
        }
    }

    private func voteModeRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44)
                .foregroundStyle(CouchTheme.gold)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
        }
    }

    private func progressPill(current: Int, total: Int, label: String) -> some View {
        Text("\(label) \(current) of \(total)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.08)))
    }
}

// MARK: - Shared components

private struct ModeratorBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
            .padding(.bottom, 8)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        MafiaGameView(viewModel: MafiaGameViewModel()) {}
    }
}
