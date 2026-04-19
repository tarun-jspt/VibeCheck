import SwiftUI

// MARK: - App-wide spring

extension Animation {
    /// The single spring used for all VibeStack hero transitions.
    static let vibeSpring = Animation.spring(duration: 0.6, bounce: 0.4)
}

// MARK: - VibeGlass ViewModifier

/// Applies a dark ultraThinMaterial card surface with a one-pixel gradient
/// border — the "Dark Mode Premium" look used across all VibeStack cards.
struct VibeGlass: ViewModifier {
    var cornerRadius: CGFloat = 22
    var borderOpacity: Double = 0.18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    // Inner glow: very faint white at top, fades out
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.07),
                                        Color.white.opacity(0.01)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    // Gradient border — brighter at top-left, dim at bottom-right
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(borderOpacity),
                                        Color.white.opacity(borderOpacity * 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }
}

extension View {
    /// Applies the VibeGlass "Dark Mode Premium" surface.
    func vibeGlass(cornerRadius: CGFloat = 22, borderOpacity: Double = 0.18) -> some View {
        modifier(VibeGlass(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}

// MARK: - Shared colour helpers (internal so all files can use them)

func vibeIntensityColor(_ v: Double) -> Color {
    let t = (v - 1) / 4
    if t <= 0.5 {
        let u = t / 0.5
        return Color(red: 0.79 + 0.15 * u,
                     green: 0.72 - 0.22 * u,
                     blue:  0.94 - 0.51 * u)
    } else {
        let u = (t - 0.5) / 0.5
        return Color(red: 0.94 + 0.06 * u,
                     green: 0.50 - 0.13 * u,
                     blue:  0.43 - 0.31 * u)
    }
}

func vibeRelativeTimestamp(_ date: Date) -> String {
    let diff = Date.now.timeIntervalSince(date)
    switch diff {
    case ..<60:      return "just now"
    case ..<3600:    return "\(Int(diff / 60))m ago"
    case ..<86400:   return "\(Int(diff / 3600))h ago"
    case ..<604800:  return "\(Int(diff / 86400))d ago"
    default:
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
