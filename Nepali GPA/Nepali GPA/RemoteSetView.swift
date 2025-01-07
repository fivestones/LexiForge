//
//  RemoteSetView.swift
//  Nepali GPA
//
//  Created by David Thomas on 1/7/25.
//

import SwiftUI
import SwiftData

struct RemoteSetView: View {
    @EnvironmentObject private var networkConfig: NetworkConfig
    @Environment(\.modelContext) private var modelContext
    @State private var sets: [String: [RemoteObject]] = [:]
    @State private var isLoading = false
    @State private var downloadProgress: [String: Double] = [:]
    @State private var downloadingSet: String?
    @State private var error: String?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading sets...")
            } else {
                ForEach(Array(sets.keys.sorted()), id: \.self) { setName in
                    Section(header: Text(setName)) {
                        ForEach(sets[setName] ?? [], id: \.id) { object in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(object.name)
                                        .font(.headline)
                                    Text(object.nepaliName)
                                        .font(.subheadline)
                                }
                                Spacer()
                                if let progress = downloadProgress[object.id] {
                                    if progress < 1.0 {
                                        ProgressView(value: progress)
                                            .frame(width: 50)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await downloadSet(setName)
                            }
                        }) {
                            if downloadingSet == setName {
                                HStack {
                                    Text("Downloading...")
                                    ProgressView()
                                }
                            } else {
                                Text("Download Set")
                            }
                        }
                        .disabled(downloadingSet != nil)
                    }
                }
            }
        }
        .navigationTitle("Remote Sets")
        .task {
            await fetchSets()
        }
        .alert("Error", isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK") { error = nil }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }
    
    private func fetchSets() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = networkConfig.getValidURL("api/objects") else {
            self.error = "Invalid server URL"
            return
        }
        
        do {
            print("Creating request for URL: \(url.absoluteString)")
            print("URL scheme: \(url.scheme ?? "no scheme")")
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            
            // Force HTTP
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                self.error = "Invalid URL format"
                return
            }
            var forcedComponents = components
            forcedComponents.scheme = "http"
            
            guard let forcedURL = forcedComponents.url else {
                self.error = "Could not create HTTP URL"
                return
            }
            
            request.url = forcedURL
            print("Final request URL: \(request.url?.absoluteString ?? "none")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Response URL: \(httpResponse.url?.absoluteString ?? "none")")
                print("Response status code: \(httpResponse.statusCode)")
            }
            
            let objects = try JSONDecoder().decode([RemoteObject].self, from: data)
            
            // Group objects by set
            var groupedSets: [String: [RemoteObject]] = [:]
            for object in objects {
                for set in object.sets {
                    var setObjects = groupedSets[set] ?? []
                    setObjects.append(object)
                    groupedSets[set] = setObjects
                }
            }
            
            await MainActor.run {
                sets = groupedSets
            }
        } catch {
            print("Fetch error details:")
            print("Error domain: \((error as NSError).domain)")
            print("Error code: \((error as NSError).code)")
            print("Error description: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("Failed URL: \(urlError.failureURLString ?? "none")")
            }
            self.error = "Failed to fetch sets: \(error.localizedDescription)"
        }
    }
    
    private func downloadSet(_ setName: String) async {
        guard let setObjects = sets[setName] else { return }
        downloadingSet = setName
        defer { downloadingSet = nil }
        
        for object in setObjects {
            // Download each file for the object
            let files = [
                (object.imageName, "image"),
                (object.videoName, "video"),
                (object.thisIsAudioFileName, "thisIs"),
                (object.negativeAudioFileName, "negative"),
                (object.whereIsAudioFileName, "whereIs")
            ]
            
            var downloadedFiles: [String: String] = [:]
            
            for (fileName, fileType) in files {
                guard let fileName = fileName else { continue }
                
                do {
                    guard let url = networkConfig.getValidURL("uploads/\(fileName)") else {
                        throw URLError(.badURL)
                    }
                    let (localURL, progress) = try await downloadFile(from: url, objectId: object.id)
                    
                    // Observe download progress
                    Task {
                        for await currentProgress in progress {
                            await MainActor.run {
                                downloadProgress[object.id] = currentProgress
                            }
                        }
                    }
                    
                    downloadedFiles[fileType] = localURL.lastPathComponent
                } catch {
                    self.error = "Failed to download \(fileType) for \(object.name)"
                    return
                }
            }
            
            // Create local object
            await MainActor.run {
                print("Creating local object with:")
                print("Image name: \(downloadedFiles["image"] ?? "none")")
                print("ThisIs audio: \(downloadedFiles["thisIs"] ?? "none")")
                print("Negative audio: \(downloadedFiles["negative"] ?? "none")")
                print("WhereIs audio: \(downloadedFiles["whereIs"] ?? "none")")
                let categories = object.categories.map { categoryName in
                    getOrCreateCategory(name: categoryName)
                }
                
                let learningObject = LearningObject(
                    id: UUID(uuidString: object.id) ?? UUID(),
                    name: object.name,
                    nepaliName: object.nepaliName,
                    imageName: downloadedFiles["image"],
                    videoName: downloadedFiles["video"],
                    thisIsAudioFileName: downloadedFiles["thisIs"] ?? "",
                    negativeAudioFileName: downloadedFiles["negative"] ?? "",
                    whereIsAudioFileName: downloadedFiles["whereIs"] ?? "",
                    categories: categories
                )

                // Set the setCategories array with the category IDs
                learningObject.setCategories = categories.map { $0.id }

                // Also update the inverse relationship
                for category in categories {
                    if !category.objects.contains(where: { $0.id == learningObject.id }) {
                        category.objects.append(learningObject)
                    }
                }
                
                modelContext.insert(learningObject)
                try? modelContext.save()
                
                downloadProgress[object.id] = 1.0
            }
        }
    }
    
    private func downloadFile(from url: URL, objectId: String) async throws -> (URL, AsyncStream<Double>) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        // Delete existing file if it exists
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        // Create URL request
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        // Download data
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let expectedLength = Int(httpResponse.expectedContentLength)
        var receivedLength = 0
        
        // Create file and get handle
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: destination)
        
        // Create progress stream
        let progress = AsyncStream<Double> { continuation in
            Task {
                do {
                    for try await byte in asyncBytes {
                        try fileHandle.write(contentsOf: [byte])
                        receivedLength += 1
                        let progress = Double(receivedLength) / Double(expectedLength)
                        continuation.yield(progress)
                    }
                    try fileHandle.close()
                    continuation.finish()
                } catch {
                    print("Error writing file: \(error)")
                    try? fileHandle.close()
                    continuation.finish()
                }
            }
        }
        
        return (destination, progress)
    }
    
    private func getOrCreateCategory(name: String) -> Category {
        let fetchDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.name == name }
        )
        
        if let existingCategory = try? modelContext.fetch(fetchDescriptor).first {
            return existingCategory
        }
        
        let newCategory = Category(name: name, objects: [])
        modelContext.insert(newCategory)
        return newCategory
    }
}
