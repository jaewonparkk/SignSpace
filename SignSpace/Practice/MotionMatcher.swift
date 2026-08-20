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

    // Keep matching lightweight enough for mobile.
    private static let maximumAnalysisFrames = 60


    // MARK: - Public

    static func compare(
        target: SignMotion,
        user: SignMotion
    ) -> PracticeMatchResult {

        // MARK: Downsample first

        let sampledTargetFrames =
            sampledFrames(
                from: target.frames,
                maximumCount: maximumAnalysisFrames
            )

        let sampledUserFrames =
            sampledFrames(
                from: user.frames,
                maximumCount: maximumAnalysisFrames
            )


        let targetHands =
            sampledTargetFrames.compactMap {
                preferredHand(
                    from: $0
                )
            }


        let userHands =
            sampledUserFrames.compactMap {
                preferredHand(
                    from: $0
                )
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
                    "We couldn't analyze enough landmarks. Keep your hand fully visible and try again."
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
                    "The motions could not be aligned. Try recording the complete sign again."
            )
        }


        var shapeTotal: Double = 0

        var movementTotal: Double = 0

        var palmTotal: Double = 0


        for pair in alignment {

            let targetFrame =
                targetDescriptors[
                    pair.targetIndex
                ]


            let userFrame =
                userDescriptors[
                    pair.userIndex
                ]


            shapeTotal +=
                shapeSimilarity(
                    targetFrame.shapeAngles,
                    userFrame.shapeAngles
                )


            movementTotal +=
                movementSimilarity(
                    targetFrame.trajectory,
                    userFrame.trajectory
                )


            palmTotal +=
                palmSimilarity(
                    targetFrame.palmNormal,
                    userFrame.palmNormal
                )
        }


        let count =
            Double(
                alignment.count
            )


        let handShapeScore =
            (shapeTotal / count)
            * 100


        let movementScore =
            (movementTotal / count)
            * 100


        let palmScore =
            (palmTotal / count)
            * 100


        let timingScore =
            timingSimilarity(
                targetDuration:
                    target.durationSeconds,
                userDuration:
                    user.durationSeconds
            )
            * 100


        let overallScore =
            handShapeScore * 0.40
            + movementScore * 0.30
            + palmScore * 0.20
            + timingScore * 0.10


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
        )
    }


    // MARK: - Frame Sampling

    private static func sampledFrames(
        from frames: [SignFrame],
        maximumCount: Int
    ) -> [SignFrame] {

        guard
            !frames.isEmpty
        else {
            return []
        }


        guard
            frames.count > maximumCount
        else {
            return frames
        }


        guard
            maximumCount > 1
        else {

            return [
                frames[0]
            ]
        }


        var result: [SignFrame] = []

        result.reserveCapacity(
            maximumCount
        )


        let lastIndex =
            frames.count - 1


        for sampleIndex in 0..<maximumCount {

            let progress =
                Double(sampleIndex)
                / Double(
                    maximumCount - 1
                )


            let frameIndex =
                Int(
                    (
                        Double(lastIndex)
                        * progress
                    )
                    .rounded()
                )


            result.append(
                frames[
                    frameIndex
                ]
            )
        }


        return result
    }


    // MARK: - Preferred Hand

    private static func preferredHand(
        from frame: SignFrame
    ) -> HandFrame? {

        if let right =
            frame.hands.first(
                where: {
                    $0.handedness == .right
                }
            ) {

            return right
        }


        if let left =
            frame.hands.first(
                where: {
                    $0.handedness == .left
                }
            ) {

            return left
        }


        return frame.hands.first
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


        var scaleTotal: Double = 0

        var scaleCount: Int = 0


        for hand in hands {

            if let scale =
                palmScale(
                    from: hand
                ) {

                scaleTotal +=
                    scale

                scaleCount +=
                    1
            }
        }


        let averagePalmScale: Double


        if scaleCount > 0 {

            averagePalmScale =
                max(
                    scaleTotal
                    / Double(
                        scaleCount
                    ),
                    0.001
                )

        } else {

            averagePalmScale =
                0.1
        }


        var descriptors:
            [FrameDescriptor] = []


        descriptors.reserveCapacity(
            hands.count
        )


        for hand in hands {

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


            let trajectory =
                SIMD2<Double>(

                    deltaX
                    / averagePalmScale,

                    deltaY
                    / averagePalmScale
                )


            descriptors.append(

                FrameDescriptor(

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
            )
        }


        return descriptors
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


        var result: [Double] = []

        result.reserveCapacity(
            joints.count
        )


        for joint in joints {

            result.append(

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
            )
        }


        return result
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


        let clamped =
            min(
                max(
                    Double(dot),
                    -1
                ),
                1
            )


        return acos(
            clamped
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


        var differenceTotal:
            Double = 0


        for index in target.indices {

            let difference =
                abs(
                    target[index]
                    - user[index]
                )


            differenceTotal +=
                min(
                    difference / 1.22,
                    1
                )
        }


        let averageDifference =
            differenceTotal
            / Double(
                target.count
            )


        return max(
            0,
            1 - averageDifference
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
            indexMCP - wrist


        let pinkyDirection =
            pinkyMCP - wrist


        let normal =
            simd_cross(
                indexDirection,
                pinkyDirection
            )


        let length =
            simd_length(
                normal
            )


        guard
            length > 0.000001
        else {

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


        let clamped =
            min(
                max(
                    Double(dot),
                    -1
                ),
                1
            )


        let difference =
            acos(
                clamped
            )


        return max(
            0,
            1 - min(
                difference
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

        let dx =
            target.x
            - user.x


        let dy =
            target.y
            - user.y


        let distance =
            sqrt(
                dx * dx
                + dy * dy
            )


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


    // MARK: - DTW

    private struct AlignmentPair {

        let targetIndex:
            Int

        let userIndex:
            Int
    }


    private static func dtwAlignment(
        target: [FrameDescriptor],
        user: [FrameDescriptor]
    ) -> [AlignmentPair] {

        let n =
            target.count


        let m =
            user.count


        guard
            n > 0,
            m > 0
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
                            m + 1
                    ),
                count:
                    n + 1
            )


        cost[0][0] =
            0


        for i in 1...n {

            for j in 1...m {

                let localCost =
                    descriptorDistance(
                        target[
                            i - 1
                        ],
                        user[
                            j - 1
                        ]
                    )


                let bestPrevious =
                    min(
                        cost[
                            i - 1
                        ][
                            j - 1
                        ],
                        min(
                            cost[
                                i - 1
                            ][
                                j
                            ],
                            cost[
                                i
                            ][
                                j - 1
                            ]
                        )
                    )


                cost[
                    i
                ][
                    j
                ] =
                    localCost
                    + bestPrevious
            }
        }


        var path:
            [AlignmentPair] = []


        path.reserveCapacity(
            n + m
        )


        var i =
            n


        var j =
            m


        while
            i > 0,
            j > 0 {

            path.append(

                AlignmentPair(
                    targetIndex:
                        i - 1,
                    userIndex:
                        j - 1
                )
            )


            let diagonal =
                cost[
                    i - 1
                ][
                    j - 1
                ]


            let up =
                cost[
                    i - 1
                ][
                    j
                ]


            let left =
                cost[
                    i
                ][
                    j - 1
                ]


            if
                diagonal <= up,
                diagonal <= left {

                i -= 1
                j -= 1

            } else if up <= left {

                i -= 1

            } else {

                j -= 1
            }
        }


        while i > 0 {

            path.append(

                AlignmentPair(
                    targetIndex:
                        i - 1,
                    userIndex:
                        0
                )
            )


            i -= 1
        }


        while j > 0 {

            path.append(

                AlignmentPair(
                    targetIndex:
                        0,
                    userIndex:
                        j - 1
                )
            )


            j -= 1
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

        let scores = [

            ("shape", handShape),

            ("movement", movement),

            ("palm", palm),

            ("timing", timing)
        ]


        guard let weakest =
            scores.min(
                by: {
                    $0.1 < $1.1
                }
            )
        else {

            return
                "Try the sign again and compare your movement with the target."
        }


        if weakest.1 >= 88 {

            return
                "Your motion is very close to the target. Try it again to build consistency."
        }


        switch weakest.0 {

        case "shape":

            return
                "Focus on your finger shape. Match how bent or extended each finger is throughout the sign."


        case "movement":

            return
                "Follow the target hand path more closely from the beginning to the end of the sign."


        case "palm":

            return
                "Your hand shape is close, but your palm is facing a different direction. Rotate your palm to better match the target."


        case "timing":

            return
                "Your motion is similar. Try matching the target pace more closely."


        default:

            return
                "Try the sign again and compare your movement with the target."
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
