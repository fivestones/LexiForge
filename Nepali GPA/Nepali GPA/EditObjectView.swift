import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI

struct EditObjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var object: LearningObject
    @Query private var tags: [Tag]
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedVideoData: Data?
    @State private var isRecording = false
    @State private var thisIsAudioURL: URL?
    @State private var negativeAudioURL: URL?
    @State private var whereIsAudioURL: URL?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var currentRecordingType: RecordingType?
    @State private var selectedTags: Set<UUID>
    @State private var newTagName: String = ""

    enum RecordingType {
        case thisIs, negative, whereIs
    }

    init(object: Binding<LearningObject>) {
        _object = object
        _selectedTags = State(initialValue: Set(object.wrappedValue.setTags))
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Information")) {
                TextField("Name (English)", text: $object.name)
                TextField("Name (Nepali)", text: $object.nepaliName)
            }

            Section(header: Text("Image or Video")) {
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    Text("Select Image or Video")
                }
                if let selectedImageData,
                   let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else if let imageName = object.imageName,
                          let uiImage = loadImage(named: imageName) {
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
                } else if let videoName = object.videoName,
                          let previewImage = generateVideoThumbnail(videoName: videoName) {
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

            Section(header: Text("Audio Recordings")) {
                recordButton(for: .thisIs, label: "This is...", url: $thisIsAudioURL, existingFileName: object.thisIsAudioFileName)
                recordButton(for: .negative, label: "Negative response", url: $negativeAudioURL, existingFileName: object.negativeAudioFileName)
                recordButton(for: .whereIs, label: "Where is...", url: $whereIsAudioURL, existingFileName: object.whereIsAudioFileName)
            }

            Section(header: Text("Tags")) {
                List {
                    ForEach(tags) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if selectedTags.contains(tag.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTags.contains(tag.id) {
                                selectedTags.remove(tag.id)
                            } else {
                                selectedTags.insert(tag.id)
                            }
                        }
                    }
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
            }

            Button("Save Object") {
                saveObject()
            }
        }
        .navigationTitle("Edit Object")
    }

    func addTag() {
        guard !newTagName.isEmpty else { return }
        let newTag = Tag(name: newTagName, objects: [])
        modelContext.insert(newTag)
        try? modelContext.save()
        newTagName = ""
    }

    func recordButton(for type: RecordingType, label: String, url: Binding<URL?>, existingFileName: String) -> some View {
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
            if let fileURL = url.wrappedValue {
                Button(action: {
                    playRecording(url: fileURL)
                }) {
                    Image(systemName: "play.circle")
                }
            } else if let existingURL = getDocumentDirectoryURL(for: existingFileName) {
                Button(action: {
                    playRecording(url: existingURL)
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
        object.setTags = Array(selectedTags)

        if let selectedImageData {
            saveMedia(data: selectedImageData, name: "\(object.id.uuidString).jpg")
            object.imageName = "\(object.id.uuidString).jpg"
        } else if let selectedVideoData {
            saveMedia(data: selectedVideoData, name: "\(object.id.uuidString).mp4")
            object.videoName = "\(object.id.uuidString).mp4"
        }

        if let thisIsAudioURL {
            moveAudioFile(from: thisIsAudioURL, to: "\(object.id.uuidString)_thisIs.m4a")
            object.thisIsAudioFileName = "\(object.id.uuidString)_thisIs.m4a"
        }
        if let negativeAudioURL {
            moveAudioFile(from: negativeAudioURL, to: "\(object.id.uuidString)_negative.m4a")
            object.negativeAudioFileName = "\(object.id.uuidString)_negative.m4a"
        }
        if let whereIsAudioURL {
            moveAudioFile(from: whereIsAudioURL, to: "\(object.id.uuidString)_whereIs.m4a")
            object.whereIsAudioFileName = "\(object.id.uuidString)_whereIs.m4a"
        }

        try? modelContext.save()
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

    func generateVideoThumbnail(videoName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoURL = documentsDirectory.appendingPathComponent(videoName)
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }

    func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(named)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }

    func getDocumentDirectoryURL(for fileName: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}
