//
//  HubView.swift
//  Couch Games
//

import SwiftUI

struct HubView: View {
    var body: some View {
        ZStack {
            GameScreenBackground()

            List {
                Section {
                    NavigationLink {
                        SetupView()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(CouchTheme.accentGradient)
                                    .frame(width: 56, height: 56)
                                Image(systemName: "timer")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Timer Guess")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text("Memorize · Count · Stop. Closest wins.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    NavigationLink {
                        MafiaSetupView()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(CouchTheme.mafiaAccentGradient)
                                    .frame(width: 56, height: 56)
                                Text("🕶️")
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Mafia")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text("Roles · Night · Vote. Find the Mafia.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    NavigationLink {
                        ResistanceSetupView()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(CouchTheme.resistanceAccentGradient)
                                    .frame(width: 56, height: 56)
                                Text("🛡️")
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Resistance")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text("Missions · Teams · Sabotage. Trust no one.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    NavigationLink {
                        FakeArtistSetupView()
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(CouchTheme.fakeArtistAccentGradient)
                                    .frame(width: 56, height: 56)
                                Text("🎨")
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Fake Artist")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text("Draw · Colors · Spot the fake.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                } header: {
                    Text("Party Games")
                        .foregroundStyle(.white.opacity(0.7))
                } footer: {
                    Text("Pass-and-play on one phone. No accounts needed.")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Couch Games")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        HubView()
    }
}
