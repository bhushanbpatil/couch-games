//
//  LeaderboardView.swift
//  Couch Games
//

import SwiftUI

struct LeaderboardView: View {
    let players: [Player]
    let turnHistory: [TurnResult]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GameScreenBackground()

            List {
                if players.isEmpty {
                    ContentUnavailableView(
                        "No scores yet",
                        systemImage: "list.number",
                        description: Text("Start a game to see the leaderboard.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section("Standings") {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            HStack {
                                Text(rankLabel(index))
                                    .font(.headline)
                                    .foregroundStyle(index == 0 ? CouchTheme.gold : .white.opacity(0.6))
                                    .frame(width: 36, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    if !player.roundScores.isEmpty {
                                        Text(player.roundScores.map(String.init).joined(separator: " · "))
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                Spacer()
                                Text("\(player.totalScore)")
                                    .font(.title2.bold())
                                    .monospacedDigit()
                                    .foregroundStyle(CouchTheme.cyan)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.white.opacity(0.08))
                        }
                    }

                    if !turnHistory.isEmpty {
                        Section("Recent turns") {
                            ForEach(turnHistory.reversed()) { turn in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(turn.playerName) · Round \(turn.roundIndex + 1)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    HStack(spacing: 16) {
                                        miniTime(label: "Target", value: turn.target)
                                        miniTime(label: "Got", value: turn.guess, highlight: true)
                                        Text("+\(turn.points)")
                                            .font(.headline.bold())
                                            .foregroundStyle(CouchTheme.gold)
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.06))
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .foregroundStyle(.white)
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }

    private func miniTime(label: String, value: TimeInterval, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
            Text(Scoring.formatTimeValue(value))
                .font(.system(size: highlight ? 22 : 17, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(highlight ? .white : .white.opacity(0.75))
        }
    }

    private func rankLabel(_ index: Int) -> String {
        switch index {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        default: return "\(index + 1)th"
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView(
            players: [
                Player(name: "Alex", totalScore: 245, roundScores: [200, 45]),
                Player(name: "Sam", totalScore: 120, roundScores: [67, 53])
            ],
            turnHistory: []
        )
    }
}
