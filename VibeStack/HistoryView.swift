import SwiftUI
import SwiftData

// MARK: - HistoryView (Calendar + List)

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VibeEntry.timestamp, order: .reverse) private var allEntries: [VibeEntry]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedEntry: VibeEntry? = nil
    @State private var showDetail = false
    @Namespace private var ns

    private var dayStart: Date { Calendar.current.startOfDay(for: selectedDate) }
    private var dayEnd: Date { Calendar.current.date(byAdding: .day, value: 1, to: dayStart)! }

    private var entriesForSelectedDay: [VibeEntry] {
        allEntries.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
                   .sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color(red: 0.11, green: 0.11, blue: 0.13).ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 16) {
                            // Compact month calendar
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .tint(Color(red: 1.0, green: 0.55, blue: 0.25))
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0.17, green: 0.17, blue: 0.20))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Day header
                            HStack {
                                Text(sectionTitle(for: selectedDate))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .textCase(.uppercase)
                                Spacer()
                                Text(entriesForSelectedDay.isEmpty ? "No vibes" : "\(entriesForSelectedDay.count) vibes")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.45))
                            }
                            .padding(.horizontal, 20)

                            // Entries list
                            if entriesForSelectedDay.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 28, weight: .thin))
                                        .foregroundStyle(Color.white.opacity(0.35))
                                    Text("No entries for this day.")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(entriesForSelectedDay) { entry in
                                        VibeCard(entry: entry, namespace: ns)
                                            .opacity(showDetail && selectedEntry?.id == entry.id ? 0 : 1)
                                            .onTapGesture {
                                                guard !showDetail else { return }
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                selectedEntry = entry
                                                withAnimation(.vibeSpring) { showDetail = true }
                                            }
                                            .listRowSeparator(.hidden)
                                            .padding(.horizontal, 20)
                                    }
                                    // bottom padding so last card is not tight to bottom
                                    Color.clear.frame(height: 12)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar(showDetail ? .hidden : .automatic, for: .navigationBar)
            }

            if showDetail, let entry = selectedEntry {
                VibeDetailView(
                    entry: entry,
                    namespace: ns,
                    isPresented: $showDetail
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionTitle(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: day)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: VibeEntry.self, inMemory: true)
}
