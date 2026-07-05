//
//  ResistanceMissionRules.swift
//  Couch Games
//

import Foundation

enum ResistanceMissionRules {
    static let winsNeeded = 3
    static let maxRejections = 5

    static func spyCount(for playerCount: Int) -> Int {
        switch playerCount {
        case 5, 6: return 2
        case 7, 8, 9: return 3
        default: return 4
        }
    }

    static func teamSize(playerCount: Int, mission: Int) -> Int {
        let index = min(max(mission - 1, 0), 4)
        switch playerCount {
        case 5: return [2, 3, 2, 3, 3][index]
        case 6: return [2, 3, 4, 3, 4][index]
        case 7: return [2, 3, 3, 4, 4][index]
        case 8: return [3, 4, 4, 5, 5][index]
        case 9: return [3, 4, 4, 5, 5][index]
        default: return [3, 4, 4, 5, 5][index]
        }
    }

    static func failsRequiredToSabotage(playerCount: Int, mission: Int) -> Int {
        playerCount >= 7 && mission == 4 ? 2 : 1
    }
}
