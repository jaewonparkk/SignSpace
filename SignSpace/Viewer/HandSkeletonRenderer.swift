import Foundation
import RealityKit
import UIKit
import simd

final class HandSkeletonRenderer {

    // MARK: - Root

    let root = Entity()

    private var handSkeletons: [HandSkeletonEntity] = []

    private let trailRoot = Entity()

    private var trailDots: [ModelEntity] = []


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

            hideAllTrailDots()

            return
        }


        let safeIndex = min(
            max(frameIndex, 0),
            motion.frames.count - 1
        )


        // Avoid creating hundreds of 3D entities
        // for very long recordings.

        let maximumTrailPoints = 80

        let frameCount =
            safeIndex + 1

        let strideAmount =
            max(
                1,
                frameCount / maximumTrailPoints
            )


        var points: [SIMD3<Float>] = []


        var index = 0

        while index <= safeIndex {

            let frame =
                motion.frames[index]


            if let hand =
                frame.hands.first {

                if let wristPosition =
                    makeWristPosition(
                        from: hand
                    ) {

                    points.append(
                        wristPosition
                    )
                }
            }


            index += strideAmount
        }


        // Always include current frame.

        if let currentHand =
            motion.frames[safeIndex]
                .hands
                .first,
           let currentWrist =
            makeWristPosition(
                from: currentHand
            ) {

            if points.last != currentWrist {

                points.append(
                    currentWrist
                )
            }
        }


        ensureTrailDotCount(
            points.count
        )


        for dotIndex in trailDots.indices {

            if dotIndex < points.count {

                trailDots[dotIndex]
                    .isEnabled = true

                trailDots[dotIndex]
                    .position =
                    points[dotIndex]

            } else {

                trailDots[dotIndex]
                    .isEnabled = false
            }
        }
    }


    // MARK: - Trail Coordinates

    private func makeWristPosition(
        from hand: HandFrame
    ) -> SIMD3<Float>? {

        guard
            hand.normalizedLandmarks.count > 0,
            hand.worldLandmarks.count > 0
        else {
            return nil
        }


        let normalizedWrist =
            hand.normalizedLandmarks[0]

        let worldWrist =
            hand.worldLandmarks[0]


        // Global movement in camera space.

        let horizontalOffset =
            (normalizedWrist.x - 0.5)
            * 0.45

        let verticalOffset =
            (0.5 - normalizedWrist.y)
            * 0.55


        // Local 3D wrist position.

        let handScale: Float =
            1.5

        let localWrist =
            SIMD3<Float>(
                worldWrist.x,
                -worldWrist.y,
                -worldWrist.z
            )
            * handScale


        return localWrist +
            SIMD3<Float>(
                horizontalOffset,
                verticalOffset,
                0
            )
    }


    // MARK: - Trail Entities

    private func ensureTrailDotCount(
        _ count: Int
    ) {

        guard trailDots.count < count else {
            return
        }


        let mesh =
            MeshResource.generateSphere(
                radius: 0.003
            )


        let material =
            UnlitMaterial(
                color: UIColor(
                    red: 1.0,
                    green: 0.58,
                    blue: 0.72,
                    alpha: 0.8
                )
            )


        while trailDots.count < count {

            let dot =
                ModelEntity(
                    mesh: mesh,
                    materials: [material]
                )


            trailDots.append(
                dot
            )


            trailRoot.addChild(
                dot
            )
        }
    }


    private func hideAllTrailDots() {

        for dot in trailDots {

            dot.isEnabled =
                false
        }
    }


    // MARK: - Camera / User Transform

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


// MARK: - Individual Hand

private final class HandSkeletonEntity {

    let root = Entity()

    private var joints: [ModelEntity] = []

    private var bones: [ModelEntity] = []


    // MARK: MediaPipe Skeleton

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


    // MARK: - Joint Models

    private func createJoints() {

        let mesh =
            MeshResource.generateSphere(
                radius: 0.0045
            )


        let material =
            UnlitMaterial(
                color: UIColor(
                    red: 1.0,
                    green: 0.42,
                    blue: 0.62,
                    alpha: 1.0
                )
            )


        for _ in 0..<21 {

            let joint =
                ModelEntity(
                    mesh: mesh,
                    materials: [material]
                )


            joints.append(
                joint
            )


            root.addChild(
                joint
            )
        }
    }


    // MARK: - Bone Models

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
                    materials: [material]
                )


            bones.append(
                bone
            )


            root.addChild(
                bone
            )
        }
    }


    // MARK: - Frame Update

    func update(
        with hand: HandFrame
    ) {

        guard
            hand.worldLandmarks.count == 21
        else {

            root.isEnabled = false

            return
        }


        root.isEnabled =
            true


        let positions =
            makeRealityKitPositions(
                from: hand
            )


        // MARK: Joints

        for index in 0..<21 {

            joints[index].position =
                positions[index]
        }


        // MARK: Bones

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


    // MARK: - Coordinate Conversion

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

            horizontalOffset =
                0

            verticalOffset =
                0
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
