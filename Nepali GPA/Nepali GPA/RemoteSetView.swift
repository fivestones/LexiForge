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
    
    // Configure URLSession for optimal performance
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 5  // Allow multiple concurrent connections
        config.timeoutIntervalForResource = 60    // Longer timeout for large files
        config.waitsForConnectivity = true        // Auto-retry on connection issues
        return URLSession(configuration: config)
    }()
    
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

    private func downloadSet(_ setName: String) async {
        guard let setObjects = sets[setName] else { return }
        downloadingSet = setName
        defer { downloadingSet = nil }

        // Create a task group for parallel downloads
        await withTaskGroup(of: (RemoteObject, [String: String])?.self) { group in
            for object in setObjects {
                group.addTask {
                    do {
                        // Download all files for this object
                        let downloadedFiles = try await downloadObjectFiles(object)
                        return (object, downloadedFiles)
                    } catch {
                        print("Error downloading files for object \(object.id): \(error)")
                        return nil
                    }
                }
            }

            // Process completed downloads and create local objects
            for await result in group {
                guard let (object, downloadedFiles) = result else { continue }
                
                await MainActor.run {
                    createLocalObject(from: object, with: downloadedFiles)
                }
            }
        }
    }

    private func downloadObjectFiles(_ object: RemoteObject) async throws -> [String: String] {
        var downloadedFiles: [String: String] = [:]
        
        // Create parallel tasks for each file download
        async let imageDownload: String? = downloadFile(
            fileName: object.imageName,
            objectId: object.id,
            fileType: "image"
        )
        
        async let videoDownload: String? = downloadFile(
            fileName: object.videoName,
            objectId: object.id,
            fileType: "video"
        )
        
        async let thisIsAudioDownload: String? = downloadFile(
            fileName: object.thisIsAudioFileName,
            objectId: object.id,
            fileType: "thisIs"
        )
        
        async let negativeAudioDownload: String? = downloadFile(
            fileName: object.negativeAudioFileName,
            objectId: object.id,
            fileType: "negative"
        )
        
        async let whereIsAudioDownload: String? = downloadFile(
            fileName: object.whereIsAudioFileName,
            objectId: object.id,
            fileType: "whereIs"
        )

        // Await all downloads simultaneously
        let results = await [
            "image": imageDownload,
            "video": videoDownload,
            "thisIs": thisIsAudioDownload,
            "negative": negativeAudioDownload,
            "whereIs": whereIsAudioDownload
        ]
        
        // Filter out nil results and add to downloadedFiles
        for (key, value) in results {
            if let fileName = value {
                downloadedFiles[key] = fileName
            }
        }
        
        return downloadedFiles
    }

    private func downloadFile(fileName: String?, objectId: String, fileType: String) async throws -> String? {
        guard let fileName = fileName else { return nil }
        
        guard let url = networkConfig.getValidURL("uploads/\(fileName)") else {
            throw URLError(.badURL)
        }

        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Generate destination filename
        let destinationFileName = "\(objectId)-\(fileName)"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documentsDirectory.appendingPathComponent(destinationFileName)

        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        // Write the entire file at once
        try data.write(to: destination)
        
        // Update progress on main thread
        await MainActor.run {
            downloadProgress[objectId] = 1.0
        }

        return destinationFileName
    }

    private func createLocalObject(from remoteObject: RemoteObject, with files: [String: String]) {
        let categories = remoteObject.categories.map { categoryName in
            getOrCreateCategory(name: categoryName)
        }
        
        let learningObject = LearningObject(
            id: UUID(uuidString: remoteObject.id) ?? UUID(),
            name: remoteObject.name,
            nepaliName: remoteObject.nepaliName,
            imageName: files["image"],
            videoName: files["video"],
            thisIsAudioFileName: files["thisIs"] ?? "",
            negativeAudioFileName: files["negative"] ?? "",
            whereIsAudioFileName: files["whereIs"] ?? "",
            categories: categories
        )

        // Set the setCategories array with the category IDs
        learningObject.setCategories = categories.map { $0.id }

        // Update the inverse relationship
        for category in categories {
            if !category.objects.contains(where: { $0.id == learningObject.id }) {
                category.objects.append(learningObject)
            }
        }
        
        modelContext.insert(learningObject)
        try? modelContext.save()
        
        downloadProgress[remoteObject.id] = 1.0
    }

    // Rest of the code remains the same...
    private func fetchSets() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = networkConfig.getValidURL("api/objects") else {
            self.error = "Invalid server URL"
            return
        }
        
        do {
            let request = URLRequest(url: url)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let objects = try JSONDecoder().decode([RemoteObject].self, from: data)
            
            await MainActor.run {
                // Group objects by set
                var groupedSets: [String: [RemoteObject]] = [:]
                for object in objects {
                    for set in object.sets {
                        var setObjects = groupedSets[set] ?? []
                        setObjects.append(object)
                        groupedSets[set] = setObjects
                    }
                }
                sets = groupedSets
            }
        } catch {
            self.error = "Failed to fetch sets: \(error.localizedDescription)"
        }
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
