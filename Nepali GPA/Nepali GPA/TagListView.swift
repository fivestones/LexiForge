import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var newCategoryName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(categories) { category in
                        Text(category.name)
                    }
                    .onDelete(perform: deleteCategories)
                }

                HStack {
                    TextField("New Tag", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: addCategory) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Tags")
            .navigationBarItems(trailing: EditButton())
        }
        .navigationViewStyle(.stack)
    }

    private func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        let newCategory = Category(name: newCategoryName, objects: [])
        modelContext.insert(newCategory)
        try? modelContext.save()
        newCategoryName = ""
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            modelContext.delete(category)
        }
        try? modelContext.save()
    }
}
