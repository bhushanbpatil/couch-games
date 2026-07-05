//
//  Scoring.swift
//  Couch Games
//

import Foundation

enum Scoring {
    static let perfectThreshold: TimeInterval = 0.05
    static let perfectPoints = 200
    static let basePoints = 100.0
    static let decayRate = 8.0

    static func points(target: TimeInterval, guess: TimeInterval) -> Int {
        let error = abs(guess - target)
        return points(forError: error)
    }

    static func points(forError error: TimeInterval) -> Int {
        guard error.isFinite, error >= 0 else { return 0 }
        if error < perfectThreshold {
            return perfectPoints
        }
        let raw = basePoints * exp(-decayRate * error)
        return max(0, Int(raw.rounded()))
    }

    static func formatSeconds(_ value: TimeInterval) -> String {
        String(format: "%.2f s", value)
    }

    static func formatTimeValue(_ value: TimeInterval) -> String {
        String(format: "%.2f", value)
    }
}
