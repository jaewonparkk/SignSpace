import Foundation
import simd


// MARK: - Practice Result

struct PracticeMatchResult: Identifiable {

    let id = UUID()

    let overallScore: Double

    let handShapeScore: Double

    let movementScore: Double

    let palmOrientationScore: Double

    let timingScore: Double

    let feedback: String
}


// MARK: - Motion Matcher

enum MotionMatcher {

    // MARK: Public

    static func compare(
        target: SignMotion,
        user: SignMotion
    ) -> PracticeMatchResult {

        let targetHands =
            target.frames.compactMap {
                $0.hands.first
            }

        let userHands =
            user.frames.compactMap {
                $0.hands.first
            }


        guard
            !targetHands.isEmpty,
            !userHands.isEmpty
        else {

            return emptyResult(
                feedback:
                    "Not enough hand motion was captured. Try recording the sign again."
            )
        }


        let targetDescriptors =
            makeDescriptors(
                from: targetHands
            )

        let userDescriptors =
            makeDescriptors(
                from: userHands
            )


        guard
            !targetDescriptors.isEmpty,
            !userDescriptors.isEmpty
        else {

            return emptyResult(
                feedback:
                    "We couldn't analyze enough landmarks. Try recording again with your hand fully visible."
            )
        }


        let alignment =
            dtwAlignment(
                target: targetDescriptors,
                user: userDescriptors
            )


        guard !alignment.isEmpty else {

            return emptyResult(
                feedback:
                    "The two motions could not be aligned. Try performing the complete sign again."
            )
        }


        var shapeScores: [Double] = []

        var movementScores: [Double] = []

        var palmScores: [Double] = []


        for pair in alignment {

            let targetFrame =
                targetDescriptors[
                    pair.targetIndex
                ]

            let userFrame =
                userDescriptors[
                    pair.userIndex
                ]


            shapeScores.append(
                shapeSimilarity(
                    targetFrame.shapeAngles,
                    userFrame.shapeAngles
                )
            )


            movementScores.append(
                movementSimilarity(
                    targetFrame.trajectory,
                    userFrame.trajectory
                )
            )


            palmScores.append(
                palmSimilarity(
                    targetFrame.palmNormal,
                    userFrame.palmNormal
                )
            )
        }


        let handShapeScore =
            average(shapeScores)
            * 100


        let movementScore =
            average(movementScores)
            * 100


        let palmScore =
            average(palmScores)
            * 100


        let timingScore =
            timingSimilarity(
                targetDuration:
                    target.durationSeconds,
                userDuration:
                    user.durationSeconds
            )
            * 100


        // Shape matters most.
        // Movement is second.
        // Palm direction is especially important
        // for spatial sign learning.

        let overallScore =
            handShapeScore * 0.40
            + movementScore * 0.30
            + palmScore * 0.20
            + timingScore * 0.10


        let feedback =
            makeFeedback(
                handShape:
                    handShapeScore,
                movement:
                    movementScore,
                palm:
                    palmScore,
                timing:
                    timingScore
            )


        return PracticeMatchResult(
            overallScore:
                clampScore(
                    overallScore
                ),

            handShapeScore:
                clampScore(
                    handShapeScore
                ),

            movementScore:
                clampScore(
                    movementScore
                ),

            palmOrientationScore:
                clampScore(
                    palmScore
                ),

            timingScore:
                clampScore(
                    timingScore
                ),

            feedback:
                feedback
        )
    }


    // MARK: - Descriptor

    private struct FrameDescriptor {

        let shapeAngles: [Double]

        let palmNormal:
            SIMD3<Float>?

        let trajectory:
            SIMD2<Double>
    }


