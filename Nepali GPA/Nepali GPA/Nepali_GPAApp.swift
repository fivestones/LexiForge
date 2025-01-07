import SwiftUI
import SwiftData

@main
struct YourAppName: App {
    @StateObject private var learningViewModel: LearningViewModel
//    @State var currentView: CurrentView = .LearnSetView

    init() {
        let modelContext = sharedModelContainer.mainContext
        _learningViewModel = StateObject(wrappedValue: LearningViewModel(modelContext: modelContext))
    }

    var body: some Scene {
        WindowGroup {
//            LearnSetView(currentView: $currentView)
            ContentView()
                .environmentObject(learningViewModel)
                .onAppear {
                    learningViewModel.performInitialSetup()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        LearningObject.self,
        GenericAudioFile.self,
        Category.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
