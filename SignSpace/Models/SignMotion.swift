import Foundation

struct SignMotion: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    let createdAt: Date

    let frames: [SignFrame]


    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        frames: [SignFrame]
    ) {

        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.frames = frames
    }


    var frameCount: Int {
        frames.count
    }


    var durationMilliseconds: Int {
        frames.last?.timestampMilliseconds ?? 0
    }


    var durationSeconds: Double {
        Double(durationMilliseconds) / 1000.0
    }
}
