import SwiftUI
import SwiftData

// MARK: - Constants

private extension CGFloat {
    static let sliderTrackWidth: CGFloat = 28
    static let sliderThumbSize: CGFloat = 52
    static let emojiButtonSize: CGFloat = 56
}

private struct MoodIcon: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let label: String
    let emojiFallback: String
}

private let moodIcons: [MoodIcon] = [
    MoodIcon(imageName: "awful",   label: "Awful",   emojiFallback: "😭"),
    MoodIcon(imageName: "bad",     label: "Bad",     emojiFallback: "🙁"),
    MoodIcon(imageName: "normal",  label: "Normal",  emojiFallback: "😐"),
    MoodIcon(imageName: "good",    label: "Good",    emojiFallback: "🙂"),
    MoodIcon(imageName: "awesome", label: "Awesome", emojiFallback: "🤩")
]

// MARK: - Colour helpers

private func vibeColor(for intensity: Double) -> Color {
    // 1.0 → soft lavender  #C9B8F0
    // 3.0 → warm coral     #F07F6E
    // 5.0 → sunset orange  #FF5F1F
    let t = (intensity - 1.0) / 4.0          // 0 … 1

    let lavender  = (r: 0.788, g: 0.722, b: 0.941)
    let coral     = (r: 0.941, g: 0.498, b: 0.431)
    let orange    = (r: 1.000, g: 0.373, b: 0.122)

    let (startR, startG, startB): (Double, Double, Double)
    let (endR,   endG,   endB  ): (Double, Double, Double)
    let localT: Double

    if t <= 0.5 {
        (startR, startG, startB) = (lavender.r, lavender.g, lavender.b)
        (endR,   endG,   endB  ) = (coral.r,    coral.g,    coral.b)
        localT = t / 0.5
    } else {
        (startR, startG, startB) = (coral.r, coral.g, coral.b)
        (endR,   endG,   endB  ) = (orange.r, orange.g, orange.b)
        localT = (t - 0.5) / 0.5
    }

    return Color(
        red:   startR + (endR   - startR) * localT,
        green: startG + (endG   - startG) * localT,
        blue:  startB + (endB   - startB) * localT
    )
}

private func labelFor(intensity: Double) -> String {
    switch intensity {
    case ..<1.8: return "Calm"
    case ..<2.6: return "Mellow"
    case ..<3.4: return "Balanced"
    case ..<4.2: return "Energised"
    default:     return "Intense"
    }
}

// MARK: - Vertical intensity slider

struct VerticalIntensitySlider: View {
    @Binding var intensity: Double          // 1.0 … 5.0
    let trackColor: Color

    // Internal drag state
    @State private var dragStartY: CGFloat = 0
    @State private var dragStartIntensity: Double = 1.0

    private let range: ClosedRange<Double> = 1.0...5.0
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geo in
            let trackH = geo.size.height

