import SwiftUI
import SwiftData

struct LearnOptionsView: View {
    @Binding var currentView: CurrentView
    @EnvironmentObject private var learningViewModel: LearningViewModel
    @Query private var categories: [Category]
    @State private var selectedCategory: Category?
    @State private var showLearnSetView = false

    var body: some View {
        VStack {
            Text("Select a Category to start learning")
                .font(.title)
                .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                    ForEach(categories) { category in
                        CategoryButton(category: category, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }

            Button("Start Learning") {
                if let category = selectedCategory {
                    // learningViewModel.setCurrentCategory(category)
                    learningViewModel.setCurrentCategory(category)
                    showLearnSetView = true
                }
                currentView = CurrentView.LearnSetView
//                showLearnSetView = true
            }
            .disabled(selectedCategory == nil)
            .padding()
            .background(selectedCategory != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
//        .sheet(isPresented: $showLearnSetView) {
//            LearnSetView()
//        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.name)
                .padding()
                .frame(minWidth: 100)
                .background(isSelected ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
