import SwiftData
import Foundation

@Model
final class Tag: Identifiable {
    var id: UUID
    var name: String
    
    var objects: [LearningObject]

    init(id: UUID = UUID(), name: String, objects: [LearningObject]) {
        self.id = id
        self.name = name
        self.objects = objects
    }
}

@Model
final class LearningObject {
    var id: UUID
    var name: String
    var nepaliName: String
    var imageName: String?
    var videoName: String?
    var thisIsAudioFileName: String
    var negativeAudioFileName: String
    var whereIsAudioFileName: String
    @Attribute(.externalStorage) var history: [Interaction] = []
    @Attribute(.externalStorage) var askedHistory: [Date] = []
    var introducedHistory: Date?
    var questionHistory: Int?
    @Attribute(.externalStorage) var setTags: [UUID] = []
    var partOfSpeechTag: UUID?
    @Relationship(inverse: \Tag.objects) var tags: [Tag]

    init(id: UUID = UUID(), name: String, nepaliName: String, imageName: String? = nil, videoName: String? = nil,
         thisIsAudioFileName: String, negativeAudioFileName: String, whereIsAudioFileName: String,
         history: [Interaction] = [], askedHistory: [Date] = [], introducedHistory: Date? = nil,
         questionHistory: Int? = nil, setTags: [UUID] = [], partOfSpeechTag: UUID? = nil, tags: [Tag]) {
        self.id = id
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
        self.setTags = setTags
        self.partOfSpeechTag = partOfSpeechTag
        self.tags = tags
    }
    
    @Transient
    private var cachedScore: Double?
    
    @Transient
    private var cachedHistoryCount: Int = 0
    
    private let maxCachedIndex = 6
    
    func calculateLearnerCompetencyScore() -> Double {
        if history.isEmpty {
            return 180.0
        }

        var score = cachedScore ?? 250.0
        
        let recentInteractions = history.suffix(maxCachedIndex)
        for (index, interaction) in recentInteractions.enumerated() {
            let multiplier: Double
            switch interaction.type {
            case .answeredCorrectly:
                multiplier = [1.3225, 1.265, 1.2075, 1.15][min(index, 3)]
            case .answeredIncorrectly, .objectNotKnown:
                multiplier = [0.7225, 0.765, 0.8075, 0.85][min(index, 3)]
            }
            score *= multiplier
        }

        return score
    }
    
    func cacheLearnerCompetencyScore() {
        guard history.count > cachedHistoryCount else { return }

        if cachedScore == nil {
            cachedScore = 250.0
        }

        let interactionIndex = history.count - maxCachedIndex - 1
        if interactionIndex >= 0 {
            let interaction = history[interactionIndex]
            let multiplier: Double = interaction.type == .answeredCorrectly ? 1.15 : 0.85
            cachedScore! *= multiplier
            cachedHistoryCount += 1
        }
    }
}

extension LearningObject {
    static func predicate(
        tag: [Tag] //This will just take one tag, but if I want to send an array of tags I can check for each of them with a ForEach and then for each one a ` || object.tags.contains { $0.name == tag } )` kind of thing in the predicate. Maybe. Or just do a separate filter for each one, and then combine the resulting things? maybe? Not sure.
    ) -> Predicate<LearningObject> {
        return #Predicate<LearningObject> { object in
            (tag.isEmpty || object.tags.contains { $0.name == tag }  )
        }
    }}

struct Interaction: Codable {
    var date: Date
    var type: InteractionType
    var attempts: Int

    enum InteractionType: String, Codable {
        case answeredCorrectly
        case answeredIncorrectly
        case objectNotKnown
    }
}
