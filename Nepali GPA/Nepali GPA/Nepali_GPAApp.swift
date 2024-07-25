import SwiftUI
import SwiftData

@main
struct YourAppName: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        LearningObject.self,
        GenericAudioFile.self,
        Tag.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
