//
//  ConfusionMascotView.swift
//  Couch Games
//

import SwiftUI

struct ConfusionMascotView: View {
    @State private var yelledNumber = "7!"
    @State private var bounce = false
    @State private var wiggle = false
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                speechBubble
                    .offset(x: 52, y: -36)
                    .rotationEffect(.degrees(bounce ? 6 : -4))

                mascotBody
                    .scaleEffect(wiggle ? 1.04 : 0.98)
            }
            .frame(height: 130)

            Text("Count in your head…")
                .font(.headline.weight(.bold))
            Text("Ignore the yelling — tap Stop when you're there")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            yelledNumber = randomYell()
            startYelling()
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                wiggle = true
            }
        }
        .onDisappear {
            timerTask?.cancel()
            timerTask = nil
        }
    }

    private var speechBubble: some View {
        ZStack(alignment: .bottomLeading) {
            Text(yelledNumber)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(CouchTheme.deepIndigo)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }

            Circle()
                .fill(.white)
                .frame(width: 10, height: 10)
                .offset(x: -4, y: 10)
        }
        .animation(.snappy, value: yelledNumber)
    }

    private var mascotBody: some View {
        ZStack {
            // Soft glow
            Circle()
                .fill(CouchTheme.magenta.opacity(0.25))
                .frame(width: 118, height: 118)
                .blur(radius: 8)

            // Main head — squishier ellipse
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.72, blue: 0.82),
                            Color(red: 0.95, green: 0.55, blue: 0.75),
                            CouchTheme.violet.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 100, height: 92)
                .overlay {
                    Ellipse()
                        .stroke(.white.opacity(0.25), lineWidth: 2)
                }
                .shadow(color: CouchTheme.magenta.opacity(0.35), radius: 10, y: 5)

            // Cheeks
            HStack(spacing: 52) {
                cheek
                cheek
            }
            .offset(y: 12)

            // Eyes
            HStack(spacing: 26) {
                cuteEye
                cuteEye
            }
            .offset(y: -6)

            // Open yelling mouth
            Ellipse()
                .fill(CouchTheme.deepIndigo.opacity(0.85))
                .frame(width: 22, height: 16)
                .offset(y: 18)

            // Tiny arms
            HStack(spacing: 78) {
                arm(rotation: bounce ? -18 : -8)
                arm(rotation: bounce ? 18 : 8)
            }
            .offset(y: 8)
        }
    }

    private var cheek: some View {
        Circle()
            .fill(Color.pink.opacity(0.45))
            .frame(width: 16, height: 16)
            .blur(radius: 1)
    }

    private var cuteEye: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
            Circle()
                .fill(CouchTheme.deepIndigo)
                .frame(width: 14, height: 14)
                .offset(x: 2, y: 2)
            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)
                .offset(x: 4, y: -2)
        }
    }

    private func arm(rotation: Double) -> some View {
        Capsule()
            .fill(Color(red: 1.0, green: 0.72, blue: 0.82))
            .frame(width: 12, height: 28)
            .rotationEffect(.degrees(rotation), anchor: .top)
    }

    private func startYelling() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                let delay = UInt64.random(in: 350_000_000...750_000_000)
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.snappy) {
                        yelledNumber = randomYell()
                        bounce.toggle()
                    }
                }
            }
        }
    }

    private func randomYell() -> String {
        let formats: [() -> String] = [
            { "\(Int.random(in: 1...12))!" },
            { String(format: "%.1f!", Double.random(in: 1.0...10.9)) },
            { "\(Int.random(in: 20...99))!" },
            { String(format: "%.2f!", Double.random(in: 0.5...9.99)) },
            { ["NOW!", "GO!", "WAIT!", "STOP?!", "TWO!"].randomElement()! }
        ]
        return formats.randomElement()!()
    }
}

#Preview {
    ZStack {
        GameScreenBackground()
        ConfusionMascotView()
    }
}
