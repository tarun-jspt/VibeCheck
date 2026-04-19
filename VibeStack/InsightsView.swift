import SwiftUI
import SwiftData
import Charts

// MARK: - Data helpers

struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let avgIntensity: Double
    let label: String          // "Mon", "Tue" …
}

struct EmojiFrequency: Identifiable {
    let id = UUID()
    let emoji: String
    let count: Int
}

/// Returns midnight of `daysAgo` days before today.
private func startOf(daysAgo: Int) -> Date {
    Calendar.current.startOfDay(for: Date.now) - TimeInterval(daysAgo * 86400)
}

private func shortWeekday(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "EEE"
    return f.string(from: date)
}

// MARK: - View-model logic (pure functions, no ObservableObject needed)

private func last7DayPoints(from entries: [VibeEntry]) -> [DailyPoint] {
    (0..<7).reversed().map { daysAgo -> DailyPoint in
        let dayStart = startOf(daysAgo: daysAgo)
        let dayEnd   = dayStart + 86400
        let slice    = entries.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
        let avg      = slice.isEmpty ? 0.0 : slice.map(\.intensity).reduce(0, +) / Double(slice.count)
        return DailyPoint(date: dayStart, avgIntensity: avg, label: shortWeekday(dayStart))
    }
}

private func topEmojis(from entries: [VibeEntry], limit: Int = 5) -> [EmojiFrequency] {
    var counts: [String: Int] = [:]
    entries.forEach { counts[$0.moodEmoji, default: 0] += 1 }
    return counts
        .sorted { $0.value > $1.value }
        .prefix(limit)
        .map { EmojiFrequency(emoji: $0.key, count: $0.value) }
}

/// AI-style summary comparing this week vs last week
private func moodSummary(thisWeek: [VibeEntry], lastWeek: [VibeEntry]) -> String {
    let thisAvg = thisWeek.isEmpty ? 0.0 : thisWeek.map(\.intensity).reduce(0, +) / Double(thisWeek.count)
    let lastAvg = lastWeek.isEmpty ? 0.0 : lastWeek.map(\.intensity).reduce(0, +) / Double(lastWeek.count)

    guard thisAvg > 0 else { return "Start logging vibes to unlock your personal insights." }
    guard lastAvg > 0 else { return "Keep logging — insights improve with more data." }

    let delta      = thisAvg - lastAvg
    let pct        = Int(abs(delta / lastAvg * 100))
    let direction  = delta >= 0 ? "higher" : "lower"
    let feel       = thisAvg >= 4.0 ? "energised" : thisAvg >= 3.0 ? "balanced" : "calm"

    return "Your energy has been \(pct)% \(direction) this week than last — you're trending \(feel). 🧠"
}

// MARK: - Gradient area chart

struct IntensityLineChart: View {
    let points: [DailyPoint]

    // Accent gradient matching app palette
    private let areaGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.37, blue: 0.12).opacity(0.55),
            Color(red: 0.79, green: 0.42, blue: 0.94).opacity(0.18),
            Color.clear
        ],
        startPoint: .top, endPoint: .bottom
    )

    private let lineGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.55, blue: 0.25),
                 Color(red: 0.78, green: 0.29, blue: 0.95)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        Chart {
            ForEach(points) { point in
                // Area fill
                AreaMark(
                    x: .value("Day",       point.label),
                    yStart: .value("Base", 0),
                    yEnd:   .value("Intensity", point.avgIntensity)
                )
                .foregroundStyle(areaGradient)
                .interpolationMethod(.catmullRom)

                // Line
                LineMark(
                    x: .value("Day",       point.label),
                    y: .value("Intensity", point.avgIntensity)
                )
                .foregroundStyle(lineGradient)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)

                // Points
                PointMark(
                    x: .value("Day",       point.label),
                    y: .value("Intensity", point.avgIntensity)
                )
                .foregroundStyle(.white)
                .symbolSize(point.avgIntensity > 0 ? 38 : 0)
            }
        }
        .chartYScale(domain: 0...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.35))
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.45))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
        }
        .frame(height: 190)
    }
}

// MARK: - Emoji frequency cell

struct EmojiFrequencyCell: View {
    let item: EmojiFrequency
    let maxCount: Int

    private var fillFraction: Double {
        maxCount > 0 ? Double(item.count) / Double(maxCount) : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                // Background track
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 64)

                // Fill bar
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.55, blue: 0.25).opacity(0.7),
                                     Color(red: 0.78, green: 0.29, blue: 0.95).opacity(0.5)],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .frame(height: max(8, 64 * fillFraction))
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: fillFraction)
                Image(item.emoji)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
            }
            .frame(height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("×\(item.count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }
}

// MARK: - Section header

struct InsightsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.25))
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
                .kerning(0.6)
                .textCase(.uppercase)
            Spacer()
        }
    }
}

// MARK: - InsightsView

struct InsightsView: View {
    @Query(sort: \VibeEntry.timestamp, order: .reverse) private var allEntries: [VibeEntry]

    private let bg    = Color(red: 0.11, green: 0.11, blue: 0.13)
    private let card  = Color(red: 0.17, green: 0.17, blue: 0.20)

    // Derived data
    private var thisWeek: [VibeEntry] {
        allEntries.filter { $0.timestamp >= startOf(daysAgo: 7) }
    }
    private var lastWeek: [VibeEntry] {
        let end   = startOf(daysAgo: 7)
        let start = startOf(daysAgo: 14)
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }
    private var chartPoints:  [DailyPoint]      { last7DayPoints(from: thisWeek) }
    private var emojiItems:   [EmojiFrequency]  { topEmojis(from: thisWeek) }
    private var summaryText:  String            { moodSummary(thisWeek: thisWeek, lastWeek: lastWeek) }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Chart card ────────────────────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            InsightsSectionHeader(title: "Vibe Intensity · 7 days",
                                                  icon: "waveform.path.ecg")
                            IntensityLineChart(points: chartPoints)
                        }
                        .padding(20)
                        .background(card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                        )

                        // ── AI Summary card ───────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            InsightsSectionHeader(title: "Mood Summary", icon: "sparkles")

                            Text(summaryText)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(
                            // Subtle gradient tint on summary card
                            LinearGradient(
                                colors: [Color(red: 0.22, green: 0.16, blue: 0.28),
                                         card],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.55, blue: 0.25).opacity(0.4),
                                                 Color(red: 0.78, green: 0.29, blue: 0.95).opacity(0.3)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )

                        // ── Top Moods grid ────────────────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            InsightsSectionHeader(title: "Top Moods · This Week",
                                                  icon: "face.smiling")

                            if emojiItems.isEmpty {
                                Text("No entries this week yet.")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.3))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                let cols = Array(repeating: GridItem(.flexible(), spacing: 12),
                                                 count: min(emojiItems.count, 6))
                                LazyVGrid(columns: cols, spacing: 12) {
                                    ForEach(emojiItems) { item in
                                        EmojiFrequencyCell(
                                            item: item,
                                            maxCount: emojiItems.first?.count ?? 1
                                        )
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                        )

                        // Stats footer row
                        HStack(spacing: 12) {
                            StatPill(label: "This week",
                                     value: "\(thisWeek.count) vibes")
                            StatPill(label: "Avg intensity",
                                     value: thisWeek.isEmpty ? "—" :
                                        String(format: "%.1f",
                                               thisWeek.map(\.intensity).reduce(0,+) / Double(thisWeek.count)))
                            StatPill(label: "Last week",
                                     value: "\(lastWeek.count) vibes")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Stat pill

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .modelContainer(for: VibeEntry.self, inMemory: true)
}
