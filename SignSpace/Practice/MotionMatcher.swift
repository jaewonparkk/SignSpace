import Foundation
import simd

struct PracticeMatchResult: Identifiable {

    let id = UUID()

    let overallScore: Double
    let handShapeScore: Double
    let movementScore: Double
    let palmOrientationScore: Double
    let timingScore: Double

    let feedback: String
}


enum MotionMatcher {

    // MARK: - Public

    static func compare(
        target: SignMotion,
        user: SignMotion
    ) -> PracticeMatchResult {

        let targetHands = target.frames.compactMap {
            $0.hands.first
        }

        let userHands = user.frames.compactMap {
            $0.hands.first
        }


        guard
            !targetHands.isEmpty,
            !userHands.isEmpty
        else {

            return PracticeMatchResult(
                overallScore: 0,
                handShapeScore: 0,
                movementScore: 0,
                palmOrientationScore: 0,
                timingScore: 0,
                feedback: "Not enough hand motion was captured. Try recording again."
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


        let alignment =
            dtwAlignment(
                target: targetDescriptors,
                user: userDescriptors
            )


        guard !alignment.isEmpty else {

            return PracticeMatchResult(
                overallScore: 0,
                handShapeScore: 0,
                movementScore: 0,
                palmOrientationScore: 0,
                timingScore: 0,
                feedback: "The motions could not be aligned. Try recording the full sign again."
            )
        }


        var shapeSimilarities: [Double] = []
        var movementSimilarities: [Double] = []
        var palmSimilarities: [Double] = []


        for pair in alignment {

            let targetFrame =
                targetDescriptors[
                    pair.targetIndex
                ]

            let userFrame =
                userDescriptors[
                    pair.userIndex
                ]


            shapeSimilarities.append(
                shapeSimilarity(
                    targetFrame.shapeAngles,
                    userFrame.shapeAngles
                )
            )


            movementSimilarities.append(
                movementSimilarity(
                    targetFrame.trajectory,
                    userFrame.trajectory
                )
            )


            palmSimilarities.append(
                palmSimilarity(
                    targetFrame.palmNormal,
                    userFrame.palmNormal
                )
            )
        }


        let handShapeScore =
            average(
                shapeSimilarities
            ) * 100


        let movementScore =
            average(
                movementSimilarities
            ) * 100


        let palmScore =
            average(
                palmSimilarities
            ) * 100


        let timingScore =
            timingSimilarity(
                targetDuration:
                    target.durationSeconds,
                userDuration:
                    user.durationSeconds
            ) * 100


        let overall =
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
                clampScore(overall),

            handShapeScore:
                clampScore(handShapeScore),

            movementScore:
                clampScore(movementScore),

            palmOrientationScore:
                clampScore(palmScore),

            timingScore:
                clampScore(timingScore),

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
            let firstHand = hands.first,
            let firstWrist =
                firstHand.normalizedLandmarks.first
        else {
            return []
        }


        let palmScales =
            hands.compactMap {
                palmScale(
                    from: $0
                )
            }


        let averageScale =
            max(
                average(
                    palmScales
                ),
                0.001
            )


        return hands.map { hand in

            let wrist =
                hand.normalizedLandmarks.first
                ?? firstWrist


            let trajectory =
                SIMD2<Double>(
                    Double(
                        wrist.x
                        - firstWrist.x
                    )
                    / averageScale,

                    Double(
                        wrist.y
                        - firstWrist.y
                    )
                    / averageScale
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


        return joints.map {

            angle(
                first: points[$0.0],
                vertex: points[$0.1],
                third: points[$0.2]
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
            vectorA / lengthA

        let normalizedB =
            vectorB / lengthB


        let dot =
            simd_dot(
                normalizedA,
                normalizedB
            )


        let clamped =
            min(
                max(
                    dot,
                    -1
                ),
                1
            )


        return acos(
            Double(clamped)
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


            differences.append(
                min(
                    difference / .pi,
                    1
                )
            )
        }


        return 1
            - average(
                differences
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


        let indexVector =
            indexMCP - wrist

        let pinkyVector =
            pinkyMCP - wrist


        let normal =
            simd_cross(
                indexVector,
                pinkyVector
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


        let clamped =
            min(
                max(
                    dot,
                    -1
                ),
                1
            )


        let difference =
            acos(
                Double(clamped)
            )


        return max(
            0,
            1 - difference / .pi
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
            hand.normalizedLandmarks[0]

        let middleMCP =
            hand.normalizedLandmarks[9]


        let dx =
            Double(
                middleMCP.x - wrist.x
            )

        let dy =
            Double(
                middleMCP.y - wrist.y
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
            target.x - user.x

        let dy =
            target.y - user.y


        let distance =
            sqrt(
                dx * dx
                + dy * dy
            )


        // Roughly:
        // 0 hand-width difference = 100%
        // 2+ hand-width difference = near 0%

        return max(
            0,
            1 - min(
                distance / 2.0,
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

        let targetIndex: Int
        let userIndex: Int
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
                        target[i - 1],
                        user[j - 1]
                    )


                let bestPrevious =
                    min(
                        cost[i - 1][j],
                        cost[i][j - 1],
                        cost[i - 1][j - 1]
                    )


                cost[i][j] =
                    localCost
                    + bestPrevious
            }
        }


        var path: [AlignmentPair] = []

        var i = n
        var j = m


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
                cost[i - 1][j - 1]

            let up =
                cost[i - 1][j]

            let left =
                cost[i][j - 1]


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


        let palmDistance =
            1
            - palmSimilarity(
                target.palmNormal,
                user.palmNormal
            )


        let movementDistance =
            1
            - movementSimilarity(
                target.trajectory,
                user.trajectory
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
            (
                name: "shape",
                score: handShape
            ),
            (
                name: "movement",
                score: movement
            ),
            (
                name: "palm",
                score: palm
            ),
            (
                name: "timing",
                score: timing
            )
        ]


        guard let weakest =
                scores.min(
                    by: {
                        $0.score
                        < $1.score
                    }
                )
        else {

            return "Try the sign again and compare your motion with the target."
        }


        if weakest.score >= 85 {

            return "Strong motion match. Try it once more to build consistency."
        }


        switch weakest.name {

        case "shape":

            return "Your movement is close. Focus on matching the finger shape throughout the sign."


        case "movement":

            return "Follow the target hand path more closely from the beginning to the end of the sign."


        case "palm":

            return "Your hand shape is close, but the palm is facing a different direction. Rotate your palm to match the target."


        case "timing":

            return "The motion is similar. Try matching the target pace a little more closely."


        default:

            return "Try the sign again and compare your motion with the target."
        }
    }


    // MARK: - Utilities

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


        return values.reduce(
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
}
