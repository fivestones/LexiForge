import SwiftUI
import SwiftData

struct ObjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var objects: [LearningObject]
    @Query private var tags: [Tag]
    @State private var selectedTags: Set<UUID> = []
    @State private var selectedObjectID: UUID?
    @State private var isAddingNewObject = false

    init(sort: SortDescriptor<LearningObject>) {
        _objects = Query(filter: #Predicate {
            $0.name == "alligator"
        }, sort: [sort])
    }
    
    var filteredObjects: [LearningObject] {
        if selectedTags.isEmpty {
            return objects
        } else {
            return objects.filter { object in
                !selectedTags.isDisjoint(with: object.setTags)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Tag Filter Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags) { tag in
                            TagFilterView(tag: tag, isSelected: selectedTags.contains(tag.id)) {
                                if selectedTags.contains(tag.id) {
                                    selectedTags.remove(tag.id)
                                } else {
                                    selectedTags.insert(tag.id)
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

struct TagFilterView: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Text(tag.name)
            .padding(8)
            .background(isSelected ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .onTapGesture {
                action()
            }
    }
}
