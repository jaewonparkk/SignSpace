//
//  HandSkeletonRenderer.swift
//  SignSpace
//
//  Created by Jaewon Park on 8/18/26.
//

import Foundation
import RealityKit
import UIKit
import simd

final class HandSkeletonRenderer {

    // MARK: - Root

    let root = Entity()

    private var handSkeletons: [HandSkeletonEntity] = []


    // MARK: - Update

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


    // MARK: - Camera / User Transform

    func setViewTransform(
        yaw: Float,
        pitch: Float,
        zoom: Float
    ) {

        let yawRotation = simd_quatf(
            angle: yaw,
            axis: SIMD3<Float>(0, 1, 0)
        )

        let pitchRotation = simd_quatf(
            angle: pitch,
            axis: SIMD3<Float>(1, 0, 0)
        )

        root.orientation =
            yawRotation * pitchRotation

        root.scale =
            SIMD3<Float>(
                repeating: zoom
            )
    }


    // MARK: - Setup

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

        /*
         Cylinder height is 1 meter here.

         We scale its Y axis every frame
         so its final length matches the
         distance between two landmarks.
         */

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

        guard hand.worldLandmarks.count == 21 else {
            root.isEnabled = false
            return
        }

        root.isEnabled = true


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

        /*
         MediaPipe hand-world coordinates
         give us local 3D hand geometry.

         For this first viewer, we also use
         the normalized wrist location to
         retain some of the hand's movement
         across the camera frame.
         */

        let wrist =
            hand.normalizedLandmarks.first


        let horizontalOffset: Float

        let verticalOffset: Float


        if let wrist {

            horizontalOffset =
                (wrist.x - 0.5) * 0.45

            verticalOffset =
                (0.5 - wrist.y) * 0.55

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
                local * handScale
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


        // Position at the midpoint.

        bone.position =
            (start + end) / 2


        // Thin cylinder with the correct length.

        bone.scale =
            SIMD3<Float>(
                0.0026,
                length,
                0.0026
            )


        // RealityKit cylinders point along Y.
        // Rotate Y to point toward the next joint.

        let normalizedDirection =
            direction / length


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
