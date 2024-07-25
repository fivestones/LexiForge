import SwiftUI
import SwiftData

struct TagListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    @State private var newTagName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(tags) { tag in
                        Text(tag.name)
                    }
                    .onDelete(perform: deleteTags)
                }

                HStack {
                    TextField("New Tag", text: $newTagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: addTag) {
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
    }

    private func addTag() {
        guard !newTagName.isEmpty else { return }
        let newTag = Tag(name: newTagName)
        modelContext.insert(newTag)
        try? modelContext.save()
        newTagName = ""
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = tags[index]
            modelContext.delete(tag)
        }
        try? modelContext.save()
    }
}
