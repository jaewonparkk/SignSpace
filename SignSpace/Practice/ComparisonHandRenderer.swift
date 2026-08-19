import Foundation
import RealityKit
import UIKit
import simd

final class ComparisonHandRenderer {

    let root = Entity()

    private let targetSkeleton = ComparisonSkeletonEntity(
        jointColor: UIColor(
            red: 1.0,
            green: 0.34,
            blue: 0.58,
            alpha: 1.0
        ),
        boneColor: UIColor(
            red: 1.0,
            green: 0.72,
            blue: 0.80,
            alpha: 1.0
        )
    )

    private let userSkeleton = ComparisonSkeletonEntity(
        jointColor: UIColor(
            white: 1.0,
            alpha: 0.55
        ),
        boneColor: UIColor(
            white: 1.0,
            alpha: 0.42
        )
    )

    init() {

        root.addChild(
            targetSkeleton.root
        )

        root.addChild(
            userSkeleton.root
        )
    }


    // MARK: - Update

    func update(
        targetFrame: SignFrame,
        userFrame: SignFrame,
        targetReference: HandFrame?,
        userReference: HandFrame?
    ) {

        if let targetHand =
            targetFrame.hands.first {

            targetSkeleton.root.isEnabled =
                true

            targetSkeleton.update(
                hand: targetHand,
                referenceHand: targetReference
            )

        } else {

            targetSkeleton.root.isEnabled =
                false
        }


        if let userHand =
            userFrame.hands.first {

            userSkeleton.root.isEnabled =
                true

            userSkeleton.update(
                hand: userHand,
                referenceHand: userReference
            )

        } else {

            userSkeleton.root.isEnabled =
                false
        }
    }


    // MARK: - View

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
}


// MARK: - Skeleton

private final class ComparisonSkeletonEntity {

    let root = Entity()

    private var joints: [ModelEntity] = []

    private var bones: [ModelEntity] = []


    private let jointColor: UIColor

    private let boneColor: UIColor


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

    init(
        jointColor: UIColor,
        boneColor: UIColor
    ) {

        self.jointColor =
            jointColor

        self.boneColor =
            boneColor


        createJoints()

        createBones()
    }


    // MARK: - Create Joints

    private func createJoints() {

        let mesh =
            MeshResource.generateSphere(
                radius: 0.0048
            )


        let material =
            UnlitMaterial(
                color: jointColor
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


    // MARK: - Create Bones

    private func createBones() {

        let mesh =
            MeshResource.generateCylinder(
                height: 1.0,
                radius: 1.0
            )


        let material =
            UnlitMaterial(
                color: boneColor
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
        hand: HandFrame,
        referenceHand: HandFrame?
    ) {

        guard
            hand.worldLandmarks.count == 21
        else {

            root.isEnabled =
                false

            return
        }


        root.isEnabled =
            true


        let positions =
            normalizedPositions(
                hand: hand,
                referenceHand: referenceHand
            )


        for index in 0..<21 {

            joints[index].position =
                positions[index]
        }


        for (
            boneIndex,
            connection
        ) in connections.enumerated() {

            updateBone(
                bones[boneIndex],
                from:
                    positions[
                        connection.0
                    ],
                to:
                    positions[
                        connection.1
                    ]
            )
        }
    }


    // MARK: - Normalized Position

    private func normalizedPositions(
        hand: HandFrame,
        referenceHand: HandFrame?
    ) -> [SIMD3<Float>] {

        let world =
            hand.worldLandmarks.map {

                SIMD3<Float>(
                    $0.x,
                    -$0.y,
                    -$0.z
                )
            }


        guard
            let currentWrist =
                hand.normalizedLandmarks.first
        else {

            return world.map {
                $0 * 1.5
            }
        }


        let referenceWrist =
            referenceHand?
                .normalizedLandmarks
                .first
            ?? currentWrist


        let scale =
            max(
                palmScale(
                    from:
                        referenceHand
                        ?? hand
                ),
                0.03
            )


        // Movement relative to the first frame.
        // This reduces differences caused only
        // by where the user stood in the camera.

        let deltaX =
            Float(
                currentWrist.x
                - referenceWrist.x
            )
            / scale


        let deltaY =
            Float(
                currentWrist.y
                - referenceWrist.y
            )
            / scale


        let movementOffset =
            SIMD3<Float>(
                deltaX * 0.10,
                -deltaY * 0.10,
                0
            )


        let handScale: Float =
            1.5


        return world.map {

            $0 * handScale
            + movementOffset
        }
    }


    // MARK: - Palm Scale

    private func palmScale(
        from hand: HandFrame
    ) -> Float {

        guard
            hand.normalizedLandmarks.count > 9
        else {

            return 0.1
        }


        let wrist =
            hand.normalizedLandmarks[0]


        let middle =
            hand.normalizedLandmarks[9]


        let dx =
            wrist.x - middle.x


        let dy =
            wrist.y - middle.y


        return sqrt(
            dx * dx
            + dy * dy
        )
    }


    // MARK: - Bone

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
                0.0024,
                length,
                0.0024
            )


        bone.orientation =
            simd_quatf(
                from:
                    SIMD3<Float>(
                        0,
                        1,
                        0
                    ),
                to:
                    direction
                    / length
            )
    }
}
