//
//  BluffBarrelPlayer.swift
//  Couch Games
//

import Foundation

struct BluffBarrelPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var hand: [BluffBarrelCard]
    var isAlive: Bool
    var safeTriggerPulls: Int

    init(id: UUID = UUID(), name: String, hand: [BluffBarrelCard] = [], isAlive: Bool = true, safeTriggerPulls: Int = 0) {
        self.id = id
        self.name = name
        self.hand = hand
        self.isAlive = isAlive
        self.safeTriggerPulls = safeTriggerPulls
    }

    var rouletteChambersRemaining: Int {
        max(0, 6 - safeTriggerPulls)
    }
}
