//import Foundation
//
//struct LearningObject: Equatable {
//    var name: String
//    var nepaliName: String
//    var imageName: String?
//    var videoName: String?
//    var audioFileName: String
//    var history: [Interaction] = []
//    var questionHistory: Int? = nil
//
//    struct Interaction: Equatable {
//        var date: Date
//        var type: InteractionType
//
//        enum InteractionType: String {
//            case asked
//            case answeredCorrectly
//            case answeredIncorrectly
//            case objectNotKnown // New interaction type for object being asked about but not known
//        }
//    }
//
//    static func ==(lhs: LearningObject, rhs: LearningObject) -> Bool {
//        return lhs.name == rhs.name
//    }
//
//    func calculateLearnerCompetencyScore() -> Double {
//        if history.isEmpty {
//            return 180.0
//        }
//
//        var score = 250.0
//
//        print("Score: \(score)")
//        for (index, interaction) in history.enumerated() {
//            print ("history item index \(index)")
//            let multiplier: Double
//            switch interaction.type {
//            case .answeredCorrectly:
//                print(".answeredCorrectly")
//                if index == 0 {
//                    print("multiplier of 1.3225")
//                    multiplier = 1.3225
//                } else if index == 1 {
//                    print("multiplier of 1.265")
//                    multiplier = 1.265
//                } else if index == 2 {
//                    print("multiplier of 1.2075")
//                    multiplier = 1.2075
//                } else {
//                    print("multiplier of 1.15")
//                    multiplier = 1.15
//                }
//            case .answeredIncorrectly, .objectNotKnown:
//                print(".answeredIncorrectly or .objectNotKnown")
//                if index == 0 {
//                    print("multiplier 0.7225")
//                    multiplier = 0.7225
//                } else if index == 1 {
//                    print("multiplier 0.765")
//                    multiplier = 0.765
//                } else if index == 2 {
//                    print("multiplier 0.8075")
//                    multiplier = 0.8075
//                } else {
//                    print("multiplier 0.85")
//                    multiplier = 0.85
//                }
//            case .asked:
//                print(".asked (ignoring)")
//                continue // Ignore the asked interactions
//            }
//            
//            score *= multiplier
//            print("Score after multiplication by multiplier (\(multiplier)): \(score)")
//        }
//
//        return score
//    }
//}
