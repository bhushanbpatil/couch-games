//
//  GameUIComponents.swift
//  Couch Games
//

import SwiftUI

enum GameLayout {
    static let actionButtonHeight: CGFloat = 56
    static let horizontalPadding: CGFloat = 20
    static let actionBottomPadding: CGFloat = 12
}

struct GameHubIcon: View {
    let assetName: String
    var size: CGFloat = 56

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}

struct PinnedActionBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: GameLayout.actionButtonHeight)
    }
}

struct GameScreenBackground: View {
    var body: some View {
        CouchTheme.screenGradient
            .ignoresSafeArea()
    }
}

struct BigTimeDisplay: View {
    let label: String
    let seconds: TimeInterval
    var size: BigTimeSize = .hero
    var accent: Color = .white

    enum BigTimeSize {
        case hero, companion

        func valueFont(for seconds: TimeInterval) -> CGFloat {
            let length = Scoring.formatTimeValue(seconds).count
            switch self {
            case .hero:
                switch length {
                case ...4: return 76
                case 5: return 62
                default: return 52
                }
            case .companion:
                switch length {
                case ...4: return 48
                case 5: return 40
                default: return 34
                }
            }
        }

        var unitFont: CGFloat {
            switch self {
            case .hero: return 20
            case .companion: return 15
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(accent.opacity(0.75))

            Text(Scoring.formatTimeValue(seconds))
                .font(.system(size: size.valueFont(for: seconds), weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            Text("seconds")
                .font(.system(size: size.unitFont, weight: .semibold, design: .rounded))
                .foregroundStyle(accent.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(Scoring.formatSeconds(seconds))")
    }
}

struct PowerDeltaDisplay: View {
    let error: TimeInterval
    let style: CouchTheme.AccuracyStyle

    var body: some View {
        VStack(spacing: 8) {
            Text(style.label)
                .font(.caption.weight(.black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.85))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(style.gradient)
                Text(Scoring.formatTimeValue(error))
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(style.gradient)
                Text("sec off")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text("Δ difference")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(style.gradient, lineWidth: 2)
                }
                .shadow(color: style.glow, radius: 18, y: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style.label). Off by \(Scoring.formatSeconds(error))")
    }
}

struct PointsBurst: View {
    let points: Int
    let isPerfect: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("+\(points)")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    isPerfect
                        ? AnyShapeStyle(LinearGradient(colors: [CouchTheme.gold, .white], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(.white)
                )
                .shadow(color: isPerfect ? CouchTheme.gold.opacity(0.5) : .clear, radius: 12)

            Text(isPerfect ? "Double points!" : "Points earned")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct CouchPrimaryButton: ButtonStyle {
    var gradient: LinearGradient = CouchTheme.accentGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .shadow(color: CouchTheme.violet.opacity(0.35), radius: 12, y: 6)
    }
}

struct PlayerBadge: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.title2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(CouchTheme.accentGradient, in: Capsule())
            .shadow(color: CouchTheme.magenta.opacity(0.35), radius: 8, y: 4)
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
            }
    }
}
