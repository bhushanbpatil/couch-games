//
//  AvalonRoleRules.swift
//  Couch Games
//

import Foundation

enum AvalonRoleRules {
    static func roles(for playerCount: Int) -> [ResistanceRole] {
        switch playerCount {
        case 5:
            return [.merlin, .percival, .loyalServant, .assassin, .minion]
        case 6:
            return [.merlin, .percival, .loyalServant, .assassin, .minion, .minion]
        case 7:
            return [.merlin, .percival, .loyalServant, .loyalServant, .assassin, .morgana, .minion]
        case 8:
            return [.merlin, .percival, .loyalServant, .loyalServant, .assassin, .morgana, .minion, .minion]
        case 9:
            return [.merlin, .percival, .loyalServant, .loyalServant, .loyalServant, .loyalServant, .assassin, .morgana, .mordred]
        default:
            return [.merlin, .percival, .loyalServant, .loyalServant, .loyalServant, .loyalServant, .assassin, .morgana, .mordred, .oberon]
        }
    }

    static func roleSummary(for playerCount: Int) -> String {
        let roles = roles(for: playerCount)
        var counts: [ResistanceRole: Int] = [:]
        for role in roles {
            counts[role, default: 0] += 1
        }
        return counts
            .sorted { $0.key.displayName < $1.key.displayName }
            .map { "\($0.key.displayName) ×\($0.value)" }
            .joined(separator: " · ")
    }
}

enum ResistanceRoleIntel {
    static func revealIntel(for player: ResistancePlayer, in players: [ResistancePlayer], percivalDecoyID: UUID?) -> RoleRevealIntel? {
        switch player.role {
        case .merlin:
            let evil = players.filter { $0.role.isEvil && $0.role != .mordred }.map(\.name)
            guard !evil.isEmpty else { return nil }
            return RoleRevealIntel(
                title: "Evil players you know",
                names: evil.sorted(),
                footnote: "Mordred is hidden from you."
            )

        case .percival:
            let merlin = players.first { $0.role == .merlin }?.name
            let morgana = players.first { $0.role == .morgana }?.name
            if let morgana, let merlin {
                return RoleRevealIntel(
                    title: "One of these is Merlin",
                    names: [merlin, morgana].shuffled(),
                    footnote: "You don't know which is which."
                )
            }
            if let merlin, let decoyID = percivalDecoyID,
               let decoy = players.first(where: { $0.id == decoyID })?.name {
                return RoleRevealIntel(
                    title: "One of these is Merlin",
                    names: [merlin, decoy].shuffled(),
                    footnote: "You don't know which is which."
                )
            }
            return nil

        case .spy, .minion, .assassin, .morgana, .mordred:
            let teammates = evilTeammates(for: player, in: players).map(\.name).sorted()
            guard !teammates.isEmpty else { return nil }
            return RoleRevealIntel(
                title: player.role == .spy ? "Your fellow Spies" : "Your evil teammates",
                names: teammates,
                footnote: player.role == .oberon ? nil : "Oberon is not shown."
            )

        case .oberon:
            return RoleRevealIntel(
                title: "You are alone",
                names: [],
                footnote: "Other evil players don't know you."
            )

        default:
            return nil
        }
    }

    static func evilTeammates(for player: ResistancePlayer, in players: [ResistancePlayer]) -> [ResistancePlayer] {
        guard player.role.isEvil, player.role != .oberon else { return [] }
        return players.filter { other in
            other.id != player.id && other.role.isEvil && other.role != .oberon
        }
    }
}
