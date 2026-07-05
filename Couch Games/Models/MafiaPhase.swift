//
//  MafiaPhase.swift
//  Couch Games
//

import Foundation

enum MafiaPhase: Equatable {
    case setup
    case roleReveal
    case nightIntro
    case nightMafia
    case nightNurse
    case nightPolice
    case nightPoliceResult
    case dawn
    case dayDiscussion
    case voteModeChoice
    case dayVoteCollect
    case dayDefense
    case dayRevote
    case dayFinalVote
    case eliminationReveal
    case gameOver
}

enum MafiaVoteMode: Equatable {
    case passPhone
    case godOverride
}

enum MafiaWinner: Equatable {
    case villagers
    case mafia
}
