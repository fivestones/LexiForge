import SwiftUI
import SwiftData

@Model
final class GenericAudioFile {
    var id: UUID
    var fileName: String

    init(id: UUID = UUID(), fileName: String) {
        self.id = id
        self.fileName = fileName
    }
}
