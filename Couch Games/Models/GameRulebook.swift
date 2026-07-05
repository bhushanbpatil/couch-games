//
//  GameRulebook.swift
//  Couch Games
//

import Foundation

enum CouchGameRulebook: String, Identifiable, CaseIterable {
    case timerGuess
    case mafia
    case resistanceClassic
    case resistanceAvalon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timerGuess: return "Timer Guess"
        case .mafia: return "Mafia"
        case .resistanceClassic: return "Resistance — Classic"
        case .resistanceAvalon: return "Resistance — Avalon"
        }
    }

    var sections: [(heading: String, lines: [String])] {
        switch self {
        case .timerGuess:
            return [
                ("Goal", [
                    "Stop the timer as close as you can to the target time."
                ]),
                ("How a round works", [
                    "Everyone sees the same target time.",
                    "Tap Ready, count in your head, then tap Stop.",
                    "Closest stop wins the round."
                ]),
                ("Scoring", [
                    "Perfect stop (within 0.05s) = 200 points.",
                    "Otherwise, closer stops earn more points.",
                    "Highest total after all rounds wins."
                ])
            ]

        case .mafia:
            return [
                ("Goal", [
                    "Town wins by voting out all Mafia.",
                    "Mafia wins when they equal or outnumber everyone else."
                ]),
                ("Setup", [
                    "Pick players and how many Mafia, Police, and Nurses.",
                    "Everyone else is a Villager.",
                    "Pass the phone — each player sees their role alone."
                ]),
                ("Night", [
                    "Everyone closes their eyes.",
                    "Mafia picks one person to eliminate.",
                    "Nurse picks someone to save (same person = saved).",
                    "Police picks someone to check (moderator nods yes/no)."
                ]),
                ("Day", [
                    "Discuss, then vote someone out.",
                    "Pass the phone to vote privately, or let the moderator tap the result.",
                    "Accused player gets to defend; then final vote."
                ])
            ]

        case .resistanceClassic:
            return [
                ("Goal", [
                    "Good team: win 3 missions.",
                    "Spy team: sabotage 3 missions."
                ]),
                ("Setup", [
                    "Most players are Resistance; a few are Spies.",
                    "Spies know each other. Resistance does not know who is who.",
                    "Pass the phone for private role reveals."
                ]),
                ("Each mission", [
                    "Mission Leader picks a team (size shown on screen).",
                    "Everyone votes Approve or Reject the team.",
                    "If approved, team members secretly play Success or Fail.",
                    "One Fail card fails the mission (two Fails on Mission 4 with 7+ players)."
                ]),
                ("Other rules", [
                    "Leader rotates after each mission or rejected team.",
                    "5 rejected teams in a row = good team wins."
                ])
            ]

        case .resistanceAvalon:
            return [
                ("Same as Classic, plus special roles", [
                    "Use Avalon mode for Merlin, Percival, Assassin, and more.",
                    "Mission rules and voting are the same as Classic."
                ]),
                ("Good roles", [
                    "Merlin — knows most evil players (not Mordred). Stay hidden.",
                    "Percival — sees Merlin and Morgana, but not which is which.",
                    "Loyal Servant — regular good player."
                ]),
                ("Evil roles", [
                    "Assassin — if good wins 3 missions, guesses Merlin to steal the win.",
                    "Morgana — looks like Merlin to Percival.",
                    "Mordred — hidden from Merlin.",
                    "Oberon (10 players) — doesn't know evil, evil doesn't know Oberon."
                ]),
                ("Winning", [
                    "Evil can win with 3 failed missions.",
                    "Good can win with 3 successful missions — then Assassin gets one guess.",
                    "Correct Merlin guess = evil wins anyway."
                ])
            ]
        }
    }

    static func resistanceBooks(for mode: ResistanceGameMode) -> [CouchGameRulebook] {
        switch mode {
        case .classic: return [.resistanceClassic]
        case .avalon: return [.resistanceClassic, .resistanceAvalon]
        }
    }
}
