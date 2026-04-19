import SwiftUI
import SwiftData
 
@main
struct VibeStackApp: App {
 
    let modelContainer: ModelContainer
 
    init() {
        do {
            modelContainer = try ModelContainer(
                for: VibeEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("❌ Failed to create ModelContainer for VibeEntry: \(error)")
        }
    }
 
    var body: some Scene {
        WindowGroup {
            HomeView().preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
        
    }
}
 

