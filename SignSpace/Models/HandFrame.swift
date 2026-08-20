import Foundation


// MARK: - Landmark Point

struct LandmarkPoint: Codable, Hashable {

    let x: Float
    let y: Float
    let z: Float
}


// MARK: - Handedness

enum Handedness: String, Codable, Hashable {

    case left
    case right
    case unknown


    var displayName: String {

        switch self {

        case .left:
            return "Left"

        case .right:
            return "Right"

        case .unknown:
            return "Unknown"
        }
    }


    var sortOrder: Int {

        switch self {

        case .left:
            return 0

        case .right:
            return 1

        case .unknown:
            return 2
        }
    }
}


// MARK: - Hand Frame

struct HandFrame: Codable, Hashable {

    // MARK: Coordinates

    let normalizedLandmarks: [LandmarkPoint]

    let worldLandmarks: [LandmarkPoint]


    // MARK: Identity

    let handedness: Handedness

    let handednessConfidence: Float


    // MARK: - Init

    init(
        normalizedLandmarks: [LandmarkPoint],
        worldLandmarks: [LandmarkPoint],
        handedness: Handedness = .unknown,
        handednessConfidence: Float = 0
    ) {

        self.normalizedLandmarks =
            normalizedLandmarks

        self.worldLandmarks =
            worldLandmarks

        self.handedness =
            handedness

        self.handednessConfidence =
            handednessConfidence
    }


    // MARK: - Codable Compatibility
    //
    // Older SignSpace recordings did not contain
    // handedness fields.
    //
    // decodeIfPresent keeps those saved lessons
    // completely usable.

    private enum CodingKeys:
        String,
        CodingKey {

        case normalizedLandmarks

        case worldLandmarks

        case handedness

        case handednessConfidence
    }


    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy:
                    CodingKeys.self
            )


        normalizedLandmarks =
            try container.decode(
                [LandmarkPoint].self,
                forKey:
                    .normalizedLandmarks
            )


        worldLandmarks =
            try container.decode(
                [LandmarkPoint].self,
                forKey:
                    .worldLandmarks
            )


        handedness =
            try container.decodeIfPresent(
                Handedness.self,
                forKey:
                    .handedness
            )
            ?? .unknown


        handednessConfidence =
            try container.decodeIfPresent(
                Float.self,
                forKey:
                    .handednessConfidence
            )
            ?? 0
    }


    func encode(
        to encoder: Encoder
    ) throws {

        var container =
            encoder.container(
                keyedBy:
                    CodingKeys.self
            )


        try container.encode(
            normalizedLandmarks,
            forKey:
                .normalizedLandmarks
        )


        try container.encode(
            worldLandmarks,
            forKey:
                .worldLandmarks
        )


        try container.encode(
            handedness,
            forKey:
                .handedness
        )


        try container.encode(
            handednessConfidence,
            forKey:
                .handednessConfidence
        )
    }
}
