import SwiftUI
import AVFoundation

class LearningViewModel: ObservableObject {
    @Published var objects: [LearningObject] = [
        LearningObject(name: "horse", nepaliName: "घोडा", imageName: nil, videoName: "horse", thisIsAudioFileName: "this_is_a-horse", negativeAudioFileName: "negative_response_horse", whereIsAudioFileName: "where_is_horse"),
        LearningObject(name: "cow", nepaliName: "गाई", imageName: "cow", videoName: nil, thisIsAudioFileName: "this_is_a-cow", negativeAudioFileName: "negative_response_cow", whereIsAudioFileName: "where_is_cow"),
        LearningObject(name: "sheep", nepaliName: "भेंडा", imageName: "sheep", videoName: nil, thisIsAudioFileName: "this_is_a-sheep", negativeAudioFileName: "negative_response_sheep", whereIsAudioFileName: "where_is_sheep"),
        LearningObject(name: "goat", nepaliName: "बाख्रा", imageName: "goat", videoName: "goat", thisIsAudioFileName: "this_is_a-goat", negativeAudioFileName: "negative_response_goat", whereIsAudioFileName: "where_is_goat"),
        LearningObject(name: "dog", nepaliName: "कुकुर", imageName: "dog", videoName: nil, thisIsAudioFileName: "this_is_a-dog", negativeAudioFileName: "negative_response_dog", whereIsAudioFileName: "where_is_dog"),
        LearningObject(name: "cat", nepaliName: "बिरालो", imageName: "cat", videoName: "cat", thisIsAudioFileName: "this_is_a-cat", negativeAudioFileName: "negative_response_cat", whereIsAudioFileName: "where_is_cat"),
        LearningObject(name: "tiger", nepaliName: "बाघ", imageName: "tiger", videoName: nil, thisIsAudioFileName: "this_is_a-tiger", negativeAudioFileName: "negative_response_tiger", whereIsAudioFileName: "where_is_tiger"),
        LearningObject(name: "rhinoceros", nepaliName: "गैडा", imageName: "rhinoceros", videoName: nil, thisIsAudioFileName: "this_is_a-rhinoceros", negativeAudioFileName: "negative_response_rhinoceros", whereIsAudioFileName: "where_is_rhinoceros"),
        LearningObject(name: "buffalo", nepaliName: "भैंसी", imageName: "buffalo", videoName: nil, thisIsAudioFileName: "this_is_a-buffalo", negativeAudioFileName: "negative_response_buffalo", whereIsAudioFileName: "where_is_buffalo"),
        LearningObject(name: "pig", nepaliName: "सुँगुर", imageName: "pig", videoName: nil, thisIsAudioFileName: "this_is_a-pig", negativeAudioFileName: "negative_response_pig", whereIsAudioFileName: "where_is_pig"),
        LearningObject(name: "deer", nepaliName: "हिरण", imageName: "deer", videoName: nil, thisIsAudioFileName: "this_is_a-deer", negativeAudioFileName: "negative_response_deer", whereIsAudioFileName: "where_is_deer"),
        LearningObject(name: "alligator", nepaliName: "गोही", imageName: "alligator", videoName: nil, thisIsAudioFileName: "this_is_a-alligator", negativeAudioFileName: "negative_response_alligator", whereIsAudioFileName: "where_is_alligator"),
        LearningObject(name: "horse1", nepaliName: "घोडा", imageName: nil, videoName: "horse", thisIsAudioFileName: "this_is_a-horse", negativeAudioFileName: "negative_response_horse", whereIsAudioFileName: "where_is_horse")
    ]
    @Published var currentObjects: [LearningObject] = []
    @Published var currentPrompt: String = ""
    @Published var highlightedObject: LearningObject?
    @Published var targetWord: String?
    @Published var attempts: Int = 0 // property for counting attempts
    @Published var grayedOutObjects: [LearningObject] = []
    @Published var correctAnswerObjectWasSelected: LearningObject? // Flag to track the correct answer

        var currentAudioPlayer: AVAudioPlayer?
        var audioQueuePlayer: AVQueuePlayer?
        var continuePlaying = true

