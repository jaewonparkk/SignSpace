import Foundation
import RealityKit
import UIKit
import simd

final class HandSkeletonRenderer {

    // MARK: - Root

    let root = Entity()

    private var handSkeletons: [HandSkeletonEntity] = []

    private let trailRoot = Entity()

    private var trailSegments: [ModelEntity] = []


    // MARK: - Init

    init() {
        root.addChild(trailRoot)
    }


    // MARK: - Hand Update

    func update(with frame: SignFrame) {

        ensureHandCount(frame.hands.count)

        for index in handSkeletons.indices {

            if index < frame.hands.count {

                handSkeletons[index].root.isEnabled = true

                handSkeletons[index].update(
                    with: frame.hands[index]
                )

            } else {

                handSkeletons[index].root.isEnabled = false
            }
        }
    }


    // MARK: - Movement Trail

    func updateTrail(
        motion: SignMotion,
        through frameIndex: Int,
        isVisible: Bool
    ) {

        trailRoot.isEnabled = isVisible

        guard isVisible else {
            return
        }

        guard !motion.frames.isEmpty else {
            hideAllTrailSegments()
            return
        }

        let safeIndex = min(
            max(frameIndex, 0),
            motion.frames.count - 1
        )

        let maximumPoints = 32

        let frameCount = safeIndex + 1

        let strideAmount = max(
            1,
            frameCount / maximumPoints
        )

        var rawPoints: [SIMD3<Float>] = []

        var index = 0

        while index <= safeIndex {

            let frame = motion.frames[index]

            if let hand = frame.hands.first,
               let point = makeWristPosition(
                    from: hand
               ) {

                rawPoints.append(point)
            }

            index += strideAmount
        }


        // Always include the current frame.

        if let hand =
            motion.frames[safeIndex].hands.first,
           let point =
            makeWristPosition(from: hand) {

            rawPoints.append(point)
        }


        let points = smooth(
            rawPoints
        )


        guard points.count >= 2 else {

            hideAllTrailSegments()

            return
        }


        let requiredSegmentCount =
            points.count - 1

        ensureTrailSegmentCount(
            requiredSegmentCount
        )


        for segmentIndex in trailSegments.indices {

            if segmentIndex < requiredSegmentCount {

                trailSegments[
                    segmentIndex
                ].isEnabled = true


                updateTrailSegment(
                    trailSegments[
                        segmentIndex
                    ],
                    from:
                        points[
                            segmentIndex
                        ],
                    to:
                        points[
                            segmentIndex + 1
                        ]
                )

            } else {

                trailSegments[
                    segmentIndex
                ].isEnabled = false
            }
        }
    }


    // MARK: - Wrist Position

    private func makeWristPosition(
        from hand: HandFrame
    ) -> SIMD3<Float>? {

        guard let wrist =
                hand.normalizedLandmarks.first
        else {
            return nil
        }

        let x =
            (wrist.x - 0.5)
            * 0.45

        let y =
            (0.5 - wrist.y)
            * 0.55

        return SIMD3<Float>(
            x,
            y,
            0
        )
    }


    // MARK: - Smooth Trail

    private func smooth(
        _ points: [SIMD3<Float>]
    ) -> [SIMD3<Float>] {

        guard points.count > 1 else {
            return points
        }

        var result: [SIMD3<Float>] = []

        result.append(
            points[0]
        )

        let smoothing: Float = 0.35

        for point in points.dropFirst() {

            guard let previous =
                    result.last
            else {
                continue
            }

            let smoothed =
                previous * (1 - smoothing)
                + point * smoothing

            result.append(
                smoothed
            )
        }

        return result
    }


    // MARK: - Trail Segments

    private func ensureTrailSegmentCount(
        _ count: Int
    ) {

        guard trailSegments.count < count else {
            return
        }

        let mesh =
            MeshResource.generateCylinder(
                height: 1.0,
                radius: 1.0
            )

        let material =
            UnlitMaterial(
                color: UIColor(
                    red: 0.20,
                    green: 0.58,
                    blue: 1.0,
                    alpha: 0.85
                )
            )

        while trailSegments.count < count {

            let segment =
                ModelEntity(
                    mesh: mesh,
                    materials: [
                        material
                    ]
                )

            trailSegments.append(
                segment
            )

            trailRoot.addChild(
                segment
            )
        }
    }


    private func updateTrailSegment(
        _ segment: ModelEntity,
        from start: SIMD3<Float>,
        to end: SIMD3<Float>
    ) {

        let direction =
            end - start

        let length =
            simd_length(
                direction
            )

        guard length > 0.0001 else {

            segment.isEnabled = false

            return
        }

        segment.isEnabled = true

        segment.position =
            (start + end) / 2

        segment.scale =
            SIMD3<Float>(
                0.0023,
                length,
                0.0023
            )

        let normalizedDirection =
            direction / length

        segment.orientation =
            simd_quatf(
                from: SIMD3<Float>(
                    0,
                    1,
                    0
                ),
                to: normalizedDirection
            )
    }


