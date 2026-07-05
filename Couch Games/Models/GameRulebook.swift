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
    case fakeArtist
    case chameleon
    case headsUp
    case bluffBarrel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timerGuess: return "Timer Guess"
        case .mafia: return GameDisplayNames.villageTraitors
        case .resistanceClassic: return "\(GameDisplayNames.secretMissions) — Classic"
        case .resistanceAvalon: return "\(GameDisplayNames.secretMissions) — Special Roles"
        case .fakeArtist: return GameDisplayNames.sketchImpostor
        case .chameleon: return GameDisplayNames.wordSpy
        case .headsUp: return GameDisplayNames.foreheadGuess
        case .bluffBarrel: return GameDisplayNames.bluffAndBarrel
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
                    "Town wins by voting out all Traitors.",
                    "Traitors win when they equal or outnumber everyone else."
                ]),
                ("Setup", [
                    "Pick players and how many Traitors, Police, and Nurses.",
                    "Everyone else is a Villager.",
                    "Pass the phone — each player sees their role alone."
                ]),
                ("Night", [
                    "Everyone closes their eyes.",
                    "Traitors pick one person to eliminate.",
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
                    "Most players are Agents; a few are Spies.",
                    "Spies know each other. Agents do not know who is who.",
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
                    "Use Special Roles mode for Oracle, Guardian, Hunter, and more.",
                    "Mission rules and voting are the same as Classic."
                ]),
                ("Good roles", [
                    "Oracle — knows most evil players (not the Hidden Spy). Stay hidden.",
                    "Guardian — sees the Oracle and Trickster, but not which is which.",
                    "Loyal Agent — regular good player."
                ]),
                ("Evil roles", [
                    "Hunter — if good wins 3 missions, guesses the Oracle to steal the win.",
                    "Trickster — looks like the Oracle to the Guardian.",
                    "Hidden Spy — hidden from the Oracle.",
                    "Lone Wolf (10 players) — doesn't know evil, evil doesn't know Lone Wolf."
                ]),
                ("Winning", [
                    "Evil can win with 3 failed missions.",
                    "Good can win with 3 successful missions — then the Hunter gets one guess.",
                    "Correct Oracle guess = evil wins anyway."
                ])
            ]

        case .fakeArtist:
            return [
                ("Goal", [
                    "Most players know the secret word. One Impostor does not.",
                    "Artists win by catching the Impostor. The Impostor wins by staying hidden — or guessing the word if caught."
                ]),
                ("Setup", [
                    "Each player gets a unique pencil color.",
                    "Pass the phone so everyone sees the word — except the Impostor, who sees \"?\"."
                ]),
                ("Drawing (2 rounds)", [
                    "In turn, each player adds one line to the shared drawing.",
                    "Your color shows who drew what.",
                    "Tap End Turn when you're finished. No letters or numbers."
                ]),
                ("Vote & guess", [
                    "Discuss the drawing, then vote for the Impostor.",
                    "If they're caught, they get one guess at the word.",
                    "Wrong accusation = Impostor wins."
                ])
            ]

        case .chameleon:
            return [
                ("Goal", [
                    "Everyone knows the secret word except one Word Spy.",
                    "Catch the Word Spy to win. The Word Spy wins by staying hidden — or guessing the word if caught."
                ]),
                ("Setup", [
                    "Pick players and how much the Word Spy knows.",
                    "Complete Blind — nothing. Category Only — topic, no words. Word Grid — classic 4×4 card.",
                    "Pass the phone for private reveals."
                ]),
                ("Discussion", [
                    "Take turns saying ONE word related to the secret.",
                    "Don't be too obvious — the Word Spy is listening.",
                    "In Complete Blind mode, the category stays hidden on screen during the round."
                ]),
                ("Vote & guess", [
                    "Discuss, then vote for the Word Spy.",
                    "If they're caught, they pick the secret word from the grid.",
                    "Wrong accusation = Word Spy wins."
                ])
            ]

        case .headsUp:
            return [
                ("Goal", [
                    "Guess as many cards as you can before time runs out.",
                    "Friends see the word on screen and act it out — you hold the phone on your forehead."
                ]),
                ("Setup", [
                    "Pick one or more decks and a round length.",
                    "Default controls: volume buttons plus on-screen Pass / Got It.",
                    "Optional: enter the guesser's name for the score screen."
                ]),
                ("Playing", [
                    "Hold the phone on your forehead with the screen facing your friends.",
                    "Volume up = got it · Volume down = pass.",
                    "On-screen buttons work too when Volume + Tap is selected."
                ]),
                ("Scoring", [
                    "Each correct guess and pass is tracked.",
                    "When the timer hits zero, see your score and pass the phone to the next player.",
                    "Tap Play Again for a fresh shuffled deck."
                ])
            ]

        case .bluffBarrel:
            return [
                ("Goal", [
                    "Be the last player standing.",
                    "Bluff about your cards — or call someone out when you think they're lying."
                ]),
                ("Setup", [
                    "2–4 players. Each gets 5 cards from a 20-card deck (Kings, Queens, Aces, and Jokers).",
                    "Each round picks a table rank — Kings, Queens, or Aces.",
                    "Jokers count as wild for any table rank."
                ]),
                ("Playing", [
                    "On your turn, play 1–3 cards face down and claim they match the table rank.",
                    "The next player can play cards too — or call Liar!",
                    "If Liar is called, the played cards are revealed."
                ]),
                ("Barrel", [
                    "If the play was a lie, the liar pulls the trigger.",
                    "If the call was wrong, the caller pulls the trigger.",
                    "Six chambers — odds get worse each safe pull. Hit = eliminated.",
                    "Survivors get a fresh deal; last player standing wins."
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
