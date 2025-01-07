import SwiftUI
import SwiftData

struct ObjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var objects: [LearningObject]  // Query all LearningObjects
    @Query private var categories: [Category]    // Query all Categories
    @State private var selectedCategories: Set<UUID> = []
    @State private var selectedObjectID: UUID?
    @State private var isAddingNewObject = false
    
    var filteredObjects: [LearningObject] {
        objects.filter { object in
            // Only filter by selected categories
            selectedCategories.isEmpty ||
                !selectedCategories.isDisjoint(with: object.setCategories)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Category Filter Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories) { category in
                            CategoryFilterView(category: category, isSelected: selectedCategories.contains(category.id)) {
                                if selectedCategories.contains(category.id) {
                                    selectedCategories.remove(category.id)
                                } else {
                                    selectedCategories.insert(category.id)
                                }
                            }
                        }
                    }
                    .padding()
                }

                List {
                    ForEach(filteredObjects) { object in
                        Button(action: {
                            selectedObjectID = object.id
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(object.name)
                                        .font(.headline)
                                    Text(object.nepaliName)
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteObjects)
                }
            }
            .navigationTitle("Objects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingNewObject = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: selectedObjectBinding()) { object in
                NavigationStack {
                    EditObjectView(object: Binding(
                        get: { object },
                        set: { newValue in
                            if let index = objects.firstIndex(where: { $0.id == object.id }) {
                                modelContext.insert(newValue)
                            }
                        }
                    ))
                    .navigationTitle("Edit Object")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                try? modelContext.save()
                                selectedObjectID = nil
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddingNewObject) {
                NavigationStack {
                    AddObjectView()
                        .navigationTitle("Add New Object")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save") {
                                    try? modelContext.save()
                                    isAddingNewObject = false
                                }
                            }
                        }
                }
            }
        }
    }

    private func selectedObjectBinding() -> Binding<LearningObject?> {
        Binding<LearningObject?>(
            get: { selectedObjectID.flatMap { id in objects.first(where: { $0.id == id }) } },
            set: { object in selectedObjectID = object?.id }
        )
    }

    private func deleteObjects(at offsets: IndexSet) {
        for index in offsets {
            let object = filteredObjects[index]
            modelContext.delete(object)
        }
        try? modelContext.save()
    }
}

struct CategoryFilterView: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Text(category.name)
            .padding(8)
            .background(isSelected ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .onTapGesture {
                action()
            }
    }
}
