//
//  BluffBarrelCard.swift
//  Couch Games
//

import Foundation

enum BluffBarrelRank: String, Codable, CaseIterable, Identifiable {
    case king
    case queen
    case ace
    case joker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .king: return "King"
        case .queen: return "Queen"
        case .ace: return "Ace"
        case .joker: return "Joker"
        }
    }

    var shortLabel: String {
        switch self {
        case .king: return "K"
        case .queen: return "Q"
        case .ace: return "A"
        case .joker: return "★"
        }
    }

    static var tableRanks: [BluffBarrelRank] { [.king, .queen, .ace] }
}

struct BluffBarrelCard: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let rank: BluffBarrelRank

    init(id: UUID = UUID(), rank: BluffBarrelRank) {
        self.id = id
        self.rank = rank
    }

    func isValid(for tableRank: BluffBarrelRank) -> Bool {
        rank == .joker || rank == tableRank
    }
}

enum BluffBarrelDeck {
    static func shuffled() -> [BluffBarrelCard] {
        var cards: [BluffBarrelCard] = []
        for _ in 0..<6 { cards.append(BluffBarrelCard(rank: .king)) }
        for _ in 0..<6 { cards.append(BluffBarrelCard(rank: .queen)) }
        for _ in 0..<6 { cards.append(BluffBarrelCard(rank: .ace)) }
        for _ in 0..<2 { cards.append(BluffBarrelCard(rank: .joker)) }
        return cards.shuffled()
    }
}
