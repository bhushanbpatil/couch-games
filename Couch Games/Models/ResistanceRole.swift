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
        case .resistance: return "Resistance"
        case .spy: return "Spy"
        case .loyalServant: return "Loyal Servant"
        case .merlin: return "Merlin"
        case .percival: return "Percival"
        case .minion: return "Minion"
        case .assassin: return "Assassin"
        case .morgana: return "Morgana"
        case .mordred: return "Mordred"
        case .oberon: return "Oberon"
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
            return "You know who most of the evil players are. Stay hidden — the Assassin is hunting you."
        case .percival:
            return "You see two players — one is Merlin. Protect the real Merlin."
        case .minion:
            return "Sabotage 3 missions. You know your evil teammates."
        case .assassin:
            return "Sabotage missions. If good wins 3 missions, you get one guess at Merlin."
        case .morgana:
            return "You appear as Merlin to Percival. Trick the good team."
        case .mordred:
            return "You are hidden from Merlin. Coordinate with your team."
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
        case .avalon: return "Avalon"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return "Resistance vs Spies"
        case .avalon: return "Merlin, Percival & the Assassin"
        }
    }
}

struct RoleRevealIntel: Equatable {
    var title: String
    var names: [String]
    var footnote: String?
}
