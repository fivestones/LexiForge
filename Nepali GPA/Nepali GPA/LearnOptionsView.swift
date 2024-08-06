import SwiftUI
import SwiftData

struct LearnOptionsView: View {
    @Binding var currentView: CurrentView
    @EnvironmentObject private var learningViewModel: LearningViewModel
    @Query private var tags: [Tag]
    @State private var selectedTag: Tag?
    @State private var showLearnSetView = false

    var body: some View {
        VStack {
            Text("Select a tag to start learning")
                .font(.title)
                .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                    ForEach(tags) { tag in
                        TagButton(tag: tag, isSelected: selectedTag == tag) {
                            selectedTag = tag
                        }
                    }
                }
                .padding()
            }

            Button("Start Learning") {
                if let tag = selectedTag {
                    // learningViewModel.setCurrentTag(tag)
                    showLearnSetView = true
                }
                currentView = CurrentView.LearnSetView
//                showLearnSetView = true
            }
            .disabled(selectedTag == nil)
            .padding()
            .background(selectedTag != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
//        .sheet(isPresented: $showLearnSetView) {
//            LearnSetView()
//        }
    }
}

struct TagButton: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .padding()
                .frame(minWidth: 100)
                .background(isSelected ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