    private static func makeDescriptors(
        from hands: [HandFrame]
    ) -> [FrameDescriptor] {

        guard
            let firstHand =
                hands.first,

            let firstWrist =
                firstHand
                    .normalizedLandmarks
                    .first
        else {

            return []
        }


        let scales =
            hands.compactMap {
                palmScale(
                    from: $0
                )
            }


        let averagePalmScale =
            max(
                average(scales),
                0.001
            )


        return hands.map { hand in

            let wrist =
                hand
                    .normalizedLandmarks
                    .first
                ?? firstWrist


            let deltaX =
                Double(
                    wrist.x
                    - firstWrist.x
                )


            let deltaY =
                Double(
                    wrist.y
                    - firstWrist.y
                )


            // Position measured approximately
            // in "hand lengths" rather than pixels.

            let trajectory =
                SIMD2<Double>(
                    deltaX
                    / averagePalmScale,

                    deltaY
                    / averagePalmScale
                )


            return FrameDescriptor(
                shapeAngles:
                    shapeAngles(
                        from: hand
                    ),

                palmNormal:
                    palmNormal(
                        from: hand
                    ),

                trajectory:
                    trajectory
            )
        }
    }


    // MARK: - Hand Shape

    private static func shapeAngles(
        from hand: HandFrame
    ) -> [Double] {

        guard
            hand.worldLandmarks.count >= 21
        else {

            return []
        }


        let points =
            hand.worldLandmarks.map {

                SIMD3<Float>(
                    $0.x,
                    $0.y,
                    $0.z
                )
            }


        // Two bending angles per finger.

        let joints: [(Int, Int, Int)] = [

            // Thumb
            (1, 2, 3),
            (2, 3, 4),

            // Index
            (5, 6, 7),
            (6, 7, 8),

            // Middle
            (9, 10, 11),
            (10, 11, 12),

            // Ring
            (13, 14, 15),
            (14, 15, 16),

            // Pinky
            (17, 18, 19),
            (18, 19, 20)
        ]


        return joints.map { joint in

            angle(
                first:
                    points[
                        joint.0
                    ],

                vertex:
                    points[
                        joint.1
                    ],

                third:
                    points[
                        joint.2
                    ]
            )
        }
    }


    private static func angle(
        first: SIMD3<Float>,
        vertex: SIMD3<Float>,
        third: SIMD3<Float>
    ) -> Double {

        let vectorA =
            first - vertex

        let vectorB =
            third - vertex


        let lengthA =
            simd_length(
                vectorA
            )

        let lengthB =
            simd_length(
                vectorB
            )


        guard
            lengthA > 0.000001,
            lengthB > 0.000001
        else {

            return 0
        }


        let normalizedA =
            vectorA
            / lengthA

        let normalizedB =
            vectorB
            / lengthB


        let dot =
            simd_dot(
                normalizedA,
                normalizedB
            )


        let clampedDot =
            min(
                max(
                    Double(dot),
                    -1.0
                ),
                1.0
            )


        return acos(
            clampedDot
        )
    }


    private static func shapeSimilarity(
        _ target: [Double],
        _ user: [Double]
    ) -> Double {

        guard
            !target.isEmpty,
            target.count == user.count
        else {

            return 0
        }


        var differences: [Double] = []


        for index in target.indices {

            let difference =
                abs(
                    target[index]
                    - user[index]
                )


            // 0 rad difference = perfect.
            // Around 70 degrees difference
            // is considered strongly different.

            let normalizedDifference =
                min(
                    difference / 1.22,
                    1
                )


            differences.append(
                normalizedDifference
            )
        }


        return max(
            0,
            1 - average(
                differences
            )
        )
    }


    // MARK: - Palm Orientation

    private static func palmNormal(
        from hand: HandFrame
    ) -> SIMD3<Float>? {

        guard
            hand.worldLandmarks.count >= 21
        else {

            return nil
        }


        let wrist =
            vector(
                hand.worldLandmarks[0]
            )


        let indexMCP =
            vector(
                hand.worldLandmarks[5]
            )


        let pinkyMCP =
            vector(
                hand.worldLandmarks[17]
            )


        let indexDirection =
            indexMCP
            - wrist

        let pinkyDirection =
            pinkyMCP
            - wrist


        let normal =
            simd_cross(
                indexDirection,
                pinkyDirection
            )


        let length =
            simd_length(
                normal
            )


        guard length > 0.000001 else {

            return nil
        }


        return normal / length
    }


