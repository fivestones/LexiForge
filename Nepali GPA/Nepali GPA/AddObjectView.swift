import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI

struct AddObjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @State private var name = ""
    @State private var nepaliName = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedVideoData: Data?
    @State private var isRecording = false
    @State private var thisIsAudioURL: URL?
    @State private var negativeAudioURL: URL?
    @State private var whereIsAudioURL: URL?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var currentRecordingType: RecordingType?
    @State private var selectedCategories: Set<UUID> = []
    @State private var newCategoryName: String = ""

    enum RecordingType {
        case thisIs, negative, whereIs
    }

    var body: some View {
        Form {
            // Basic Information section remains the same
            Section(header: Text("Basic Information")) {
                TextField("Name (English)", text: $name)
                TextField("Name (Nepali)", text: $nepaliName)
            }

            // Image/Video section remains the same
            Section(header: Text("Image or Video")) {
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    Text("Select Image or Video")
                }
                if let selectedImageData,
                   let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                if let selectedVideoData,
                   let previewImage = generateVideoThumbnail(videoData: selectedVideoData) {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .overlay(Image(systemName: "play.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white))
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if isImage(data: data) {
                            selectedImageData = data
                            selectedVideoData = nil
                        } else {
                            selectedVideoData = data
                            selectedImageData = nil
                        }
                    }
                }
            }

            // Audio Recordings section remains the same
            Section(header: Text("Audio Recordings")) {
                recordButton(for: .thisIs, label: "This is...")
                recordButton(for: .negative, label: "Negative response")
                recordButton(for: .whereIs, label: "Where is...")
            }

            Section(header: Text("Categories")) {
                List {
                    ForEach(categories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            if selectedCategories.contains(category.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCategories.contains(category.id) {
                                selectedCategories.remove(category.id)
                            } else {
                                selectedCategories.insert(category.id)
                            }
                        }
                    }
                }

                HStack {
                    TextField("New Category", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: addCategory) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .padding()
                    }
                }
            }

            Button("Save Object") {
                saveObject()
            }
        }
        .navigationTitle("Add New Object")
    }

    func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        let newCategory = Category(name: newCategoryName, objects: [])
        modelContext.insert(newCategory)
        try? modelContext.save()
        newCategoryName = ""
    }

    func recordButton(for type: RecordingType, label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording(for: type)
                }
            }) {
                Image(systemName: isRecording && currentRecordingType == type ? "stop.circle" : "mic")
            }
            if let url = audioURL(for: type) {
                Button(action: {
                    playRecording(url: url)
                }) {
                    Image(systemName: "play.circle")
                }
            }
        }
    }

    func startRecording(for type: RecordingType) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            print("Audio session set for recording")

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("\(type).m4a")

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()

            isRecording = true
            currentRecordingType = type
            print("Started recording for type: \(type) at \(audioFilename.path)")
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false

        if let type = currentRecordingType {
            switch type {
            case .thisIs:
                thisIsAudioURL = audioRecorder?.url
            case .negative:
                negativeAudioURL = audioRecorder?.url
            case .whereIs:
                whereIsAudioURL = audioRecorder?.url
            }
            print("Stopped recording for type: \(type) at \(audioRecorder?.url.path ?? "unknown location")")
        }

        currentRecordingType = nil

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated after recording in stopRecording")
        } catch {
            print("Failed to deactivate AVAudioSession in stopRecording: \(error)")
        }
    }

    func playRecording(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch {
            print("Could not play recording")
        }
    }

    func audioURL(for type: RecordingType) -> URL? {
        switch type {
        case .thisIs:
            return thisIsAudioURL
        case .negative:
            return negativeAudioURL
        case .whereIs:
            return whereIsAudioURL
        }
    }

    func saveObject() {
        guard !name.isEmpty, !nepaliName.isEmpty,
              let thisIsAudioURL = thisIsAudioURL,
              let negativeAudioURL = negativeAudioURL,
              let whereIsAudioURL = whereIsAudioURL else {
            print("Missing required information")
            return
        }

        let id = UUID()
        let selectedCategoryObjects = categories.filter { selectedCategories.contains($0.id) }

        let newObject = LearningObject(
            id: id,
            name: name,
            nepaliName: nepaliName,
            imageName: selectedImageData != nil ? "\(id.uuidString).jpg" : nil,
            videoName: selectedVideoData != nil ? "\(id.uuidString).mp4" : nil,
            thisIsAudioFileName: "\(id.uuidString)_thisIs.m4a",
            negativeAudioFileName: "\(id.uuidString)_negative.m4a",
            whereIsAudioFileName: "\(id.uuidString)_whereIs.m4a",
            setCategories: Array(selectedCategories),
            categories: selectedCategoryObjects
        )

        modelContext.insert(newObject)

        // Save media files
        if let imageData = selectedImageData {
            saveMedia(data: imageData, name: "\(id.uuidString).jpg")
        } else if let videoData = selectedVideoData {
            saveMedia(data: videoData, name: "\(id.uuidString).mp4")
        }

        // Move audio files
        moveAudioFile(from: thisIsAudioURL, to: "\(id.uuidString)_thisIs.m4a")
        moveAudioFile(from: negativeAudioURL, to: "\(id.uuidString)_negative.m4a")
        moveAudioFile(from: whereIsAudioURL, to: "\(id.uuidString)_whereIs.m4a")

        dismiss()
    }

    func saveMedia(data: Data, name: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(name)
        do {
            try data.write(to: fileURL)
        } catch {
            print("Error saving media: \(error)")
        }
    }

    func moveAudioFile(from sourceURL: URL, to destinationName: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent(destinationName)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
        } catch {
            print("Error moving audio file: \(error)")
        }
    }

    func isImage(data: Data) -> Bool {
        let header = data.prefix(8)
        let jpgHeader = Data([0xFF, 0xD8, 0xFF])
        let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        return header.starts(with: jpgHeader) || header.starts(with: pngHeader)
    }

    func generateVideoThumbnail(videoData: Data) -> UIImage? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempVideo.mp4")
        do {
            try videoData.write(to: tempURL)
            let asset = AVAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
}
