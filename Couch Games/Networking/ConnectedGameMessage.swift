//
//  ConnectedGameMessage.swift
//  Couch Games
//

import Foundation

struct RoomPlayer: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isHost: Bool
    var isLocal: Bool

    init(id: UUID = UUID(), name: String, isHost: Bool = false, isLocal: Bool = false) {
        self.id = id
        self.name = name
        self.isHost = isHost
        self.isLocal = isLocal
    }
}

struct ConnectedGameStartPayload: Codable, Equatable {
    let game: ConnectedGameKind
    let players: [RoomPlayer]
    let hostPlayerID: UUID
}

struct ConnectedPhasePayload: Codable, Equatable {
    let title: String
    let script: String
    let phaseKey: String
}

struct ConnectedPrivateRolePayload: Codable, Equatable {
    let heading: String
    let lines: [String]
}

struct ConnectedChameleonRolePayload: Codable, Equatable {
    let isChameleon: Bool
    let category: String
    let secretWord: String?
    let gridWords: [String]
    let intelMode: ChameleonIntelMode
}

struct ConnectedChameleonVotePromptPayload: Codable, Equatable {
    let playerID: UUID
}

struct ConnectedVotePayload: Codable, Equatable {
    let voterID: UUID
    let targetID: UUID
}

struct ConnectedChameleonGuessPromptPayload: Codable, Equatable {
    let gridWords: [String]
    let category: String
}

struct ConnectedBluffBarrelHandPayload: Codable, Equatable {
    let cards: [BluffBarrelCard]
}

struct ConnectedBluffBarrelPlayerSnapshot: Codable, Equatable {
    let id: UUID
    let name: String
    let isAlive: Bool
    let safeTriggerPulls: Int
    let handCount: Int
}

struct ConnectedBluffBarrelPublicPayload: Codable, Equatable {
    let tableRank: BluffBarrelRank
    let phaseKey: String
    let activePlayerID: UUID?
    let lastPlayPlayerID: UUID?
    let lastPlayCount: Int
    let canCallLiar: Bool
    let mustPlay: Bool
    let revealedCards: [BluffBarrelCard]?
    let lied: Bool?
    let rouletteTargetID: UUID?
    let players: [ConnectedBluffBarrelPlayerSnapshot]
    let title: String
    let script: String
    let lastRouletteHit: Bool
    let winnerID: UUID?
}

struct ConnectedBluffBarrelActionPayload: Codable, Equatable {
    enum Action: String, Codable {
        case play
        case callLiar
        case pullTrigger
        case confirmRoundIntro
        case continueToRoulette
        case acknowledgeRouletteResult
    }

    let playerID: UUID
    let action: Action
    let cardIDs: [UUID]?
}

enum ConnectedMessage: Codable {
    case roster([RoomPlayer])
    case startGame(ConnectedGameStartPayload)
    case phase(ConnectedPhasePayload)
    case chameleonRole(ConnectedChameleonRolePayload)
    case privateRole(ConnectedPrivateRolePayload)
    case chameleonVotePrompt(ConnectedChameleonVotePromptPayload)
    case chameleonGuessPrompt(ConnectedChameleonGuessPromptPayload)
    case vote(ConnectedVotePayload)
    case bluffBarrelHand(ConnectedBluffBarrelHandPayload)
    case bluffBarrelPublic(ConnectedBluffBarrelPublicPayload)
    case bluffBarrelAction(ConnectedBluffBarrelActionPayload)
    case ack

    private enum CodingKeys: String, CodingKey { case type, payload }

    private enum MessageType: String, Codable {
        case roster, startGame, phase, chameleonRole, privateRole, chameleonVotePrompt, chameleonGuessPrompt, vote, bluffBarrelHand, bluffBarrelPublic, bluffBarrelAction, ack
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)
        switch type {
        case .roster:
            self = .roster(try container.decode([RoomPlayer].self, forKey: .payload))
        case .startGame:
            self = .startGame(try container.decode(ConnectedGameStartPayload.self, forKey: .payload))
        case .phase:
            self = .phase(try container.decode(ConnectedPhasePayload.self, forKey: .payload))
        case .chameleonRole:
            self = .chameleonRole(try container.decode(ConnectedChameleonRolePayload.self, forKey: .payload))
        case .privateRole:
            self = .privateRole(try container.decode(ConnectedPrivateRolePayload.self, forKey: .payload))
        case .chameleonVotePrompt:
            self = .chameleonVotePrompt(try container.decode(ConnectedChameleonVotePromptPayload.self, forKey: .payload))
        case .chameleonGuessPrompt:
            self = .chameleonGuessPrompt(try container.decode(ConnectedChameleonGuessPromptPayload.self, forKey: .payload))
        case .vote:
            self = .vote(try container.decode(ConnectedVotePayload.self, forKey: .payload))
        case .bluffBarrelHand:
            self = .bluffBarrelHand(try container.decode(ConnectedBluffBarrelHandPayload.self, forKey: .payload))
        case .bluffBarrelPublic:
            self = .bluffBarrelPublic(try container.decode(ConnectedBluffBarrelPublicPayload.self, forKey: .payload))
        case .bluffBarrelAction:
            self = .bluffBarrelAction(try container.decode(ConnectedBluffBarrelActionPayload.self, forKey: .payload))
        case .ack:
            self = .ack
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .roster(let players):
            try container.encode(MessageType.roster, forKey: .type)
            try container.encode(players, forKey: .payload)
        case .startGame(let payload):
            try container.encode(MessageType.startGame, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .phase(let payload):
            try container.encode(MessageType.phase, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .chameleonRole(let payload):
            try container.encode(MessageType.chameleonRole, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .privateRole(let payload):
            try container.encode(MessageType.privateRole, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .chameleonVotePrompt(let payload):
            try container.encode(MessageType.chameleonVotePrompt, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .chameleonGuessPrompt(let payload):
            try container.encode(MessageType.chameleonGuessPrompt, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .vote(let payload):
            try container.encode(MessageType.vote, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .bluffBarrelHand(let payload):
            try container.encode(MessageType.bluffBarrelHand, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .bluffBarrelPublic(let payload):
            try container.encode(MessageType.bluffBarrelPublic, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .bluffBarrelAction(let payload):
            try container.encode(MessageType.bluffBarrelAction, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .ack:
            try container.encode(MessageType.ack, forKey: .type)
        }
    }
}
