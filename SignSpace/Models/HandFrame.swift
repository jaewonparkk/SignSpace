import Foundation

struct LandmarkPoint: Codable, Hashable {

    let x: Float
    let y: Float
    let z: Float
}


struct HandFrame: Codable, Hashable {

    // Coordinates normalized to the camera image.
    // Useful for overlay / body-relative position later.
    let normalizedLandmarks: [LandmarkPoint]

    // Real-world 3D hand geometry from MediaPipe.
    // Coordinates are expressed in meters.
    let worldLandmarks: [LandmarkPoint]
}
