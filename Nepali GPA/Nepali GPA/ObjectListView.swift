import SwiftUI
import SwiftData

struct ObjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var objects: [LearningObject]
    @Query private var tags: [Tag]
    @State private var selectedTags: Set<UUID> = []

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
        NavigationView {
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
                        NavigationLink(destination: EditObjectView(object: .constant(object))) {
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

                // Add Object Button
                NavigationLink(destination: AddObjectView()) {
                    Text("Add New Object")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Objects")
            .toolbar {
                EditButton()
            }
        }
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
