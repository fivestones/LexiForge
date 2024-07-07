import Foundation

struct LearningObject: Equatable {
    var name: String
    var nepaliName: String
    var imageName: String?
    var videoName: String?
    var thisIsAudioFileName: String
    var negativeAudioFileName: String
    var whereIsAudioFileName: String
    var history: [Interaction] = [] {
        didSet {
            // When history is updated, check if we need to cache the score
            if history.count > maxCachedIndex {
                cacheLearnerCompetencyScore()
            }
        }
    }
    var askedHistory: [Date] = []
    var introducedHistory: Date? // New variable for introduced history
    var questionHistory: Int? = nil
    private var cachedScore: Double?
    private var cachedHistoryCount: Int = 0

    private let maxCachedIndex = 6 // Number of recent interactions to consider

    struct Interaction: Equatable {
        var date: Date
        var type: InteractionType
        var attempts: Int // Add attempts property

        enum InteractionType: String {
            case answeredCorrectly
            case answeredIncorrectly
            case objectNotKnown // Interaction for object being asked about but not known
        }
    }

    static func ==(lhs: LearningObject, rhs: LearningObject) -> Bool {
        return lhs.name == rhs.name
    }

    // Explicit initializer
    init(name: String, nepaliName: String, imageName: String?, videoName: String?, thisIsAudioFileName: String, negativeAudioFileName: String, whereIsAudioFileName: String, history: [Interaction] = [], askedHistory: [Date] = [], introducedHistory: Date? = nil, questionHistory: Int? = nil, cachedScore: Double? = nil, cachedHistoryCount: Int = 0) {
        self.name = name
        self.nepaliName = nepaliName
        self.imageName = imageName
        self.videoName = videoName
        self.thisIsAudioFileName = thisIsAudioFileName
        self.negativeAudioFileName = negativeAudioFileName
        self.whereIsAudioFileName = whereIsAudioFileName
        self.history = history
        self.askedHistory = askedHistory
        self.introducedHistory = introducedHistory
        self.questionHistory = questionHistory
        self.cachedScore = cachedScore
        self.cachedHistoryCount = cachedHistoryCount
    }

    // Function to calculate the learner competency score
    mutating func calculateLearnerCompetencyScore() -> Double {
        if history.isEmpty {
            return 180.0
        }

        // Start with the cached score if available, otherwise start with the initial score
        var score = cachedScore ?? 250.0

        print("Initial Score: \(score)")
        // Process only the most recent `maxCachedIndex` interactions
        let recentInteractions = history.suffix(maxCachedIndex)
        for (index, interaction) in recentInteractions.enumerated() {
            let multiplier: Double
            switch interaction.type {
            case .answeredCorrectly:
//                print(".answeredCorrectly")
                if index == 0 {
//                    print("multiplier of 1.3225")
                    multiplier = 1.3225
                } else if index == 1 {
//                    print("multiplier of 1.265")
                    multiplier = 1.265
                } else if index == 2 {
//                    print("multiplier of 1.2075")
                    multiplier = 1.2075
                } else {
//                    print("multiplier of 1.15")
                    multiplier = 1.15
                }
            case .answeredIncorrectly, .objectNotKnown:
//                print(".answeredIncorrectly or .objectNotKnown")
                if index == 0 {
//                    print("multiplier of 0.7225")
                    multiplier = 0.7225
                } else if index == 1 {
//                    print("multiplier of 0.765")
                    multiplier = 0.765
                } else if index == 2 {
//                    print("multiplier of 0.8075")
                    multiplier = 0.8075
                } else {
//                    print("multiplier of 0.85")
                    multiplier = 0.85
                }
            }

            // Apply the multiplier to the score
            score *= multiplier
//            print("Score after multiplying by multiplier (\(multiplier)): \(score)")
        }

        return score
    }

    // Function to cache the learner competency score
    private mutating func cacheLearnerCompetencyScore() {
        // Ensure we only cache if there are more interactions than cached history count
        guard history.count > cachedHistoryCount else { return }

        if cachedScore == nil {
            // First time caching
            cachedScore = 250.0
        }

        // Update existing cache with the 7th most recent valid interaction
        let interactionIndex = history.count - maxCachedIndex - 1
        if interactionIndex >= 0 {
            let interaction = history[interactionIndex]
            let multiplier: Double
            switch interaction.type {
            case .answeredCorrectly:
                multiplier = 1.15
            case .answeredIncorrectly, .objectNotKnown:
                multiplier = 0.85
            }

            // Apply the multiplier to the cached score
            cachedScore! *= multiplier
            // Increment the cached history count
            cachedHistoryCount += 1
            print("Cached Score: \(cachedScore!)")
        }
    }
}