    private static func palmSimilarity(
        _ target: SIMD3<Float>?,
        _ user: SIMD3<Float>?
    ) -> Double {

        guard
            let target,
            let user
        else {

            return 0.5
        }


        let dot =
            simd_dot(
                target,
                user
            )


        let clampedDot =
            min(
                max(
                    Double(dot),
                    -1.0
                ),
                1.0
            )


        let angularDifference =
            acos(
                clampedDot
            )


        // 0 degrees -> 1.0
        // 90+ degrees -> ~0

        return max(
            0,
            1 - min(
                angularDifference
                / (.pi / 2),
                1
            )
        )
    }


    // MARK: - Movement

    private static func palmScale(
        from hand: HandFrame
    ) -> Double? {

        guard
            hand.normalizedLandmarks.count > 9
        else {

            return nil
        }


        let wrist =
            hand
                .normalizedLandmarks[0]

        let middleMCP =
            hand
                .normalizedLandmarks[9]


        let dx =
            Double(
                middleMCP.x
                - wrist.x
            )


        let dy =
            Double(
                middleMCP.y
                - wrist.y
            )


        return sqrt(
            dx * dx
            + dy * dy
        )
    }


    private static func movementSimilarity(
        _ target: SIMD2<Double>,
        _ user: SIMD2<Double>
    ) -> Double {

        let deltaX =
            target.x
            - user.x

        let deltaY =
            target.y
            - user.y


        let distance =
            sqrt(
                deltaX * deltaX
                + deltaY * deltaY
            )


        // About 1.5 hand lengths away
        // is treated as very different.

        return max(
            0,
            1 - min(
                distance / 1.5,
                1
            )
        )
    }


    // MARK: - Timing

    private static func timingSimilarity(
        targetDuration: Double,
        userDuration: Double
    ) -> Double {

        guard
            targetDuration > 0,
            userDuration > 0
        else {

            return 0
        }


        return min(
            targetDuration,
            userDuration
        )
        /
        max(
            targetDuration,
            userDuration
        )
    }


    // MARK: - Dynamic Time Warping

    private struct AlignmentPair {

        let targetIndex: Int

        let userIndex: Int
    }


    private static func dtwAlignment(
        target: [FrameDescriptor],
        user: [FrameDescriptor]
    ) -> [AlignmentPair] {

        let targetCount =
            target.count

        let userCount =
            user.count


        guard
            targetCount > 0,
            userCount > 0
        else {

            return []
        }


        var cost =
            Array(
                repeating:
                    Array(
                        repeating:
                            Double.infinity,
                        count:
                            userCount + 1
                    ),
                count:
                    targetCount + 1
            )


        cost[0][0] = 0


        for targetIndex in 1...targetCount {

            for userIndex in 1...userCount {

                let localCost =
                    descriptorDistance(
                        target[
                            targetIndex - 1
                        ],
                        user[
                            userIndex - 1
                        ]
                    )


                let diagonal =
                    cost[
                        targetIndex - 1
                    ][
                        userIndex - 1
                    ]


                let vertical =
                    cost[
                        targetIndex - 1
                    ][
                        userIndex
                    ]


                let horizontal =
                    cost[
                        targetIndex
                    ][
                        userIndex - 1
                    ]


                let bestPrevious =
                    min(
                        diagonal,
                        min(
                            vertical,
                            horizontal
                        )
                    )


                cost[
                    targetIndex
                ][
                    userIndex
                ] =
                    localCost
                    + bestPrevious
            }
        }


        // MARK: Recover alignment path

        var path: [AlignmentPair] = []


        var targetIndex =
            targetCount

        var userIndex =
            userCount


        while
            targetIndex > 0,
            userIndex > 0 {

            path.append(
                AlignmentPair(
                    targetIndex:
                        targetIndex - 1,
                    userIndex:
                        userIndex - 1
                )
            )


            let diagonal =
                cost[
                    targetIndex - 1
                ][
                    userIndex - 1
                ]


            let vertical =
                cost[
                    targetIndex - 1
                ][
                    userIndex
                ]


            let horizontal =
                cost[
                    targetIndex
                ][
                    userIndex - 1
                ]


            if
                diagonal <= vertical,
                diagonal <= horizontal {

                targetIndex -= 1

                userIndex -= 1

            } else if
                vertical <= horizontal {

                targetIndex -= 1

            } else {

                userIndex -= 1
            }
        }


        while targetIndex > 0 {

            path.append(
                AlignmentPair(
                    targetIndex:
                        targetIndex - 1,
                    userIndex:
                        0
                )
            )

            targetIndex -= 1
        }


        while userIndex > 0 {

            path.append(
                AlignmentPair(
                    targetIndex:
                        0,
                    userIndex:
                        userIndex - 1
                )
            )

            userIndex -= 1
        }


        return path.reversed()
    }


