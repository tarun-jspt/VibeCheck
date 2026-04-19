import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VibeEntry.timestamp, order: .reverse) private var entries: [VibeEntry]

    @State private var showAddVibe = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple.gradient)

                Text("Vibe Check")
                    .font(.largeTitle.bold())

                Text("\(entries.count) vibe\(entries.count == 1 ? "" : "s") logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    // NavigationLink pushes to a new screen (correct for list)
                    NavigationLink("📋 View All Vibes") {
                        Text("Vibe List — Coming Soon")
                            .navigationTitle("All Vibes")
                    }
                    .buttonStyle(.borderedProminent)

                    // Button + .sheet presents AddVibeView as a modal
                    Button("➕ Log a Vibe") {
                        showAddVibe = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Vibe Check")
            .navigationBarTitleDisplayMode(.inline)
            // .sheet sits on the NavigationStack, not on the Button
            .sheet(isPresented: $showAddVibe) {
                AddVibeView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: VibeEntry.self, inMemory: true)
}
