import SwiftUI
import SwiftData
import AVFoundation

@MainActor
class LearningViewModel: ObservableObject {
    @Published var currentObjects: [LearningObject] = []
    @Published var allObjects: [LearningObject] = []
    @Published var currentPrompt: String = ""
    @Published var highlightedObject: LearningObject?
    @Published var highlightedCorrectObject: LearningObject?
    @Published var introducingObject: LearningObject?
    @Published var introductionFinished: LearningObject?
    @Published var targetWord: String?
    @Published var attempts: Int = 0
    @Published var grayedOutObjects: [LearningObject] = []
    @Published var correctAnswerObjectWasSelected: LearningObject?
    @Published var isAutoMode: Bool = false
    @Published var autoModeStep: Int = 0
    @Published var isQuestionAudioPlaying: Bool = false
    @Published var currentQuestionObject: LearningObject? = nil
    @Published var currentIntroductionObject: LearningObject? = nil
    @Published var genericAudioFiles: [GenericAudioFile] = []
    @Published var currentTag: Tag?
    
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAllObjects()
        loadGenericAudioFiles()
        copyGenericAudioFilesIfNeeded()
        printDocumentsDirectoryPath()
        listDocumentsDirectoryContents()
    }

    
    private func loadGenericAudioFiles() {
        let descriptor = FetchDescriptor<GenericAudioFile>(sortBy: [SortDescriptor(\.fileName)])
        do {
            genericAudioFiles = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch GenericAudioFiles: \(error)")
        }
    }

    private func getPositiveFeedbackAudioFileName() -> String? {
        return genericAudioFiles.randomElement()?.fileName
    }

    // A function called printDocumentsDirectory to print the documents directory path
    func printDocumentsDirectory() {
        print("Documents directory: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)")
    }
    
    private func printDocumentsDirectoryPath() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents Directory: \(documentsDirectory.path)")
    }

    private func listDocumentsDirectoryContents() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                print("File: \(fileURL.lastPathComponent)")
            }
        } catch {
            print("Error while listing files in documents directory: \(error)")
        }
    }

    private func copyGenericAudioFilesIfNeeded() {
        let genericAudioFiles = ["sha_bas.m4a"] // Add more files here as needed

        for audioFile in genericAudioFiles {
            if !isFileInDocumentsDirectory(fileName: audioFile) {
                if resourceExists(resourceName: audioFile) {
                    let newFileName = copyResourceToDocumentsDirectory(resourceName: audioFile, for: UUID())
                    saveGenericAudioFile(name: newFileName)
                    print("Copied audio file \(audioFile) to documents directory")
                } else {
                    print("Generic audio resource not found: \(audioFile)")
                }
            }
        }
    }

    private func saveGenericAudioFile(name: String) {
        let genericAudioFile = GenericAudioFile(fileName: name)
        modelContext.insert(genericAudioFile)
        genericAudioFiles.append(genericAudioFile)
        try? modelContext.save()
    }

    private func isFileInDocumentsDirectory(fileName: String) -> Bool {
        let fileURL = getDocumentDirectoryURL(for: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func getGenericAudioFile(named: String) -> String? {
        return genericAudioFiles.first { $0.fileName.contains(named) }?.fileName
    }


    
    public func loadAllObjects() {
        let descriptor = FetchDescriptor<LearningObject>(sortBy: [SortDescriptor(\.name)])
        do {
            allObjects = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch LearningObjects: \(error)")
        }
    }
    
    public func performInitialSetup() {
            let defaults = UserDefaults.standard
            let isFirstLaunch = !defaults.bool(forKey: "hasLaunchedBefore")
            
            if isFirstLaunch {
                // add initial objects
                addInitialObjectsIfNeeded()
                
                // Set the flag to indicate the app has been launched before
                defaults.set(true, forKey: "hasLaunchedBefore")
            } else {
                print("Not first launch, skipping initial setup")
            }
        }

    private func addInitialObjectsIfNeeded() {
        // First, ensure the 'animals' tag exists
        let animalTag: Tag
        let fetchRequest = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == "animals" })
        
        do {
            if let existingTag = try modelContext.fetch(fetchRequest).first {
                animalTag = existingTag
                print("Using existing 'animals' tag")
            } else {
                animalTag = Tag(name: "animals", objects: [])
                modelContext.insert(animalTag)
                print("Created new 'animals' tag")
            }
        } catch {
            print("Error fetching 'animals' tag: \(error)")
            // Create a new tag if we couldn't fetch existing ones
            animalTag = Tag(name: "animals", objects: [])
            modelContext.insert(animalTag)
            print("Created new 'animals' tag after fetch error")
        }
        
        let initialObjects = [
            LearningObject(id: UUID(), name: "horse", nepaliName: "घोडा", imageName: nil, videoName: "horse.mp4", thisIsAudioFileName: "this_is_a-horse.m4a", negativeAudioFileName: "negative_response_horse.m4a", whereIsAudioFileName: "where_is_horse.m4a", tags: []),
            LearningObject(id: UUID(), name: "cow", nepaliName: "गाई", imageName: "cow.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-cow.m4a", negativeAudioFileName: "negative_response_cow.m4a", whereIsAudioFileName: "where_is_cow.m4a", tags: []),
            LearningObject(id: UUID(), name: "sheep", nepaliName: "भेंडा", imageName: "sheep.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-sheep.m4a", negativeAudioFileName: "negative_response_sheep.m4a", whereIsAudioFileName: "where_is_sheep.m4a", tags: []),
            LearningObject(id: UUID(), name: "goat", nepaliName: "बाख्रा", imageName: "goat.jpg", videoName: "goat.mp4", thisIsAudioFileName: "this_is_a-goat.m4a", negativeAudioFileName: "negative_response_goat.m4a", whereIsAudioFileName: "where_is_goat.m4a", tags: []),
            LearningObject(id: UUID(), name: "dog", nepaliName: "कुकुर", imageName: "dog.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-dog.m4a", negativeAudioFileName: "negative_response_dog.m4a", whereIsAudioFileName: "where_is_dog.m4a", tags: []),
            LearningObject(id: UUID(), name: "cat", nepaliName: "बिरालो", imageName: "cat.jpg", videoName: "cat.mp4", thisIsAudioFileName: "this_is_a-cat.m4a", negativeAudioFileName: "negative_response_cat.m4a", whereIsAudioFileName: "where_is_cat.m4a", tags: []),
            LearningObject(id: UUID(), name: "tiger", nepaliName: "बाघ", imageName: "tiger.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-tiger.m4a", negativeAudioFileName: "negative_response_tiger.m4a", whereIsAudioFileName: "where_is_tiger.m4a", tags: []),
            LearningObject(id: UUID(), name: "rhinoceros", nepaliName: "गैडा", imageName: "rhinoceros.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-rhinoceros.m4a", negativeAudioFileName: "negative_response_rhinoceros.m4a", whereIsAudioFileName: "where_is_rhinoceros.m4a", tags: []),
            LearningObject(id: UUID(), name: "buffalo", nepaliName: "भैंसी", imageName: "buffalo.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-buffalo.m4a", negativeAudioFileName: "negative_response_buffalo.m4a", whereIsAudioFileName: "where_is_buffalo.m4a", tags: []),
            LearningObject(id: UUID(), name: "pig", nepaliName: "सुँगुर", imageName: "pig.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-pig.m4a", negativeAudioFileName: "negative_response_pig.m4a", whereIsAudioFileName: "where_is_pig.m4a", tags: []),
            LearningObject(id: UUID(), name: "deer", nepaliName: "हिरण", imageName: "deer.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-deer.m4a", negativeAudioFileName: "negative_response_deer.m4a", whereIsAudioFileName: "where_is_deer.m4a", tags: []),
            LearningObject(id: UUID(), name: "alligator", nepaliName: "गोही", imageName: "alligator.jpg", videoName: nil, thisIsAudioFileName: "this_is_a-alligator.m4a", negativeAudioFileName: "negative_response_alligator.m4a", whereIsAudioFileName: "where_is_alligator.m4a", tags: [])
        ]

        for var object in initialObjects {
            // Check if the object already exists in the database
            if !allObjects.contains(where: { $0.name == object.name }) {
                if let imageName = object.imageName {
                    if resourceExists(resourceName: imageName) {
                        let newImageName = copyResourceToDocumentsDirectory(resourceName: imageName, for: object.id)
                        object.imageName = newImageName
                        print("Updated image name: \(newImageName)")
                    } else {
                        print("Image resource not found: \(imageName)")
                    }
                }
                if let videoName = object.videoName {
                    if resourceExists(resourceName: videoName) {
                        let newVideoName = copyResourceToDocumentsDirectory(resourceName: videoName, for: object.id)
                        object.videoName = newVideoName
                        print("Updated video name: \(newVideoName)")
                    } else {
                        print("Video resource not found: \(videoName)")
                    }
                }
                object.thisIsAudioFileName = copyResourceToDocumentsDirectory(resourceName: object.thisIsAudioFileName, for: object.id)
                object.negativeAudioFileName = copyResourceToDocumentsDirectory(resourceName: object.negativeAudioFileName, for: object.id)
                object.whereIsAudioFileName = copyResourceToDocumentsDirectory(resourceName: object.whereIsAudioFileName, for: object.id)
                
                // Add the 'animals' tag to the object
                object.setTags.append(animalTag.id)
                
                modelContext.insert(object)
                print("Added new object: \(object.name) with 'animals' tag")
            } else {
                // If the object already exists, ensure it has the 'animals' tag
                if let existingObject = allObjects.first(where: { $0.name == object.name }) {
                    if !existingObject.setTags.contains(animalTag.id) {
                        existingObject.setTags.append(animalTag.id)
                        print("Added 'animals' tag to existing object: \(existingObject.name)")
                    } else {
                        print("Object already exists with 'animals' tag: \(object.name)")
                    }
                }
            }
        }

        do {
            try modelContext.save()
            loadAllObjects() // Reload all objects after adding
        } catch {
            print("Failed to save initial objects: \(error)")
        }
    }
    
    private func resourceExists(resourceName: String) -> Bool {
        if let resourceURL = Bundle.main.url(forResource: resourceName, withExtension: nil) {
            print("Resource found: \(resourceURL.path)")
            return true
        } else {
            print("Resource not found: \(resourceName)")
            return false
        }
    }

    
    private func copyResourceToDocumentsDirectory(resourceName: String, for id: UUID) -> String {
        // Print all resources in the main bundle
        if let resourcePath = Bundle.main.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            do {
                let resources = try FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
//                print("Available resources in bundle:")
//                for resource in resources {
//                    print(resource.lastPathComponent)
//                }
            } catch {
                print("Error while listing resources in bundle: \(error)")
            }
        }
        
        guard let resourceURL = Bundle.main.url(forResource: resourceName, withExtension: nil) else {
            fatalError("Resource not found: \(resourceName)")
        }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent("\(id.uuidString)_\(resourceName)")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                print("Removed existing file at destination: \(destinationURL.path)")
            }
            try FileManager.default.copyItem(at: resourceURL, to: destinationURL)
            print("Copied \(resourceName) to documents directory with name: \(destinationURL.lastPathComponent)")
        } catch {
            fatalError("Failed to copy resource to documents directory: \(error)")
        }

        return destinationURL.lastPathComponent
    }
    
    private func loadObjects() {
        let descriptor = FetchDescriptor<LearningObject>(sortBy: [SortDescriptor(\.name)])
        do {
            currentObjects = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch LearningObjects: \(error)")
        }
    }
    
    func addObject(_ object: LearningObject) {
        modelContext.insert(object)
        currentObjects.append(object)
    }
    
    func deleteObject(_ object: LearningObject) {
        modelContext.delete(object)
        if let index = currentObjects.firstIndex(where: { $0.id == object.id }) {
            currentObjects.remove(at: index)
        }
    }

    var currentAudioPlayer: AVAudioPlayer?
    var audioQueuePlayer: AVQueuePlayer?
    var continuePlaying = true

    func introduceNextObject(completion: @escaping () -> Void) {
        print("in introduceNextObject, stopping current audio")
        stopCurrentAudio()
        if currentObjects.count < allObjects.count {
            let newObject = allObjects[currentObjects.count]
            newObject.introducedHistory = Date()
            currentObjects.append(newObject)
            self.introducingObject = currentObjects.last
            currentIntroductionObject = currentObjects.last
            currentPrompt = "यो \(newObject.nepaliName) हो।"
            playSoundsSequentially(sounds: [newObject.thisIsAudioFileName], type: "m4a", completion: {
                self.introducingObject = nil
                completion()
            })
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save after introducing new object: \(error)")
            }
        } else {
            completion()
        }
    }

    
    func askQuestion(completion: @escaping () -> Void) {
        if isQuestionAudioPlaying {
            // If the question audio is playing, do nothing
            print("question audio is still playing, so not asking another question")
            return
        }
        stopCurrentAudio()
        currentIntroductionObject = nil
        guard !currentObjects.isEmpty else { return }
        
        if let currentQuestionObject = currentQuestionObject {
            // If there is a current question object and audio has finished, repeat the question audio
            print("There is a currentQuestionObject, so just repeating the question")
            currentPrompt = "\(currentQuestionObject.nepaliName) कहाँ छ?"
            isQuestionAudioPlaying = true
            playSoundsSequentially(sounds: [currentQuestionObject.whereIsAudioFileName], type: "m4a", completion:  {
                self.isQuestionAudioPlaying = false
                print("set isQuestionAudioPlaying to false after repeat question")
                completion()
            })
            return
        } else {
            print("there is not a currentQuestionObject, so will ask a new question")
        }
        
        // Select a new question if no currentQuestionObject
        let selectedObject = selectNextObjectToAsk()
        currentPrompt = "\(selectedObject.nepaliName) कहाँ छ?"
        targetWord = selectedObject.nepaliName
        attempts = 0 // Reset the attempt counter
        recordAskedInteraction(for: selectedObject)
        updateQuestionHistory(for: selectedObject)
        
        currentQuestionObject = selectedObject // Set the current question object
        isQuestionAudioPlaying = true
        playSoundsSequentially(sounds: [selectedObject.whereIsAudioFileName], type: "m4a", completion:  {
            self.isQuestionAudioPlaying = false
            print("set isQuestionAudioPlaying to false after new question")
            
            completion()
        })
    }
    
    func continueAutoMode() {
        if (currentObjects.count == 1 && autoModeStep == 0) {
            // There was already one object and we are just starting autoMode for the first time, so setting autoModeStep to 1
            autoModeStep = 1
        }
        if (currentObjects.count > 1 && autoModeStep == 0) {
            // There were already two object and we are just starting autoMode for the first time, so setting autoModeStep to 2
            autoModeStep = 2
        }
        switch autoModeStep {
        case 0:
            print("we are in autoModeStep 0, about to go to introduceNextObject")
            introduceNextObject {
                self.autoModeStep += 1
//                print("audoModeStep: \(self.autoModeStep)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.introduceNextObject {
                        self.autoModeStep += 1
                        self.continueAutoMode()
                    }
                }
            }
        case 1:
            // We got here because there was already one object but not two
            print("we are in autoModeStep 1, about to go to introduceNextObject")
            self.introduceNextObject {
                self.autoModeStep += 1
                self.continueAutoMode()
            }
        case let x where x > 1:
            if checkCompetency() {
                print("we are in autoModeStep > 1, and checkCompetency was true, about to go to introduceNextObject")
                introduceNextObject {
                    self.autoModeStep += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.continueAutoMode()
                    }
                }
            } else {
                askQuestion {
                    self.autoModeStep += 1
                    //self.continueAutoMode()
                }
            }
        default:
            break
        }
    }

    func checkCompetency() -> Bool {
//        print("Checking competency")
        // Create a mutable copy of currentObjects to work with
        var mutableCurrentObjects = currentObjects

        // Check if all objects have a raw competency factor of at least 400
        let allObjectsCompetent = mutableCurrentObjects.allSatisfy {
            var object = $0
            return object.calculateLearnerCompetencyScore() >= 400
        }
//        print("allObjectsCompetent: \(allObjectsCompetent)")

        // Check if the most recent object was answered correctly the last two times
        guard let lastIntroducedObject = mutableCurrentObjects.last else { return false }
        let lastTwoInteractions = lastIntroducedObject.history.suffix(2)
        let lastTwoCorrect = lastTwoInteractions.count == 2 && lastTwoInteractions.allSatisfy { $0.type == .answeredCorrectly }
//        print("lastTwoCorrect: \(lastTwoCorrect)")
        
        // Check if at least 90% of the objects have been asked about at least once since the last object was introduced
        let objectsAskedSinceLast = mutableCurrentObjects.filter {
            var object = $0
            return object.askedHistory.last ?? Date.distantPast > (lastIntroducedObject.introducedHistory ?? Date.distantPast)
        }
//        print("objectsAskedSinceLast: \(objectsAskedSinceLast.count)")
//        print("currentObjects: \(currentObjects.count)")
        let ninetyPercentAsked = Double(objectsAskedSinceLast.count) / Double(mutableCurrentObjects.count) >= 0.9
//        print("ninetyPercentAsked: \(ninetyPercentAsked)")
        
        return allObjectsCompetent && lastTwoCorrect && ninetyPercentAsked
    }
    
    func replayCurrentPrompt() {
        if currentQuestionObject != nil {
            // There is a current question, so play it.
            askQuestion(completion: {})
        } else if currentIntroductionObject != nil {
            if let lastObject = currentObjects.last {
                playSoundsSequentially(sounds: [lastObject.thisIsAudioFileName], type: "m4a", completion:  {
                    self.introducingObject = nil
                })
            }
        }
    }
    
    func checkAnswer(selectedObject: LearningObject) {
        stopCurrentAudio()
        print("Checking answer for: \(selectedObject.name)")
        guard let targetName = targetWord else {
            print("No target word set")
            if (isAutoMode) {
                continueAutoMode()
            }
            return
        }
        print("Target name: \(targetName)")
        if let correctObject = currentObjects.first(where: { $0.nepaliName == targetName }) {
    //            print("Correct object: \(correctObject.nepaliName)")
            if selectedObject.name == correctObject.name {
                print("Correct answer selected")
                currentPrompt = "शाबास"
                targetWord = nil
                currentQuestionObject = nil // Reset the current question object
                print("in checkAnswer, got it right. currentQuestionObject reset to \(currentQuestionObject)")
                recordInteraction(for: correctObject, type: .answeredCorrectly)
                attempts = 0 // Reset attempts after a correct answer
                correctAnswerObjectWasSelected = correctObject // Set the correct answer object
                if let feedbackFileName = getPositiveFeedbackAudioFileName() {
                    playSoundsSequentially(
                        sounds: [feedbackFileName],
                        type: "m4a",
                        objects: [],
                        firstItemCompletion: { [weak self] in
                            // Restore all grayed out objects
                            self?.grayedOutObjects.removeAll()
                            self?.correctAnswerObjectWasSelected = nil // Reset the correct answer object after playback
                            if self?.isAutoMode == true {
                                self?.continueAutoMode()
                            }
                        }
                    )
                }
            } else {
                print("Incorrect answer selected")
                attempts += 1 // Increment the attempt counter
                currentPrompt = "होइन, त्यो \(selectedObject.nepaliName) हो। \(correctObject.nepaliName) कहाँ छ?"
                recordInteraction(for: selectedObject, type: .answeredIncorrectly)
                recordInteraction(for: correctObject, type: .objectNotKnown) // Record object not known for the correct object
                targetWord = correctObject.nepaliName

                playSoundsSequentially(
                    sounds: [selectedObject.negativeAudioFileName, correctObject.whereIsAudioFileName],
                    type: "m4a",
                    objects: [selectedObject, nil],
                    firstItemCompletion: { [weak self] in
                        // After playing the incorrect feedback audio, gray out objects if attempts > 3
                        if let attempts = self?.attempts, attempts > 3 {
                            if attempts == 4 {
                                self?.grayOutHalfObjects(except: correctObject)
                            } else if attempts == 6 {
                                self?.grayOutAllButTwoObjects(except: correctObject)
                            }
                        }
                    }
                )
            }
        } else {
            print("No matching object found for target name: \(targetName)")
        }
    }
    
    func shuffleCurrentObjects() {
        currentObjects.shuffle()
    }
    
    private func recordInteraction(for object: LearningObject, type: Interaction.InteractionType) {
        let attempts = (type == .answeredCorrectly) ? self.attempts + 1 : self.attempts
        let interaction = Interaction(date: Date(), type: type, attempts: attempts)
        object.history.append(interaction)
        try? modelContext.save()
    }
    
    private func recordAskedInteraction(for object: LearningObject) {
        object.askedHistory.append(Date())
        try? modelContext.save()
    }

    private func updateQuestionHistory(for selectedObject: LearningObject) {
        for object in currentObjects {
            if object.id == selectedObject.id {
                object.questionHistory = 0
            } else if let history = object.questionHistory {
                object.questionHistory = history + 1
            }
        }
        try? modelContext.save()
    }

    private func selectNextObjectToAsk() -> LearningObject {
        let highestQuestionHistory = currentObjects.compactMap { $0.questionHistory }.max() ?? 0

        var scores: [(object: LearningObject, score: Double)] = []

        // Calculate learner competency scores
        var rawCompetencyScores: [Double] = []
//        print("*********")
//        print("Learner competency scores calculation time")
        for var object in currentObjects {
//            print("Calculating score for \(object.name)")
            let score = object.calculateLearnerCompetencyScore()
            rawCompetencyScores.append(score)
        }
//        print("*********")
        let maxCompetencyScore = rawCompetencyScores.max() ?? 180.0 // Ensure there's a max score to avoid division by zero
        let normalizedCompetencyScores = rawCompetencyScores.map { $0 / maxCompetencyScore }
        let invertedCompetencyScores = normalizedCompetencyScores.map { 1.0 - $0 }
        let scaledCompetencyScores = invertedCompetencyScores.map { $0 * 0.5 }

        for (index, object) in currentObjects.enumerated() {
            var score = 0.0

            // Factor 1: Question history (recency of being asked)
            let questionHistoryValue = object.questionHistory ?? (highestQuestionHistory + 1)
            let questionHistoryScore = Double(questionHistoryValue) / Double(highestQuestionHistory + 1) * 0.25
            score += questionHistoryScore

            // Factor 2: Learner competency score
            let learnerCompetencyScore = scaledCompetencyScores[index]
            score += learnerCompetencyScore

            scores.append((object, score))

            print("Object: \(object.name)")
            print("  Question History Score: \(questionHistoryScore)")
            print("  Learner Competency Score: \(learnerCompetencyScore)")
            print("  Total Score: \(score)")
        }

        // Calculate the standard deviation of the scores
        let meanScore = scores.map { $0.score }.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0.score - meanScore, 2.0) }.reduce(0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)

        // Sort scores in descending order
        scores.sort(by: { $0.score > $1.score })

        // Handle different selection scenarios
        let topScore = scores[0].score
        let topScoringObjects = scores.filter { $0.score == topScore }

        // 1. If there's one top score with no other scores within one standard deviation, select the top score
        if topScoringObjects.count == 1 {
            if scores.count < 2 {return scores[0].object}
            let secondHighestScore = scores[1].score
            if abs(topScore - secondHighestScore) > standardDeviation {
                print("Choosing the top object without ties:")
                print("Top object: \(scores[0].object.name), Score: \(scores[0].score)")
                return scores[0].object
            }
        }

        // 2. If there are any number of tying top scores, select randomly from them
        if topScoringObjects.count > 1 {
            let chosenObject = topScoringObjects.randomElement()!.object
            print("Choosing randomly among top tying objects:")
            topScoringObjects.forEach { print("Object: \($0.object.name), Score: \($0.score)") }
            return chosenObject
        }

        // 3. If there's one top score, but a second score within one standard deviation, select randomly between them
        let secondHighestScore = scores[1].score
        if abs(topScore - secondHighestScore) <= standardDeviation {
            let secondScoringObjects = scores.filter { abs($0.score - topScore) <= standardDeviation }
            let chosenObject = secondScoringObjects.randomElement()!.object
            print("Choosing between top score and those within one standard deviation:")
            secondScoringObjects.forEach { print("Object: \($0.object.name), Score: \($0.score)") }
            return chosenObject
        }

        // 4. If there's one top score, but multiple scores tying for second within one standard deviation, select randomly among them
        let secondScoringObjects = scores.filter { $0.score != topScore && abs($0.score - topScore) <= standardDeviation }
        if secondScoringObjects.count > 1 {
            let candidates = [scores[0]] + secondScoringObjects
            let chosenObject = candidates.randomElement()!.object
            print("Choosing between top object and second place ties within one standard deviation:")
            candidates.forEach { print("Object: \($0.object.name), Score: \($0.score)") }
            return chosenObject
        }

        // Default to choosing the top object
        print("Choosing the top object by default:")
        print("Top object: \(scores[0].object.name), Score: \(scores[0].score)")
        return scores[0].object
    }
    
    func playSoundsSequentially(
        sounds: [String],
        type: String,
        objects: [LearningObject?] = [],
        firstItemCompletion: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        continuePlaying = true
        var audioItems: [AVPlayerItem] = []

        for sound in sounds {
            print("Attempting to play sound: \(sound)")
            let fileName = sound.hasSuffix(".\(type)") ? sound : "\(sound).\(type)"
            let fileURL = getDocumentDirectoryURL(for: fileName)
            print("Resolved file URL: \(fileURL)")

            if FileManager.default.fileExists(atPath: fileURL.path) {
                let item = AVPlayerItem(url: fileURL)
                audioItems.append(item)
                print("Audio file found: \(fileName)")
            } else {
                print("Audio file not found: \(fileName)")
            }
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session is active and ready in playSoundsSequentially")
        } catch {
            print("Failed to set up AVAudioSession in playSoundsSequentially: \(error)")
            return
        }

        audioQueuePlayer = AVQueuePlayer(items: audioItems)

        // Add observer to highlight the incorrectly selected object during playback
        if objects.count > 0 {
            audioQueuePlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: DispatchQueue.main) { [weak self] time in
                guard let self = self else { return }
                if self.audioQueuePlayer?.currentItem == audioItems.first {
                    self.highlightedObject = objects.first ?? nil
                } else {
                    self.highlightedObject = nil
                }
            }
        }

        // Add observer to call firstItemCompletion handler after the first item ends
        if let firstItem = audioItems.first {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: firstItem, queue: .main) { _ in
                firstItemCompletion?()
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: firstItem)
            }
        }

        // Add observer to call completion handler after all items end
        if let lastItem = audioItems.last {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: lastItem, queue: .main) { _ in
                completion?()
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: lastItem)
            }
        }

        print("Starting audio playback")
        audioQueuePlayer?.play()
    }

    private func getDocumentDirectoryURL(for fileName: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }

    
    private func stopCurrentAudio() {
        print("Stopping current audio and setting isQuestionAudioPlaying to false")
        isQuestionAudioPlaying = false
        continuePlaying = false
        audioQueuePlayer?.pause()
        audioQueuePlayer = nil
        currentAudioPlayer?.stop()
        currentAudioPlayer = nil

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated in stopCurrentAudio")
        } catch {
            print("Failed to deactivate AVAudioSession in stopCurrentAudio: \(error)")
        }
    }
    
    private func grayOutHalfObjects(except targetObject: LearningObject) {
        // Ensure at least 3 objects remain visible
        var minVisibleObjects = 3
        let totalObjects = currentObjects.count

        // Determine the number of objects to gray out
        let numToGrayOut: Int
        if totalObjects == 3 {
            numToGrayOut = 1 // Gray out 1 object, leaving 2 visible
            minVisibleObjects = 2
        } else {
            numToGrayOut = totalObjects / 2
            //numToGrayOut = max(totalObjects / 2, totalObjects - 3) // Gray out half, leaving a minimum of 3 visible
        }
        let maxGrayOut = totalObjects - minVisibleObjects
        let grayOutCount = min(numToGrayOut, maxGrayOut)
        
        // Ensure grayOutCount is not less than zero
        guard grayOutCount > 0 else {
            grayedOutObjects = []
            return
        }
    
        // Create a list of objects to gray out excluding the target object
        var objectsToGrayOut = currentObjects.filter { $0.name != targetObject.name }
        objectsToGrayOut.shuffle() // Randomly shuffle the objects

        // Select the first n objects to gray out
        grayedOutObjects = Array(objectsToGrayOut.prefix(grayOutCount))
    }
    
    private func grayOutAllButTwoObjects(except targetObject: LearningObject) {
        // Ensure at least 2 objects remain visible
        let minVisibleObjects = 2
        let totalObjects = currentObjects.count
        let maxGrayOut = totalObjects - minVisibleObjects
        
        // Create a list of objects to gray out excluding the target object and currently grayed out objects
        let alreadyGrayedOutObjects = grayedOutObjects.filter { $0.name != targetObject.name }
        var objectsToKeepVisible = currentObjects.filter { $0.name != targetObject.name && !grayedOutObjects.contains($0) }
        
        // Ensure there are enough objects to gray out
        if objectsToKeepVisible.count > 1 {
            objectsToKeepVisible.shuffle()
            let secondVisibleObject = objectsToKeepVisible.first!
            
            grayedOutObjects = currentObjects.filter { $0.name != targetObject.name && $0.name != secondVisibleObject.name }
        } else {
            grayedOutObjects = currentObjects.filter { $0.name != targetObject.name }
        }
    }
    
}

var audioPlayer: AVAudioPlayer?