            ZStack(alignment: .bottom) {
                // Track background
                RoundedRectangle(cornerRadius: .sliderTrackWidth / 2)
                    .fill(.white.opacity(0.25))
                    .frame(width: .sliderTrackWidth)

                // Filled portion
                RoundedRectangle(cornerRadius: .sliderTrackWidth / 2)
                    .fill(.white.opacity(0.55))
                    .frame(width: .sliderTrackWidth, height: filledHeight(trackH))
                    .animation(.interactiveSpring(), value: intensity)

                // Thumb
                ZStack {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                    Text(intensityIcon)
                        .font(.system(size: 22))
                }
                .frame(width: .sliderThumbSize, height: .sliderThumbSize)
                .offset(y: thumbOffset(trackH))
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: intensity)
            }
            .frame(width: geo.size.width)       // centre in given width
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if value.translation == .zero {
                            dragStartY = value.location.y
                            dragStartIntensity = intensity
                        }
                        let delta = dragStartY - value.location.y  // up = more
                        let ratio = delta / (trackH - .sliderThumbSize)
                        let newVal = (dragStartIntensity + ratio * 4.0)
                            .clamped(to: range)
                        if abs(newVal - intensity) >= 0.05 {
                            haptic.impactOccurred(intensity: CGFloat(newVal / 5.0))
                        }
                        intensity = newVal
                    }
            )
        }
    }

    // MARK: Geometry helpers

    private func filledHeight(_ trackH: CGFloat) -> CGFloat {
        let ratio = (intensity - 1.0) / 4.0
        return max(.sliderThumbSize / 2, trackH * CGFloat(ratio))
    }

    private func thumbOffset(_ trackH: CGFloat) -> CGFloat {
        // 0 at top  →  centre of thumb at top edge; full at bottom
        let ratio = (intensity - 1.0) / 4.0
        let travel = trackH - .sliderThumbSize
        return -travel * CGFloat(ratio)     // negative = up
    }

    private var intensityIcon: String {
        switch intensity {
        case ..<2.0: return "🌙"
        case ..<3.0: return "🌤️"
        case ..<4.0: return "☀️"
        case ..<4.6: return "⚡️"
        default:     return "🔥"
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Main view

struct AddVibeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var intensity: Double = 2.5
    @State private var selectedMood: MoodIcon = moodIcons[3] // default to 'Good'
    @State private var note: String = ""
    @FocusState private var noteIsFocused: Bool

    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationHaptic = UINotificationFeedbackGenerator()

    var body: some View {
        let accent = vibeColor(for: intensity)

        ZStack {
            // ── Animated background ──────────────────────────────────────
            accent
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: intensity)

            // Subtle radial highlight
            RadialGradient(
                colors: [.white.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // ── Content ──────────────────────────────────────────────────
            VStack(spacing: 0) {

                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.white.opacity(0.2), in: Circle())
                    }
                    Spacer()
                    Text("Log Your Vibe")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    // Balance spacer
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)

                // ── Slider + Labels card ─────────────────────────────────
                HStack(alignment: .center, spacing: 32) {

                    // Vertical slider
                    VerticalIntensitySlider(intensity: $intensity, trackColor: accent)
                        .frame(width: .sliderThumbSize, height: 220)

                    // Right-side labels
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()

                        Text(labelFor(intensity: intensity))
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: intensity)

                        Text("Vibe Intensity")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.top, 2)

                        Spacer()

                        // Pip indicators
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { pip in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Double(pip) <= intensity
                                          ? Color.white
                                          : Color.white.opacity(0.3))
                                    .frame(width: pip == Int(intensity.rounded()) ? 24 : 10, height: 6)
                                    .animation(.spring(response: 0.25), value: intensity)
                            }
                        }
                        .padding(.bottom, 4)

                        Text(String(format: "%.1f / 5.0", intensity))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 32)

                // ── Bottom card ──────────────────────────────────────────
                VStack(spacing: 0) {

                    // Emoji picker
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pick a Mood", systemImage: "face.smiling")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(moodIcons) { mood in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedMood = mood
                                        }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }) {
                                        VStack(spacing: 6) {
                                            Image(mood.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: .emojiButtonSize, height: .emojiButtonSize)
                                                .background(
                                                    selectedMood == mood ? vibeColor(for: intensity).opacity(0.18) : Color.clear,
                                                    in: RoundedRectangle(cornerRadius: 16)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .strokeBorder(
                                                            selectedMood == mood ? vibeColor(for: intensity) : .clear,
                                                            lineWidth: 2.5
                                                        )
                                                )
                                                .scaleEffect(selectedMood == mood ? 1.0 : 1.0)

                                            Text(mood.label)
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedMood)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 28)

                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Quick Note", systemImage: "pencil")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.gray)

                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("What's on your mind?")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 18)
                            }
                            TextField("", text: $note, axis: .vertical)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(3...5)
                                .focused($noteIsFocused)
                                .padding(14)
                        }
                        .background(accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)

                    // Save button
                    Button(action: saveVibe) {
                        HStack(spacing: 10) {
                            Image(selectedMood.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text("Save Vibe")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(accent, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: accent.opacity(0.45), radius: 12, y: 6)
                        .animation(.easeInOut(duration: 0.35), value: intensity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(.white, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 20, y: -4)
                .padding(.top, 8)
            }
        }
        .onTapGesture { noteIsFocused = false }
    }

    // MARK: - Save

    private func saveVibe() {
        heavyHaptic.prepare()
        heavyHaptic.impactOccurred()
        notificationHaptic.notificationOccurred(.success)

        let entry = VibeEntry(
            moodID: selectedMood.imageName,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            intensity: intensity,
            moodEmoji: selectedMood.imageName
        )
        modelContext.insert(entry)

        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to save VibeEntry: \(error)")
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddVibeView()
        .modelContainer(for: VibeEntry.self, inMemory: true)
}

