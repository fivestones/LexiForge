import SwiftData
import Foundation

@Model
final class Category: Identifiable {
    var id: UUID //remove this maybe?
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
    @Attribute(.externalStorage) var setCategories: [UUID] = []
    var partOfSpeechTag: UUID?
    @Relationship(inverse: \Category.objects) var categories: [Category]

    init(id: UUID = UUID(), name: String, nepaliName: String, imageName: String? = nil, videoName: String? = nil,
         thisIsAudioFileName: String, negativeAudioFileName: String, whereIsAudioFileName: String,
         history: [Interaction] = [], askedHistory: [Date] = [], introducedHistory: Date? = nil,
         questionHistory: Int? = nil, setCategories: [UUID] = [], partOfSpeechTag: UUID? = nil, categories: [Category]) {
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
        self.setCategories = setCategories
        self.partOfSpeechTag = partOfSpeechTag
        self.categories = categories
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
    static func predicate(categories: [Category]) -> Predicate<LearningObject> {
        // First, check if we have any categories to filter by
        guard !categories.isEmpty else {
            return #Predicate<LearningObject> { _ in true }
        }
        
        let categoryName = categories[0].name
        
        // If category name is empty, return all objects
        if categoryName.isEmpty {
            return #Predicate<LearningObject> { _ in true }
        }
        
        // Filter objects that have a category matching the name
        return #Predicate<LearningObject> { object in
            object.categories.contains { category in
                category.name.contains(categoryName)
            }
        }
    }
}

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
