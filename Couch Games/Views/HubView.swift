//
//  HubView.swift
//  Couch Games
//

import SwiftUI

struct HubView: View {
    @State private var passAndPlayExpanded = true
    @State private var everyPhoneExpanded = true

    var body: some View {
        ZStack {
            GameScreenBackground()

            List {
                CollapsibleHubSection(
                    title: "Pass & Play",
                    subtitle: "One phone passed around the group",
                    isExpanded: $passAndPlayExpanded
                ) {
                    ForEach(PassAndPlayGame.all) { game in
                        NavigationLink {
                            passAndPlayDestination(for: game.id)
                        } label: {
                            hubRow(title: game.title, subtitle: game.subtitle, icon: game.iconAsset)
                        }
                        .listRowBackground(Color.white.opacity(0.08))
                    }
                }

                CollapsibleHubSection(
                    title: "Connect Play",
                    subtitle: "Each player uses their own device nearby",
                    isExpanded: $everyPhoneExpanded
                ) {
                    ForEach(ConnectedGameKind.allCases) { game in
                        NavigationLink {
                            ConnectedEntryView(game: game)
                        } label: {
                            hubRow(title: game.title, subtitle: game.subtitle, icon: game.iconAsset)
                        }
                        .listRowBackground(Color.white.opacity(0.08))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listSectionSpacing(12)
        }
        .navigationTitle("Couch Games")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func passAndPlayDestination(for id: String) -> some View {
        switch id {
        case "headsUp": HeadsUpSetupView()
        case "timerGuess": SetupView()
        case "mafia": MafiaSetupView()
        case "resistance": ResistanceSetupView()
        case "chameleon": ChameleonSetupView()
        case "fakeArtist": FakeArtistSetupView()
        default: EmptyView()
        }
    }

    private func hubRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            GameHubIcon(assetName: icon)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        HubView()
    }
}
