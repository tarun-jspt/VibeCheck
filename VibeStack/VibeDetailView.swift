import SwiftUI

// MARK: - VibeDetailView
// Presented as an overlay when a card is tapped in HomeView.
// The namespace + IDs must match exactly what HomeView stamps on each card.

struct VibeDetailView: View {
    let entry: VibeEntry
    let namespace: Namespace.ID
    @Binding var isPresented: Bool

    private var accent: Color { vibeIntensityColor(entry.intensity) }

    // Formatted full date
    private var fullDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: entry.timestamp)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // ── Blurred backdrop ─────────────────────────────────────────
            Color.black
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // ── Expanded card ────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {

                // Hero header — matches the compact card geometry
                HStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.22))
                            .matchedGeometryEffect(id: "bubble-\(entry.id)", in: namespace)
                            .frame(width: 72, height: 72)
                        Image(entry.moodID)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .matchedGeometryEffect(id: "emoji-\(entry.id)", in: namespace)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(vibeRelativeTimestamp(entry.timestamp))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                            .matchedGeometryEffect(id: "time-\(entry.id)", in: namespace)

                        Text(labelForMoodID(entry.moodID))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))

                        // Intensity label
                        Text(intensityLabel)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .padding(24)

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 24)

                // Full note
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Note")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(0.8)
                            .textCase(.uppercase)

                        Text(entry.note.isEmpty ? "No note recorded." : entry.note)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(entry.note.isEmpty ? .white.opacity(0.3) : .white)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .background(Color.white.opacity(0.08))

                        // Stats row
                        HStack(spacing: 0) {
                            detailStat(label: "Intensity",
                                       value: String(format: "%.1f", entry.intensity))
                            Spacer()
                            detailStat(label: "Date", value: fullDate)
                        }

                        // Intensity pip bar
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { pip in
                                Capsule()
                                    .fill(Double(pip) <= entry.intensity
                                          ? accent : Color.white.opacity(0.12))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 6)
                                    .matchedGeometryEffect(
                                        id: "pip-\(entry.id)-\(pip)", in: namespace)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                }

                // Dismiss button
                Button(action: dismiss) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent.opacity(0.25),
                                    in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(accent.opacity(0.4), lineWidth: 1)
                        )
                }
                .padding([.horizontal, .bottom], 24)
            }
            .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.16))  // solid — no bleed-through
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.6), radius: 32, y: 16)
                        )
            .padding(.horizontal, 16)
            .padding(.vertical, 60)
            .matchedGeometryEffect(id: "card-\(entry.id)", in: namespace)
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func dismiss() {
        withAnimation(.vibeSpring) { isPresented = false }
    }

    private var intensityLabel: String {
        switch entry.intensity {
        case ..<2.0: return "Calm 🌙"
        case ..<3.0: return "Mellow 🌤️"
        case ..<4.0: return "Balanced ☀️"
        case ..<4.6: return "Energised ⚡️"
        default:     return "Intense 🔥"
        }
    }

    @ViewBuilder
    private func detailStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .kerning(0.6)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
    
    private func labelForMoodID(_ id: String) -> String {
        switch id {
        case "awful": return "Awful"
        case "bad": return "Bad"
        case "normal": return "Normal"
        case "good": return "Good"
        case "awesome": return "Awesome"
        default: return "Mood"
        }
    }
}

