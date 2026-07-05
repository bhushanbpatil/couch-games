//
//  ResistanceRole.swift
//  Couch Games
//

import Foundation

enum ResistanceRole: String, CaseIterable, Codable {
    case resistance
    case spy
    case loyalServant
    case merlin
    case percival
    case minion
    case assassin
    case morgana
    case mordred
    case oberon

    var isEvil: Bool {
        switch self {
        case .resistance, .loyalServant, .merlin, .percival:
            return false
        default:
            return true
        }
    }

    var displayName: String {
        switch self {
        case .resistance: return GameDisplayNames.loyalAgent
        case .spy: return "Spy"
        case .loyalServant: return "Loyal Agent"
        case .merlin: return "Oracle"
        case .percival: return "Guardian"
        case .minion: return "Spy Ally"
        case .assassin: return "Hunter"
        case .morgana: return "Trickster"
        case .mordred: return "Hidden Spy"
        case .oberon: return "Lone Wolf"
        }
    }

    var emoji: String {
        switch self {
        case .resistance, .loyalServant: return "🛡️"
        case .spy, .minion: return "🕵️"
        case .merlin: return "🧙"
        case .percival: return "⚔️"
        case .assassin: return "🗡️"
        case .morgana: return "🌙"
        case .mordred: return "👑"
        case .oberon: return "👤"
        }
    }

    var instruction: String {
        switch self {
        case .resistance:
            return "Complete 3 missions. You must play Success."
        case .spy:
            return "Sabotage 3 missions. You know the other Spies."
        case .loyalServant:
            return "Help the good team win 3 missions. You must play Success."
        case .merlin:
            return "You know who most of the evil players are. Stay hidden — the Hunter is hunting you."
        case .percival:
            return "You see two players — one is the Oracle. Protect the real Oracle."
        case .minion:
            return "Sabotage 3 missions. You know your evil teammates."
        case .assassin:
            return "Sabotage missions. If good wins 3 missions, you get one guess at the Oracle."
        case .morgana:
            return "You appear as the Oracle to the Guardian. Trick the good team."
        case .mordred:
            return "You are hidden from the Oracle. Coordinate with your team."
        case .oberon:
            return "You don't know your teammates and they don't know you."
        }
    }
}

enum ResistanceGameMode: String, CaseIterable, Identifiable {
    case classic
    case avalon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .avalon: return "Special Roles"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return "Agents vs Spies"
        case .avalon: return "Oracle, Guardian & the Hunter"
        }
    }
}

struct RoleRevealIntel: Equatable {
    var title: String
    var names: [String]
    var footnote: String?
}
