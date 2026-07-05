//
//  CollapsibleHubSection.swift
//  Couch Games
//

import SwiftUI

struct CollapsibleHubSection<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        Section {
            if isExpanded {
                content
            }
        } header: {
            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    isExpanded.toggle()
                }
                Haptics.impact(.light)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(CouchTheme.gold.opacity(0.85))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }
}
