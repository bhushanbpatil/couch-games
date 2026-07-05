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
