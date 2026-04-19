import SwiftUI
import SwiftData

// MARK: - Intensity → colour palette

/// Maps an average intensity (1–5) to a set of 9 mesh colours.
/// Low  → cool lavender/indigo  Mid → teal/coral  High → orange/magenta
private func meshPalette(for intensity: Double) -> [Color] {
    let t = ((intensity - 1) / 4).clamped(to: 0...1)

    // Three anchor palettes
    let calm: [Color] = [
        Color(red: 0.45, green: 0.38, blue: 0.75),   // 0,0 — soft indigo
        Color(red: 0.30, green: 0.25, blue: 0.60),   // 1,0
        Color(red: 0.55, green: 0.42, blue: 0.80),   // 2,0
        Color(red: 0.38, green: 0.32, blue: 0.70),   // 0,1
        Color(red: 0.20, green: 0.18, blue: 0.40),   // 1,1 — deep center
        Color(red: 0.48, green: 0.36, blue: 0.72),   // 2,1
        Color(red: 0.52, green: 0.44, blue: 0.78),   // 0,2
        Color(red: 0.35, green: 0.28, blue: 0.62),   // 1,2
        Color(red: 0.60, green: 0.48, blue: 0.82),   // 2,2
    ]

    let balanced: [Color] = [
        Color(red: 0.20, green: 0.55, blue: 0.70),   // teal top-left
        Color(red: 0.15, green: 0.40, blue: 0.65),
        Color(red: 0.30, green: 0.60, blue: 0.75),
        Color(red: 0.65, green: 0.35, blue: 0.55),   // coral mid-left
        Color(red: 0.12, green: 0.12, blue: 0.22),   // deep center
        Color(red: 0.25, green: 0.50, blue: 0.68),
        Color(red: 0.70, green: 0.40, blue: 0.50),
        Color(red: 0.50, green: 0.30, blue: 0.60),
        Color(red: 0.28, green: 0.58, blue: 0.72),
    ]

    let intense: [Color] = [
        Color(red: 0.95, green: 0.42, blue: 0.18),   // sunset orange
        Color(red: 0.80, green: 0.25, blue: 0.50),   // hot pink
        Color(red: 0.95, green: 0.55, blue: 0.10),
        Color(red: 0.75, green: 0.20, blue: 0.60),   // magenta
        Color(red: 0.18, green: 0.10, blue: 0.22),   // dark center
        Color(red: 0.85, green: 0.35, blue: 0.20),
        Color(red: 0.90, green: 0.50, blue: 0.15),
        Color(red: 0.70, green: 0.22, blue: 0.55),
        Color(red: 0.95, green: 0.45, blue: 0.12),
    ]

    // Blend between the three anchors
    let (start, end, localT): ([Color], [Color], Double) = {
        if t < 0.5 { return (calm, balanced, t / 0.5) }
        else        { return (balanced, intense, (t - 0.5) / 0.5) }
    }()

    return zip(start, end).map { s, e in
        blendColor(from: s, to: e, t: localT)
    }
}

private func blendColor(from a: Color, to b: Color, t: Double) -> Color {
    let ar = a.components, br = b.components
    return Color(red:   ar.r + (br.r - ar.r) * t,
                 green: ar.g + (br.g - ar.g) * t,
                 blue:  ar.b + (br.b - ar.b) * t)
}

private extension Color {
    var components: (r: Double, g: Double, b: Double) {
        // Resolve via UIColor for reliable component extraction
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Drift math

/// 9 base positions for a 3×3 mesh (normalised 0–1).
private let basePoints: [SIMD2<Float>] = [
    [0.00, 0.00], [0.50, 0.00], [1.00, 0.00],
    [0.00, 0.50], [0.50, 0.50], [1.00, 0.50],
    [0.00, 1.00], [0.50, 1.00], [1.00, 1.00],
]

/// Drift amplitudes per point — corners barely move, center drifts most.
private let driftAmplitude: [SIMD2<Float>] = [
    [0.04, 0.04], [0.08, 0.05], [0.04, 0.04],
    [0.06, 0.08], [0.12, 0.12], [0.06, 0.08],
    [0.04, 0.04], [0.08, 0.05], [0.04, 0.04],
]

/// Each point drifts on its own phase so they never move in sync.
private let driftPhase: [SIMD2<Float>] = [
    [0.00, 1.57], [0.78, 0.39], [3.14, 0.78],
    [1.57, 0.00], [0.52, 2.09], [2.09, 1.05],
    [0.39, 3.14], [1.05, 0.52], [2.61, 1.83],
]

private let driftSpeed: Float = 0.35   // cycles per second

private func driftedPoints(at time: TimeInterval) -> [SIMD2<Float>] {
    let t = Float(time) * driftSpeed * .pi * 2
    return (0..<9).map { i in
        let base = basePoints[i]
        let amp  = driftAmplitude[i]
        let ph   = driftPhase[i]
        return SIMD2<Float>(
            (base.x + amp.x * sin(t + ph.x)).clamped(to: 0...1),
            (base.y + amp.y * cos(t + ph.y)).clamped(to: 0...1)
        )
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - VibeBloomView

struct VibeBloomView: View {
    /// Pass in the full entry list; the view derives intensity internally.
    let entries: [VibeEntry]

    private var dominantIntensity: Double {
        guard !entries.isEmpty else { return 2.5 }
        // Histogram: bucket into 1–5 integer bands
        var buckets = [Int: Int]()
        entries.forEach { buckets[Int($0.intensity.rounded()), default: 0] += 1 }
        let dominant = buckets.max(by: { $0.value < $1.value })?.key ?? 3
        return Double(dominant)
    }

    var body: some View {
        let colors = meshPalette(for: dominantIntensity)

        TimelineView(.animation) { context in
            let pts = driftedPoints(at: context.date.timeIntervalSinceReferenceDate)

            MeshGradient(
                width: 3, height: 3,
                points: pts,
                colors: colors,
                smoothsColors: true
            )
        }
        .blur(radius: 40)
        .ignoresSafeArea()
        // Darken slightly so cards on top remain readable
        .overlay(Color.black.opacity(0.38).ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview {
    VibeBloomView(entries: [])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
