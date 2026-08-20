import Foundation
import SwiftData

@Model
final class SavedSign {

    // MARK: - Stored Properties

    var id: UUID

    var name: String

    var difficulty: String

    var lessonDescription: String

    var notice1: String

    var notice2: String

    var notice3: String

    var createdAt: Date

    @Attribute(.externalStorage)
    var motionData: Data


    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        difficulty: String,
        lessonDescription: String,
        notice1: String,
        notice2: String,
        notice3: String,
        createdAt: Date = Date(),
        motion: SignMotion
    ) {

        self.id = id

        self.name = name

        self.difficulty = difficulty

        self.lessonDescription = lessonDescription

        self.notice1 = notice1

        self.notice2 = notice2

        self.notice3 = notice3

        self.createdAt = createdAt


        do {

            self.motionData =
                try JSONEncoder().encode(
                    motion
                )

        } catch {

            print(
                "Failed to encode SignMotion:",
                error
            )

            self.motionData =
                Data()
        }
    }


    // MARK: - Motion

    var targetMotion: SignMotion? {

        guard
            !motionData.isEmpty
        else {
            return nil
        }


        do {

            return try JSONDecoder().decode(
                SignMotion.self,
                from: motionData
            )

        } catch {

            print(
                "Failed to decode SignMotion:",
                error
            )

            return nil
        }
    }


    // MARK: - Computed Metadata

    var handCount: Int {

        targetMotion?
            .frames
            .map {
                $0.hands.count
            }
            .max()
        ?? 0
    }


    var handDescription: String {

        switch handCount {

        case 1:

            return "1 hand"


        case 2:

            return "2 hands"


        default:

            return "\(handCount) hands"
        }
    }


    var durationText: String {

        guard let motion =
                targetMotion
        else {

            return "—"
        }


        return String(
            format: "%.1fs",
            motion.durationSeconds
        )
    }


    var notices: [String] {

        [
            notice1,
            notice2,
            notice3
        ]
        .filter {

            !$0
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }
    }
}
