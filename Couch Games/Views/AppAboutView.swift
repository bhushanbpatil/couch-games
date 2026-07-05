//
//  AppAboutView.swift
//  Couch Games
//

import SwiftUI

struct AppAboutView: View {
    var body: some View {
        ZStack {
            GameScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Couch Games")
                            .font(.title.bold())
                        Text("Version \(AppLegal.appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Pass-and-play party games for friends in the same room.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    aboutSection(title: "Privacy") {
                        Text("Couch Games does not collect, sell, or store your personal data. Player names and game state stay on your device for the session.")
                        Text("Connect Play uses Apple's nearby device networking so phones in the same room can join a game. That traffic stays between devices — we do not operate a game server.")
                        Link("Full privacy policy", destination: AppLegal.privacyPolicyURL)
                            .font(.subheadline.weight(.semibold))
                    }

                    aboutSection(title: "Support") {
                        Text("Bug reports and questions:")
                        Link(AppLegal.supportEmail, destination: AppLegal.supportEmailURL)
                            .font(.subheadline.weight(.semibold))
                        Link("GitHub issues", destination: AppLegal.supportURL)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func aboutSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(CouchTheme.gold)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.06)))
    }
}

#Preview {
    NavigationStack {
        AppAboutView()
    }
}