    private static func descriptorDistance(
        _ target: FrameDescriptor,
        _ user: FrameDescriptor
    ) -> Double {

        let shapeDistance =
            1
            - shapeSimilarity(
                target.shapeAngles,
                user.shapeAngles
            )


        let movementDistance =
            1
            - movementSimilarity(
                target.trajectory,
                user.trajectory
            )


        let palmDistance =
            1
            - palmSimilarity(
                target.palmNormal,
                user.palmNormal
            )


        return
            shapeDistance * 0.50
            + movementDistance * 0.30
            + palmDistance * 0.20
    }


    // MARK: - Feedback

    private static func makeFeedback(
        handShape: Double,
        movement: Double,
        palm: Double,
        timing: Double
    ) -> String {

        let categories: [
            (
                name: String,
                score: Double
            )
        ] = [

            (
                "shape",
                handShape
            ),

            (
                "movement",
                movement
            ),

            (
                "palm",
                palm
            ),

            (
                "timing",
                timing
            )
        ]


        guard
            let weakest =
                categories.min(
                    by: {
                        $0.score
                        < $1.score
                    }
                )
        else {

            return
                "Try the sign again and compare your motion with the target."
        }


        if weakest.score >= 88 {

            return
                "Your motion is very close to the target. Try it again to build consistency."
        }


        switch weakest.name {

        case "shape":

            return
                "Focus on your finger shape. Try matching how bent or extended each finger is throughout the sign."


        case "movement":

            return
                "Follow the target movement path more closely from the beginning to the end of the sign."


        case "palm":

            return
                "Your hand shape is close, but your palm is facing a different direction. Rotate your palm to better match the target."


        case "timing":

            return
                "Your motion is similar. Try matching the target's pace more closely."


        default:

            return
                "Try the sign again and compare your motion with the target."
        }
    }


    // MARK: - Helpers

    private static func vector(
        _ point: LandmarkPoint
    ) -> SIMD3<Float> {

        SIMD3<Float>(
            point.x,
            point.y,
            point.z
        )
    }


    private static func average(
        _ values: [Double]
    ) -> Double {

        guard !values.isEmpty else {
            return 0
        }


        return
            values.reduce(
                0,
                +
            )
            / Double(
                values.count
            )
    }


    private static func clampScore(
        _ score: Double
    ) -> Double {

        min(
            max(
                score,
                0
            ),
            100
        )
    }


    private static func emptyResult(
        feedback: String
    ) -> PracticeMatchResult {

        PracticeMatchResult(
            overallScore: 0,
            handShapeScore: 0,
            movementScore: 0,
            palmOrientationScore: 0,
            timingScore: 0,
            feedback: feedback
        )
    }
}
