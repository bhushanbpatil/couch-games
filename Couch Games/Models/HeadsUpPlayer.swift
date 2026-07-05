//
//  HeadsUpPlayer.swift
//  Couch Games
//

import Foundation

struct HeadsUpSetupConfig: Equatable {
    static let roundDurationOptions = [30, 45, 60, 90]

    var deckIDs: Set<String>
    var roundDuration: Int = 60
    var controlMode: HeadsUpControlMode = .volumeAndTap
    var playerName: String = ""

    var validationError: String? {
        guard !deckIDs.isEmpty else {
            return "Pick at least one deck."
        }
        guard Self.roundDurationOptions.contains(roundDuration) else {
            return "Pick a round length."
        }
        return nil
    }
}
