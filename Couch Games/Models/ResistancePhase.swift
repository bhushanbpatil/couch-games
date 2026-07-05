//
//  ResistancePhase.swift
//  Couch Games
//

import Foundation

enum ResistancePhase: Equatable {
    case setup
    case roleReveal
    case missionIntro
    case teamPick
    case voteModeChoice
    case teamVoteCollect
    case teamVoteGod
    case teamVoteResult
    case missionPlay
    case missionResult
    case assassination
    case gameOver
}

enum ResistanceVoteMode: Equatable {
    case passPhone
    case godOverride
}

enum ResistanceTeamVote: Equatable {
    case approve
    case reject
}

enum ResistanceMissionCard: Equatable {
    case success
    case fail
}

enum ResistanceWinner: Equatable {
    case resistance
    case spies
}
