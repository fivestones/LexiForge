import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: LearnSetView(modelContext: modelContext)) {
                    Text("Learn Set")
                }
                NavigationLink(destination: AddObjectView()) {
                    Text("Add New Object")
                }
            }
            .navigationTitle("Language Learning App")
        }
    }
}
