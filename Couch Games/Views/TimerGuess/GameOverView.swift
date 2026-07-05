//
//  GameOverView.swift
//  Couch Games
//

import SwiftUI

struct GameOverContent: View {
    @Bindable var viewModel: TimerGuessViewModel

    private var winner: Player? {
        viewModel.leaderboard.first
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.title.bold())

            if let winner {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(CouchTheme.gold)
                    Text(winner.name)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    Text("\(winner.totalScore) points")
                        .font(.title3.bold())
                        .monospacedDigit()
                        .foregroundStyle(CouchTheme.cyan)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(CouchTheme.gold.opacity(0.5), lineWidth: 1.5)
                        }
                }
            }

            let players = viewModel.leaderboard
            if !players.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Final Standings")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundStyle(.white.opacity(0.45))
                                .frame(width: 28, alignment: .leading)
                            Text(player.name)
                            Spacer()
                            Text("\(player.totalScore)")
                                .monospacedDigit()
                                .fontWeight(.bold)
                                .foregroundStyle(index == 0 ? CouchTheme.gold : .white)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .onAppear { Haptics.success() }
    }
}

#Preview {
    ZStack {
        GameScreenBackground()
        GameOverContent(viewModel: {
            let vm = TimerGuessViewModel()
            vm.startGame(config: vm.makeDefaultConfig(playerCount: 2, roundCount: 1))
            return vm
        }())
        .padding()
    }
}
