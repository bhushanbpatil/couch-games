//
//  CouchGameCatalog.swift
//  Couch Games
//

import Foundation

enum ConnectedGameKind: String, Codable, CaseIterable, Identifiable {
    case mafia
    case resistance
    case chameleon
    case bluffBarrel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mafia: return GameDisplayNames.villageTraitors
        case .resistance: return GameDisplayNames.secretMissions
        case .chameleon: return GameDisplayNames.wordSpy
        case .bluffBarrel: return GameDisplayNames.bluffAndBarrel
        }
    }

    var subtitle: String {
        switch self {
        case .mafia: return "Roles · Night · Vote on your phone."
        case .resistance: return "Missions · Teams · Secret roles."
        case .chameleon: return "Words · Clues · Spot the fake."
        case .bluffBarrel: return "Cards · Bluff · Pull the trigger."
        }
    }

    var iconAsset: String {
        switch self {
        case .mafia: return "GameMafia"
        case .resistance: return "GameResistance"
        case .chameleon: return "GameChameleon"
        case .bluffBarrel: return "GameBluffBarrel"
        }
    }

    var minPlayers: Int {
        switch self {
        case .mafia: return MafiaSetupConfig.minPlayers
        case .resistance: return ResistanceSetupConfig.minPlayers
        case .chameleon: return ChameleonSetupConfig.minPlayers
        case .bluffBarrel: return BluffBarrelSetupConfig.minPlayers
        }
    }

    var maxPlayers: Int {
        switch self {
        case .mafia: return MafiaSetupConfig.maxPlayers
        case .resistance: return ResistanceSetupConfig.maxPlayers
        case .chameleon: return ChameleonSetupConfig.maxPlayers
        case .bluffBarrel: return BluffBarrelSetupConfig.maxPlayers
        }
    }
}

struct PassAndPlayGame: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let iconAsset: String

    static let all: [PassAndPlayGame] = [
        PassAndPlayGame(id: "headsUp", title: GameDisplayNames.foreheadGuess, subtitle: "Forehead · Act · Volume to score.", iconAsset: "GameHeadsUp"),
        PassAndPlayGame(id: "timerGuess", title: "Timer Guess", subtitle: "Memorize · Count · Stop. Closest wins.", iconAsset: "GameTimerGuess"),
        PassAndPlayGame(id: "mafia", title: GameDisplayNames.villageTraitors, subtitle: "Roles · Night · Vote. Find the traitors.", iconAsset: "GameMafia"),
        PassAndPlayGame(id: "resistance", title: GameDisplayNames.secretMissions, subtitle: "Missions · Teams · Sabotage. Trust no one.", iconAsset: "GameResistance"),
        PassAndPlayGame(id: "chameleon", title: GameDisplayNames.wordSpy, subtitle: "Words · Clues · Spot the fake.", iconAsset: "GameChameleon"),
        PassAndPlayGame(id: "fakeArtist", title: GameDisplayNames.sketchImpostor, subtitle: "Draw · Colors · Spot the fake.", iconAsset: "GameFakeArtist"),
        PassAndPlayGame(id: "bluffBarrel", title: GameDisplayNames.bluffAndBarrel, subtitle: "Cards · Bluff · Pull the trigger.", iconAsset: "GameBluffBarrel")
    ]
}
