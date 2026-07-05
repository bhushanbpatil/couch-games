//
//  GameRulebookView.swift
//  Couch Games
//

import SwiftUI

struct GameRulebookView: View {
    let books: [CouchGameRulebook]
    var gradient: LinearGradient = CouchTheme.accentGradient

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CouchTheme.screenGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(books) { book in
                        VStack(alignment: .leading, spacing: 16) {
                            if books.count > 1 {
                                Text(book.title)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }

                            ForEach(Array(book.sections.enumerated()), id: \.offset) { _, section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section.heading)
                                        .font(.headline)
                                        .foregroundStyle(CouchTheme.cyan)

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(section.lines, id: \.self) { line in
                                            HStack(alignment: .top, spacing: 10) {
                                                Text("•")
                                                    .foregroundStyle(.white.opacity(0.45))
                                                Text(line)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white.opacity(0.85))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                }
                            }

                            if book.id != books.last?.id {
                                Divider()
                                    .overlay(.white.opacity(0.15))
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle(books.count == 1 ? "Rules" : "How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GameRulebookView(books: [.mafia])
    }
}
