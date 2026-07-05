//
//  FakeArtistPhase.swift
//  Couch Games
//

import Foundation

enum FakeArtistPhase: Equatable {
    case setup
    case roleReveal
    case drawHandoff
    case drawing
    case revealDrawing
    case voteModeChoice
    case voteCollect
    case voteGod
    case fakeGuess
    case gameOver
}

enum FakeArtistVoteMode: Equatable {
    case passPhone
    case godOverride
}

enum FakeArtistOutcome: Equatable {
    case artistsWin
    case fakeArtistUndetected
    case fakeArtistGuessedWord
}
