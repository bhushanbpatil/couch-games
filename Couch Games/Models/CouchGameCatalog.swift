//
//  CouchGameCatalog.swift
//  Couch Games
//

import Foundation

enum ConnectedGameKind: String, Codable, CaseIterable, Identifiable {
    case mafia
    case resistance
    case chameleon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mafia: return "Mafia"
        case .resistance: return "Resistance"
        case .chameleon: return "Chameleon"
        }
    }

    var subtitle: String {
        switch self {
        case .mafia: return "Roles · Night · Vote on your phone."
        case .resistance: return "Missions · Teams · Secret roles."
        case .chameleon: return "Words · Clues · Spot the fake."
        }
    }

    var iconAsset: String {
        switch self {
        case .mafia: return "GameMafia"
        case .resistance: return "GameResistance"
        case .chameleon: return "GameChameleon"
        }
    }

    var minPlayers: Int {
        switch self {
        case .mafia: return MafiaSetupConfig.minPlayers
        case .resistance: return ResistanceSetupConfig.minPlayers
        case .chameleon: return ChameleonSetupConfig.minPlayers
        }
    }

    var maxPlayers: Int {
        switch self {
        case .mafia: return MafiaSetupConfig.maxPlayers
        case .resistance: return ResistanceSetupConfig.maxPlayers
        case .chameleon: return ChameleonSetupConfig.maxPlayers
        }
    }
}

struct PassAndPlayGame: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let iconAsset: String

    static let all: [PassAndPlayGame] = [
        PassAndPlayGame(id: "headsUp", title: "Heads Up", subtitle: "Forehead · Act · Volume to score.", iconAsset: "GameHeadsUp"),
        PassAndPlayGame(id: "timerGuess", title: "Timer Guess", subtitle: "Memorize · Count · Stop. Closest wins.", iconAsset: "GameTimerGuess"),
        PassAndPlayGame(id: "mafia", title: "Mafia", subtitle: "Roles · Night · Vote. Find the Mafia.", iconAsset: "GameMafia"),
        PassAndPlayGame(id: "resistance", title: "Resistance", subtitle: "Missions · Teams · Sabotage. Trust no one.", iconAsset: "GameResistance"),
        PassAndPlayGame(id: "chameleon", title: "Chameleon", subtitle: "Words · Clues · Spot the fake.", iconAsset: "GameChameleon"),
        PassAndPlayGame(id: "fakeArtist", title: "Fake Artist", subtitle: "Draw · Colors · Spot the fake.", iconAsset: "GameFakeArtist")
    ]
}
