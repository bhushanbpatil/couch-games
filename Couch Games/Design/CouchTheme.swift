//
//  CouchTheme.swift
//  Couch Games
//

import SwiftUI

enum CouchTheme {
    static let deepIndigo = Color(red: 0.12, green: 0.11, blue: 0.28)
    static let violet = Color(red: 0.45, green: 0.28, blue: 0.95)
    static let magenta = Color(red: 0.92, green: 0.32, blue: 0.58)
    static let cyan = Color(red: 0.22, green: 0.82, blue: 0.95)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.22)

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                deepIndigo,
                Color(red: 0.18, green: 0.14, blue: 0.38),
                Color(red: 0.10, green: 0.16, blue: 0.32)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [violet, magenta],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var stopGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.28, blue: 0.38), Color(red: 0.85, green: 0.18, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var mafiaGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.06, blue: 0.14),
                Color(red: 0.22, green: 0.08, blue: 0.18),
                Color(red: 0.12, green: 0.10, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var mafiaAccentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.75, green: 0.12, blue: 0.22), Color(red: 0.45, green: 0.08, blue: 0.35)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var resistanceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.10, blue: 0.18),
                Color(red: 0.10, green: 0.18, blue: 0.28),
                Color(red: 0.08, green: 0.14, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var resistanceAccentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.62, blue: 0.82), Color(red: 0.28, green: 0.42, blue: 0.88)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var fakeArtistGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.10, blue: 0.20),
                Color(red: 0.24, green: 0.14, blue: 0.22),
                Color(red: 0.18, green: 0.16, blue: 0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var fakeArtistAccentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.55, blue: 0.28), Color(red: 0.88, green: 0.32, blue: 0.52)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func accuracyStyle(for error: TimeInterval) -> AccuracyStyle {
        if error < Scoring.perfectThreshold {
            return AccuracyStyle(
                label: "PERFECT",
                gradient: LinearGradient(colors: [gold, Color(red: 0.4, green: 0.95, blue: 0.55)], startPoint: .leading, endPoint: .trailing),
                glow: gold.opacity(0.45)
            )
        }
        if error < 0.15 {
            return AccuracyStyle(
                label: "ON FIRE",
                gradient: LinearGradient(colors: [Color(red: 0.35, green: 0.95, blue: 0.55), cyan], startPoint: .leading, endPoint: .trailing),
                glow: Color.green.opacity(0.35)
            )
        }
        if error < 0.35 {
            return AccuracyStyle(
                label: "SOLID",
                gradient: LinearGradient(colors: [cyan, violet], startPoint: .leading, endPoint: .trailing),
                glow: cyan.opacity(0.35)
            )
        }
        if error < 0.6 {
            return AccuracyStyle(
                label: "CLOSE",
                gradient: LinearGradient(colors: [Color.orange, magenta], startPoint: .leading, endPoint: .trailing),
                glow: Color.orange.opacity(0.3)
            )
        }
        return AccuracyStyle(
            label: "OFF MARK",
            gradient: LinearGradient(colors: [Color(red: 0.55, green: 0.45, blue: 0.75), Color(red: 0.45, green: 0.35, blue: 0.6)], startPoint: .leading, endPoint: .trailing),
            glow: Color.purple.opacity(0.25)
        )
    }

    struct AccuracyStyle {
        let label: String
        let gradient: LinearGradient
        let glow: Color
    }
}
