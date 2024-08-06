import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var learningViewModel: LearningViewModel
    @State private var selectedTab = 0
    @State var currentView: CurrentView = .ControlView
    
    var body: some View {
        switch currentView {
        case CurrentView.ControlView:
            ControlView(currentView: $currentView)
        case CurrentView.LearnSetView:
            LearnSetView(currentView: $currentView)
        }
    }
}

struct ControlView: View {
    @Binding var currentView: CurrentView
    
    @EnvironmentObject private var learningViewModel: LearningViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LearnOptionsView(currentView: $currentView)
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(0)

            ObjectListView(sort: SortDescriptor(\LearningObject.name))
                .tabItem {
                    Label("Objects", systemImage: "list.bullet")
                }
                .tag(1)

            TagListView()
                .tabItem {
                    Label("Tags", systemImage: "tag.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

// Placeholder view for Settings
struct SettingsView: View {
    var body: some View {
        Text("Settings View")
            .font(.largeTitle)
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LearningViewModel(modelContext: previewContainer.mainContext))
            .modelContainer(previewContainer)
    }
}

// Convenience preview container
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(for: LearningObject.self, GenericAudioFile.self, Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return container
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}()

enum CurrentView {
    case LearnSetView
    case ControlView
}
