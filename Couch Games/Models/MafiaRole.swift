//
//  MafiaRole.swift
//  Couch Games
//

import Foundation

enum MafiaRole: String, CaseIterable, Codable {
    case mafia
    case police
    case nurse
    case villager

    var displayName: String {
        switch self {
        case .mafia: return GameDisplayNames.traitor
        case .police: return "Police"
        case .nurse: return "Nurse"
        case .villager: return "Villager"
        }
    }

    var emoji: String {
        switch self {
        case .mafia: return "🕶️"
        case .police: return "👮"
        case .nurse: return "💉"
        case .villager: return "🏠"
        }
    }

    var instruction: String {
        switch self {
        case .mafia:
            return "Wake at night with the other Traitors. Silently choose someone to eliminate."
        case .police:
            return "Wake at night to investigate one player. The moderator will nod yes or no."
        case .nurse:
            return "Wake at night to pick one player to save from elimination."
        case .villager:
            return "Find the Traitors during the day. Vote them out before they outnumber the town."
        }
    }
}