    private func hideAllTrailSegments() {

        for segment in trailSegments {

            segment.isEnabled =
                false
        }
    }


    // MARK: - View Transform

    func setViewTransform(
        yaw: Float,
        pitch: Float,
        zoom: Float
    ) {

        let yawRotation =
            simd_quatf(
                angle: yaw,
                axis: SIMD3<Float>(
                    0,
                    1,
                    0
                )
            )

        let pitchRotation =
            simd_quatf(
                angle: pitch,
                axis: SIMD3<Float>(
                    1,
                    0,
                    0
                )
            )

        root.orientation =
            yawRotation
            * pitchRotation

        root.scale =
            SIMD3<Float>(
                repeating: zoom
            )
    }


    // MARK: - Hand Setup

    private func ensureHandCount(
        _ count: Int
    ) {

        while handSkeletons.count < count {

            let skeleton =
                HandSkeletonEntity()

            handSkeletons.append(
                skeleton
            )

            root.addChild(
                skeleton.root
            )
        }
    }
}


// MARK: - Individual Hand Skeleton

private final class HandSkeletonEntity {

    let root = Entity()

    private var joints: [ModelEntity] = []

    private var bones: [ModelEntity] = []


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


    // MARK: - Init

    init() {

        createJoints()

        createBones()
    }


    // MARK: - Joints

    private func createJoints() {

        let mesh =
            MeshResource.generateSphere(
                radius: 0.0045
            )

        let material =
            UnlitMaterial(
                color: UIColor(
                    red: 0.16,
                    green: 0.52,
                    blue: 1.0,
                    alpha: 1.0
                )
            )

        for _ in 0..<21 {

            let joint =
                ModelEntity(
                    mesh: mesh,
                    materials: [
                        material
                    ]
                )

            joints.append(
                joint
            )

            root.addChild(
                joint
            )
        }
    }


    // MARK: - Bones

    private func createBones() {

        let mesh =
            MeshResource.generateCylinder(
                height: 1.0,
                radius: 1.0
            )

        let material =
            UnlitMaterial(
                color: UIColor(
                    white: 0.92,
                    alpha: 1.0
                )
            )

        for _ in connections {

            let bone =
                ModelEntity(
                    mesh: mesh,
                    materials: [
                        material
                    ]
                )

            bones.append(
                bone
            )

            root.addChild(
                bone
            )
        }
    }


    // MARK: - Update

    func update(
        with hand: HandFrame
    ) {

        guard
            hand.worldLandmarks.count == 21
        else {

            root.isEnabled = false

            return
        }

        root.isEnabled = true

        let positions =
            makeRealityKitPositions(
                from: hand
            )


        for index in 0..<21 {

            joints[index].position =
                positions[index]
        }


        for (
            boneIndex,
            connection
        ) in connections.enumerated() {

            let start =
                positions[
                    connection.0
                ]

            let end =
                positions[
                    connection.1
                ]

            updateBone(
                bones[boneIndex],
                from: start,
                to: end
            )
        }
    }


    // MARK: - Coordinates

    private func makeRealityKitPositions(
        from hand: HandFrame
    ) -> [SIMD3<Float>] {

        let wrist =
            hand.normalizedLandmarks.first

        let horizontalOffset: Float
        let verticalOffset: Float

        if let wrist {

            horizontalOffset =
                (wrist.x - 0.5)
                * 0.45

            verticalOffset =
                (0.5 - wrist.y)
                * 0.55

        } else {

            horizontalOffset = 0

            verticalOffset = 0
        }

        let positionOffset =
            SIMD3<Float>(
                horizontalOffset,
                verticalOffset,
                0
            )

        let handScale: Float =
            1.5

        return hand.worldLandmarks.map {

            let local =
                SIMD3<Float>(
                    $0.x,
                    -$0.y,
                    -$0.z
                )

            return
                local
                * handScale
                + positionOffset
        }
    }


    // MARK: - Bone Geometry

    private func updateBone(
        _ bone: ModelEntity,
        from start: SIMD3<Float>,
        to end: SIMD3<Float>
    ) {

        let direction =
            end - start

        let length =
            simd_length(
                direction
            )

        guard length > 0.0001 else {

            bone.isEnabled =
                false

            return
        }

        bone.isEnabled =
            true

        bone.position =
            (start + end)
            / 2

        bone.scale =
            SIMD3<Float>(
                0.0026,
                length,
                0.0026
            )

        let normalizedDirection =
            direction
            / length

        bone.orientation =
            simd_quatf(
                from: SIMD3<Float>(
                    0,
                    1,
                    0
                ),
                to: normalizedDirection
            )
    }
}
