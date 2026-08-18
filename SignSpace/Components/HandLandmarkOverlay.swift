import SwiftUI

struct HandLandmarkOverlay: View {

    let hands: [[CGPoint]]

    private let connections: [(Int, Int)] = [
        // Thumb
        (0, 1),
        (1, 2),
        (2, 3),
        (3, 4),

        // Index
        (0, 5),
        (5, 6),
        (6, 7),
        (7, 8),

        // Middle
        (5, 9),
        (9, 10),
        (10, 11),
        (11, 12),

        // Ring
        (9, 13),
        (13, 14),
        (14, 15),
        (15, 16),

        // Pinky
        (13, 17),
        (17, 18),
        (18, 19),
        (19, 20),

        // Palm
        (0, 17)
    ]

    var body: some View {

        GeometryReader { geometry in

            Canvas { context, size in

                for hand in hands {

                    guard hand.count == 21 else {
                        continue
                    }

                    // MARK: - Skeleton Lines

                    var skeletonPath = Path()

                    for connection in connections {

                        let start = displayPoint(
                            hand[connection.0],
                            in: size
                        )

                        let end = displayPoint(
                            hand[connection.1],
                            in: size
                        )

                        skeletonPath.move(to: start)
                        skeletonPath.addLine(to: end)
                    }

                    context.stroke(
                        skeletonPath,
                        with: .color(.white.opacity(0.9)),
                        lineWidth: 3
                    )

                    // MARK: - Landmark Dots

                    for landmark in hand {

                        let point = displayPoint(
                            landmark,
                            in: size
                        )

                        let circle = CGRect(
                            x: point.x - 5,
                            y: point.y - 5,
                            width: 10,
                            height: 10
                        )

                        context.fill(
                            Path(ellipseIn: circle),
                            with: .color(
                                Color(
                                    red: 1.0,
                                    green: 0.48,
                                    blue: 0.63
                                )
                            )
                        )

                        context.stroke(
                            Path(ellipseIn: circle),
                            with: .color(.white),
                            lineWidth: 1.5
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Coordinate Conversion

    private func displayPoint(
        _ point: CGPoint,
        in size: CGSize
    ) -> CGPoint {

        // Front camera preview is mirrored.
        let mirroredX = 1.0 - point.x

        return CGPoint(
            x: mirroredX * size.width,
            y: point.y * size.height
        )
    }
}