    func introduceNextObject() {
        stopCurrentAudio()
        if currentObjects.count < objects.count {
            let newObject = objects[currentObjects.count]
            currentObjects.append(newObject)
            currentPrompt = "यो \(newObject.nepaliName) हो।"
            playSoundsSequentially(sounds: [newObject.thisIsAudioFileName], type: "m4a")
        }
    }
    
    func askQuestion() {
        stopCurrentAudio()
        guard !currentObjects.isEmpty else { return }
        let selectedObject = selectNextObjectToAsk()
        currentPrompt = "\(selectedObject.nepaliName) कहाँ छ?"
        targetWord = selectedObject.nepaliName
        attempts = 0 // Reset the attempt counter
        recordAskedInteraction(for: selectedObject)
        updateQuestionHistory(for: selectedObject)
        playSoundsSequentially(sounds: [selectedObject.whereIsAudioFileName], type: "m4a")
    }
    
    func checkAnswer(selectedObject: LearningObject) {
        stopCurrentAudio()
        print("Checking answer for: \(selectedObject.name)")
        guard let targetName = targetWord else {
            print("No target word set")
            return
        }
        print("Target name: \(targetName)")
        if let correctObject = currentObjects.first(where: { $0.nepaliName == targetName }) {
            print("Correct object: \(correctObject.nepaliName)")
            if selectedObject.name == correctObject.name {
                print("Correct answer selected")
                currentPrompt = "शाबास"
                targetWord = nil
                recordInteraction(for: correctObject, type: .answeredCorrectly)
                attempts = 0 // Reset attempts after a correct answer
                correctAnswerObjectWasSelected = correctObject // Set the correct answer object
                playSoundsSequentially(
                    sounds: ["sha_bas"],
                    type: "m4a",
                    objects: [],
                    firstItemCompletion: { [weak self] in
                        // Restore all grayed out objects
                        self?.grayedOutObjects.removeAll()
                        self?.correctAnswerObjectWasSelected = nil // Reset the correct answer object after playback
                    }
                )
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
    
    private func recordInteraction(for object: LearningObject, type: LearningObject.Interaction.InteractionType) {
        print("in recordInteraction function")
        if let index = currentObjects.firstIndex(where: { $0.name == object.name }) {
            let attempts = (type == .answeredCorrectly) ? self.attempts + 1 : self.attempts
            currentObjects[index].history.append(LearningObject.Interaction(date: Date(), type: type, attempts: attempts))
            print("recorded interaction for \(object.name) as \(type) with \(attempts) attempts")
        }
    }
    
    private func recordAskedInteraction(for object: LearningObject) {
        print("in recordAskedInteraction function")
        if let index = currentObjects.firstIndex(where: { $0.name == object.name }) {
            currentObjects[index].askedHistory.append(Date())
            print("recorded asked interaction for \(object.name)")
        }
    }

    private func updateQuestionHistory(for selectedObject: LearningObject) {
        for index in currentObjects.indices {
            if currentObjects[index].name == selectedObject.name {
                currentObjects[index].questionHistory = 0
            } else if currentObjects[index].questionHistory != nil {
                currentObjects[index].questionHistory! += 1
            }
        }
    }

    private func selectNextObjectToAsk() -> LearningObject {
        let highestQuestionHistory = currentObjects.compactMap { $0.questionHistory }.max() ?? 0

        var scores: [(object: LearningObject, score: Double)] = []

        // Calculate learner competency scores
        var rawCompetencyScores: [Double] = []
        print("*********")
        print("Learner competency scores calculation time")
        for var object in currentObjects {
            print("Calculating score for \(object.name)")
            let score = object.calculateLearnerCompetencyScore()
            rawCompetencyScores.append(score)
        }
        print("*********")
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
        firstItemCompletion: (() -> Void)? = nil
    ) {
        continuePlaying = true
        var audioItems: [AVPlayerItem] = []

        for sound in sounds {
            if let path = Bundle.main.path(forResource: sound, ofType: type) {
                let item = AVPlayerItem(url: URL(fileURLWithPath: path))
                audioItems.append(item)
            } else {
                print("Audio file not found: \(sound).\(type)")
            }
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

        audioQueuePlayer?.play()
    }
    
    private func stopCurrentAudio() {
        continuePlaying = false
        audioQueuePlayer?.pause()
        audioQueuePlayer = nil
        currentAudioPlayer?.stop()
        currentAudioPlayer = nil
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
