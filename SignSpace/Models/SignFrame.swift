import Foundation

struct SignFrame: Codable, Hashable {

    // Time since recording started.
    let timestampMilliseconds: Int

    // Supports one-hand and two-hand signs.
    let hands: [HandFrame]
}
