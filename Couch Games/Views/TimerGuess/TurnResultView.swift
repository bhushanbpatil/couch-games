//
//  TurnResultView.swift
//  Couch Games
//

import SwiftUI

struct TurnResultContent: View {
    let result: TurnResult
    var reveal: Bool

    private var accuracyStyle: CouchTheme.AccuracyStyle {
        CouchTheme.accuracyStyle(for: result.error)
    }

    private var isPerfect: Bool {
        result.points >= Scoring.perfectPoints
    }

    var body: some View {
        VStack(spacing: 14) {
            PlayerBadge(name: result.playerName)

            GlassCard {
                VStack(spacing: 16) {
                    BigTimeDisplay(
                        label: "Target",
                        seconds: result.target,
                        size: .companion,
                        accent: .white.opacity(0.75)
                    )

                    Rectangle()
                        .fill(.white.opacity(0.15))
                        .frame(height: 1)

                    BigTimeDisplay(
                        label: "You got",
                        seconds: result.guess,
                        size: .hero,
                        accent: .white
                    )
                }
            }

            PowerDeltaDisplay(error: result.error, style: accuracyStyle)
                .scaleEffect(reveal ? 1 : 0.92)
                .opacity(reveal ? 1 : 0)

            PointsBurst(points: result.points, isPerfect: isPerfect)
                .scaleEffect(reveal ? 1 : 0.85)
                .opacity(reveal ? 1 : 0)
        }
    }
}

#Preview {
    ZStack {
        GameScreenBackground()
        TurnResultContent(
            result: TurnResult(
                roundIndex: 0,
                playerID: UUID(),
                playerName: "Player 1",
                target: 4.27,
                guess: 10.47,
                error: 6.20,
                points: 0
            ),
            reveal: true
        )
        .padding()
    }
}
