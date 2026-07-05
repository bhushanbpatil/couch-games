//
//  FakeArtistColorPalette.swift
//  Couch Games
//

import SwiftUI

enum FakeArtistColorPalette {
    struct Ink: Equatable {
        let name: String
        let color: Color
    }

    static let inks: [Ink] = [
        Ink(name: "Cyan", color: Color(red: 0.10, green: 0.75, blue: 0.92)),
        Ink(name: "Coral", color: Color(red: 0.98, green: 0.42, blue: 0.38)),
        Ink(name: "Lime", color: Color(red: 0.55, green: 0.88, blue: 0.25)),
        Ink(name: "Violet", color: Color(red: 0.62, green: 0.38, blue: 0.95)),
        Ink(name: "Gold", color: Color(red: 1.0, green: 0.78, blue: 0.18)),
        Ink(name: "Pink", color: Color(red: 0.95, green: 0.35, blue: 0.65)),
        Ink(name: "Orange", color: Color(red: 1.0, green: 0.55, blue: 0.12)),
        Ink(name: "Blue", color: Color(red: 0.25, green: 0.45, blue: 0.95)),
        Ink(name: "Mint", color: Color(red: 0.30, green: 0.90, blue: 0.75)),
        Ink(name: "Red", color: Color(red: 0.92, green: 0.18, blue: 0.28))
    ]

    static func ink(for index: Int) -> Ink {
        inks[index % inks.count]
    }
}
