//
//  ResistanceGameView.swift
//  Couch Games
//

import SwiftUI

struct ResistanceGameView: View {
    @Bindable var viewModel: ResistanceGameViewModel
    var onExitToHome: () -> Void

    @State private var showLeaveConfirmation = false
    @State private var assassinationSelection: UUID?

    var body: some View {
        ZStack {
            CouchTheme.resistanceGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewModel.phase != .roleReveal && viewModel.phase != .gameOver {
                            scoreboard
                        }

                        ResistanceModeratorBanner(text: viewModel.moderatorScript)
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
            assassinationSelection = nil
        }
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack {
                    scoreColumn(title: "Resistance", value: viewModel.resistanceWins, color: CouchTheme.cyan)
                    Text("–")
                        .font(.title.bold())
                        .foregroundStyle(.white.opacity(0.35))
                    scoreColumn(title: "Spies", value: viewModel.spyWins, color: Color.red.opacity(0.85))
                }

                if viewModel.consecutiveRejections > 0 {
                    Text("\(viewModel.consecutiveRejections) rejection\(viewModel.consecutiveRejections == 1 ? "" : "s") in a row")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange.opacity(0.9))
                }
            }
        }
    }

    private func scoreColumn(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.55))
            Text("\(value)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text("wins")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Phase content

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .roleReveal:
            roleRevealContent
        case .missionIntro:
            missionIntroContent
        case .teamPick:
            teamPickContent
        case .voteModeChoice:
            voteModeContent
        case .teamVoteCollect:
            teamVoteCollectContent
        case .teamVoteGod:
            teamVoteGodContent
        case .teamVoteResult:
            teamVoteResultContent
        case .missionPlay:
            missionPlayContent
        case .missionResult:
            missionResultContent
        case .assassination:
            assassinationContent
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

                        Text(player.role.emoji)
                            .font(.system(size: 72))

                        Text(player.role.displayName)
                            .font(.largeTitle.bold())
                            .foregroundStyle(player.role.isEvil ? Color.red.opacity(0.9) : CouchTheme.cyan)

                        Text(player.role.instruction)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)

                        if let intel = viewModel.roleRevealIntel(for: player) {
                            VStack(spacing: 8) {
                                Text(intel.title)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.55))

                                ForEach(intel.names, id: \.self) { name in
                                    Text(name)
                                        .font(.headline)
                                        .foregroundStyle(player.role.isEvil ? Color.red.opacity(0.85) : CouchTheme.cyan)
                                }

                                if let footnote = intel.footnote {
                                    Text(footnote)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 4)
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

                    Text("Tap when ready — only they should look.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
            }

            progressPill(current: viewModel.revealIndex + 1, total: viewModel.players.count)
        }
    }

    private var missionIntroContent: some View {
        VStack(spacing: 20) {
            if let leader = viewModel.leader {
                VStack(spacing: 8) {
                    Text("Mission Leader")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    PlayerBadge(name: leader.name)
                }
            }

            GlassCard {
                VStack(spacing: 10) {
                    Text("Mission \(viewModel.missionNumber)")
                        .font(.title.bold())
                    Text("Team size: \(viewModel.currentTeamSize)")
                        .font(.headline)
                        .foregroundStyle(CouchTheme.cyan)
                    if viewModel.failsRequired > 1 {
                        Text("\(viewModel.failsRequired) Fail cards needed to sabotage")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    private var teamPickContent: some View {
        VStack(spacing: 16) {
            Text("\(viewModel.proposedTeamIDs.count) / \(viewModel.currentTeamSize) selected")
                .font(.headline)
                .foregroundStyle(CouchTheme.cyan)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.players) { player in
                    Button {
                        viewModel.toggleTeamMember(player.id)
                        Haptics.impact()
                    } label: {
                        Text(player.name)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        viewModel.proposedTeamIDs.contains(player.id)
                                            ? AnyShapeStyle(CouchTheme.resistanceAccentGradient)
                                            : AnyShapeStyle(Color.white.opacity(0.08))
                                    )
                            }
                    }
                }
            }
        }
    }

    private var voteModeContent: some View {
        VStack(spacing: 16) {
            voteModeRow(
                icon: "iphone.and.arrow.forward",
                title: "Pass the Phone",
                subtitle: "Each player votes Approve or Reject privately"
            ) {
                viewModel.chooseVoteMode(.passPhone)
            }

            voteModeRow(
                icon: "person.fill.checkmark",
                title: "Moderator Override",
                subtitle: "God taps the group's decision — no passing"
            ) {
                viewModel.chooseVoteMode(.godOverride)
            }
        }
    }

    private var teamVoteCollectContent: some View {
        VStack(spacing: 20) {
            if let voter = viewModel.currentVoter {
                VStack(spacing: 8) {
                    PlayerBadge(name: voter.name)
                    Text("Only you should look.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            proposedTeamList

            HStack(spacing: 12) {
                voteChoiceButton(title: "Approve", icon: "hand.thumbsup.fill", color: Color.green) {
                    viewModel.submitTeamVote(.approve)
                }
                voteChoiceButton(title: "Reject", icon: "hand.thumbsdown.fill", color: Color.red.opacity(0.85)) {
                    viewModel.submitTeamVote(.reject)
                }
            }
        }
    }

    private var teamVoteGodContent: some View {
        VStack(spacing: 20) {
            proposedTeamList

            HStack(spacing: 12) {
                voteChoiceButton(title: "Approve Team", icon: "hand.thumbsup.fill", color: Color.green) {
                    viewModel.submitGodTeamVote(approved: true)
                }
                voteChoiceButton(title: "Reject Team", icon: "hand.thumbsdown.fill", color: Color.red.opacity(0.85)) {
                    viewModel.submitGodTeamVote(approved: false)
                }
            }
        }
    }

    private var teamVoteResultContent: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.lastTeamApproved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(viewModel.lastTeamApproved ? Color.green : Color.red.opacity(0.85))

                    Text(viewModel.lastTeamApproved ? "Team Approved" : "Team Rejected")
                        .font(.title2.bold())

                    HStack(spacing: 24) {
                        Label("\(viewModel.lastApproveCount)", systemImage: "hand.thumbsup.fill")
                            .foregroundStyle(Color.green)
                        Label("\(viewModel.lastRejectCount)", systemImage: "hand.thumbsdown.fill")
                            .foregroundStyle(Color.red.opacity(0.85))
                    }
                    .font(.headline)
                }
            }

            if !viewModel.lastTeamApproved && viewModel.consecutiveRejections >= ResistanceMissionRules.maxRejections - 1 {
                Text("One more rejection and the Resistance wins!")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var missionPlayContent: some View {
        VStack(spacing: 20) {
            if let player = viewModel.currentMissionPlayer {
                VStack(spacing: 8) {
                    Text("Mission Team")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    PlayerBadge(name: player.name)
                    Text("Only \(player.name) should look.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }

                if player.role.isEvil {
                    Text("Play Success or Fail")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))

                    HStack(spacing: 12) {
                        missionCardButton(title: "Success", color: Color.green) {
                            viewModel.playMissionCard(.success)
                        }
                        missionCardButton(title: "Fail", color: Color.red.opacity(0.85)) {
                            viewModel.playMissionCard(.fail)
                        }
                    }
                } else {
                    Text("You must play Success")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))

                    missionCardButton(title: "Success", color: Color.green) {
                        viewModel.playMissionCard(.success)
                    }
                }
            }
        }
    }

    private var missionResultContent: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 12) {
                    Text(viewModel.lastMissionSucceeded ? "✅" : "💥")
                        .font(.system(size: 56))

                    Text(viewModel.lastMissionSucceeded ? "Mission Succeeded" : "Mission Sabotaged")
                        .font(.title2.bold())
                        .foregroundStyle(viewModel.lastMissionSucceeded ? Color.green : Color.red.opacity(0.85))

                    Text("\(viewModel.lastMissionFailCount) Fail card\(viewModel.lastMissionFailCount == 1 ? "" : "s") played")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))

                    if viewModel.failsRequired > 1 {
                        Text("Needed \(viewModel.failsRequired) to sabotage this mission")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
    }

    private var assassinationContent: some View {
        VStack(spacing: 20) {
            if let assassin = viewModel.assassinPlayer {
                VStack(spacing: 8) {
                    Text("🗡️ Assassin")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    PlayerBadge(name: assassin.name)
                }
            }

            Text("Who is Merlin?")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.players) { player in
                    Button {
                        assassinationSelection = player.id
                        Haptics.impact()
                    } label: {
                        Text(player.name)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        assassinationSelection == player.id
                                            ? AnyShapeStyle(CouchTheme.mafiaAccentGradient)
                                            : AnyShapeStyle(Color.white.opacity(0.08))
                                    )
                            }
                    }
                }
            }
        }
    }

    private var gameOverContent: some View {
        VStack(spacing: 24) {
            Text(viewModel.winner == .resistance ? "🛡️" : "🕵️")
                .font(.system(size: 72))

            if viewModel.spiesWinViaAssassination {
                Text("Spies Win!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.red.opacity(0.9))
                if let target = viewModel.assassinationTarget {
                    Text("\(target.name) was Merlin.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text(viewModel.winner == .resistance ? "Good Team Wins!" : "Spies Win!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(viewModel.winner == .resistance ? CouchTheme.cyan : Color.red.opacity(0.9))
            }

            VStack(spacing: 10) {
                ForEach(viewModel.players) { player in
                    HStack {
                        Text(player.role.emoji)
                        Text(player.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(player.role.displayName)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.08))
                    }
                }
            }
        }
    }

    private var proposedTeamList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Proposed team")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))

            FlowLayout(spacing: 8) {
                ForEach(viewModel.proposedTeam) { player in
                    Text(player.name)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.1)))
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
                    Button("Got it — Hide") { viewModel.confirmRoleSeen() }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))
                } else {
                    Button("Show My Role") { viewModel.revealRoleForCurrentPlayer() }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))
                }

            case .missionIntro:
                Button("Pick Team") { viewModel.continueFromMissionIntro() }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))

            case .teamPick:
                if viewModel.proposedTeamIDs.count == viewModel.currentTeamSize {
                    Button("Propose Team") { viewModel.confirmTeamPick() }
                        .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))
                } else {
                    disabledPlaceholder("Select \(viewModel.currentTeamSize) players")
                }

            case .voteModeChoice, .teamVoteCollect, .teamVoteGod:
                EmptyView()

            case .teamVoteResult:
                Button(viewModel.lastTeamApproved ? "Play Mission Cards" : "Next Leader") {
                    viewModel.continueFromTeamVoteResult()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))

            case .missionPlay:
                EmptyView()

            case .missionResult:
                Button(missionResultButtonTitle) { viewModel.continueFromMissionResult() }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))

            case .assassination:
                if let assassinationSelection {
                    Button("Confirm Assassination") {
                        viewModel.confirmAssassination(targetID: assassinationSelection)
                    }
                    .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.mafiaAccentGradient))
                } else {
                    disabledPlaceholder("Select a player")
                }

            case .gameOver:
                Button("Back to Home") {
                    viewModel.resetToSetup()
                    onExitToHome()
                }
                .buttonStyle(CouchPrimaryButton(gradient: CouchTheme.resistanceAccentGradient))

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private var missionResultButtonTitle: String {
        if viewModel.gameMode == .avalon,
           viewModel.resistanceWins >= ResistanceMissionRules.winsNeeded,
           viewModel.spyWins < ResistanceMissionRules.winsNeeded {
            return "Assassination"
        }
        return "Next Mission"
    }

    private func voteModeRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44)
                    .foregroundStyle(CouchTheme.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
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
            }
        }
    }

    private func voteChoiceButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.25))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.6), lineWidth: 1.5)
                    }
            }
        }
    }

    private func missionCardButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color.opacity(0.3))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(color.opacity(0.65), lineWidth: 1.5)
                        }
                }
        }
    }

    private func disabledPlaceholder(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .foregroundStyle(.white.opacity(0.35))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.06))
            }
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

// MARK: - Shared

private struct ResistanceModeratorBanner: View {
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
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
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
        ResistanceGameView(viewModel: ResistanceGameViewModel()) {}
    }
}
