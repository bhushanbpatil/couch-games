//
//  HeadsUpPhase.swift
//  Couch Games
//

import Foundation

enum HeadsUpPhase: Equatable {
    case setup
    case ready
    case playing
    case roundSummary
}

enum HeadsUpControlMode: String, CaseIterable, Identifiable {
    case volumeAndTap
    case volume
    case tap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .volumeAndTap: return "Volume + Tap"
        case .volume: return "Volume Buttons"
        case .tap: return "Tap Only"
        }
    }

    var subtitle: String {
        switch self {
        case .volumeAndTap: return "Vol up/down or on-screen buttons"
        case .volume: return "Vol up = got it · Vol down = pass"
        case .tap: return "Use on-screen buttons"
        }
    }

    var usesTap: Bool {
        self == .tap || self == .volumeAndTap
    }

    var usesVolume: Bool {
        self == .volume || self == .volumeAndTap
    }
}

struct HeadsUpCardResult: Identifiable, Equatable {
    let id: UUID
    let word: String
    let wasCorrect: Bool

    init(id: UUID = UUID(), word: String, wasCorrect: Bool) {
        self.id = id
        self.word = word
        self.wasCorrect = wasCorrect
    }
}
