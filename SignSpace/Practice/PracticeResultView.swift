import SwiftUI

struct PracticeResultView: View {

    let targetMotion: SignMotion

    let userMotion: SignMotion

    let result: PracticeMatchResult


    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss


    // MARK: - Comparison

    @State private var showGhostComparison =
        false


    // MARK: - Body

    var body: some View {

        ZStack {

            Color(
                red: 1.0,
                green: 0.97,
                blue: 0.95
            )
            .ignoresSafeArea()


            ScrollView {

                VStack(
                    spacing: 22
                ) {

                    header

                    overallCard

                    categoryCard

                    feedbackCard

                    ghostButton

                    recordingComparison

                    doneButton

                    disclaimer

                    Spacer(
                        minLength: 30
                    )
                }
                .padding(
                    .top,
                    24
                )
            }
        }
        .navigationTitle(
            targetMotion.name
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .fullScreenCover(
            isPresented:
                $showGhostComparison
        ) {

            NavigationStack {

                GhostComparisonView(
                    targetMotion:
                        targetMotion,
                    userMotion:
                        userMotion
                )
            }
        }
    }


    // MARK: - Header

    private var header: some View {

        VStack(
            spacing: 8
        ) {

            Image(
                systemName:
                    "hand.raised.fill"
            )
            .font(
                .system(
                    size: 32
                )
            )
            .foregroundStyle(
                accent
            )


            Text(
                "Practice Result"
            )
            .font(
                .system(
                    size: 30,
                    weight: .bold,
                    design: .rounded
                )
            )


            Text(
                "Here's how your movement compared with the target."
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .secondary
            )
            .multilineTextAlignment(
                .center
            )
        }
        .padding(
            .horizontal,
            28
        )
    }


    // MARK: - Overall

    private var overallCard: some View {

        VStack(
            spacing: 16
        ) {

            ZStack {

                Circle()
                    .stroke(
                        Color.gray.opacity(
                            0.14
                        ),
                        lineWidth: 14
                    )


                Circle()
                    .trim(
                        from: 0,
                        to:
                            CGFloat(
                                result.overallScore
                                / 100
                            )
                    )
                    .stroke(
                        accent,
                        style:
                            StrokeStyle(
                                lineWidth: 14,
                                lineCap: .round
                            )
                    )
                    .rotationEffect(
                        .degrees(-90)
                    )


                VStack(
                    spacing: 1
                ) {

                    Text(
                        "\(Int(result.overallScore.rounded()))"
                    )
                    .font(
                        .system(
                            size: 44,
                            weight: .bold,
                            design: .rounded
                        )
                    )


                    Text(
                        "overall"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .frame(
                width: 155,
                height: 155
            )


            Text(
                scoreMessage
            )
            .font(
                .system(
                    size: 18,
                    weight: .semibold,
                    design: .rounded
                )
            )
        }
        .padding(26)
        .frame(
            maxWidth:
                .infinity
        )
        .background(
            Color.white.opacity(
                0.82
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Categories

    private var categoryCard: some View {

        VStack(
            spacing: 0
        ) {

            scoreRow(
                icon:
                    "hand.point.up.left.fill",
                title:
                    "Hand Shape",
                score:
                    result.handShapeScore
            )


            Divider()
                .padding(
                    .leading,
                    54
                )


            scoreRow(
                icon:
                    "point.topleft.down.to.point.bottomright.curvepath",
                title:
                    "Movement Path",
                score:
                    result.movementScore
            )


            Divider()
                .padding(
                    .leading,
                    54
                )


            scoreRow(
                icon:
                    "rotate.3d",
                title:
                    "Palm Orientation",
                score:
                    result.palmOrientationScore
            )


            Divider()
                .padding(
                    .leading,
                    54
                )


            scoreRow(
                icon:
                    "metronome.fill",
                title:
                    "Timing",
                score:
                    result.timingScore
            )
        }
        .padding(
            .horizontal,
            18
        )
        .background(
            Color.white.opacity(
                0.82
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .padding(
            .horizontal,
            20
        )
    }


    private func scoreRow(
        icon: String,
        title: String,
        score: Double
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            Image(
                systemName:
                    icon
            )
            .font(
                .system(
                    size: 18
                )
            )
            .frame(
                width: 28
            )


            Text(
                title
            )
            .font(
                .system(
                    size: 16,
                    weight: .medium
                )
            )


            Spacer()


            Text(
                "\(Int(score.rounded()))%"
            )
            .font(
                .system(
                    size: 17,
                    weight: .bold,
                    design: .rounded
                )
            )


            Image(
                systemName:
                    score >= 80
                    ? "checkmark.circle.fill"
                    : "exclamationmark.circle.fill"
            )
            .foregroundStyle(
                score >= 80
                ? Color.green
                : Color.orange
            )
        }
        .padding(
            .vertical,
            17
        )
    }


    // MARK: - Feedback

    private var feedbackCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(
                spacing: 8
            ) {

                Image(
                    systemName:
                        "sparkles"
                )


                Text(
                    "Focus next"
                )
                .font(
                    .headline
                )
            }


            Text(
                result.feedback
            )
            .font(
                .system(
                    size: 16
                )
            )
            .foregroundStyle(
                .secondary
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color(
                red: 1.0,
                green: 0.90,
                blue: 0.93
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Ghost Button

    private var ghostButton: some View {

        Button {

            showGhostComparison =
                true

        } label: {

            HStack(
                spacing: 12
            ) {

                Image(
                    systemName:
                        "square.3.layers.3d"
                )


                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(
                        "View Ghost Comparison"
                    )
                    .fontWeight(
                        .semibold
                    )


                    Text(
                        "Overlay your motion with the target"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.78
                        )
                    )
                }


                Spacer()


                Image(
                    systemName:
                        "chevron.right"
                )
            }
            .foregroundStyle(
                .white
            )
            .padding(
                .horizontal,
                18
            )
            .frame(
                height: 64
            )
            .background(
                accent
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
        }
        .buttonStyle(
            .plain
        )
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Recording Comparison

    private var recordingComparison: some View {

        HStack {

            recordingStat(
                title:
                    "Target",
                frames:
                    targetMotion.frameCount,
                duration:
                    targetMotion.durationSeconds
            )


            Spacer()


            Image(
                systemName:
                    "arrow.left.arrow.right"
            )
            .foregroundStyle(
                .secondary
            )


            Spacer()


            recordingStat(
                title:
                    "You",
                frames:
                    userMotion.frameCount,
                duration:
                    userMotion.durationSeconds
            )
        }
        .padding(18)
        .background(
            Color.white.opacity(
                0.68
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .padding(
            .horizontal,
            20
        )
    }


    private func recordingStat(
        title: String,
        frames: Int,
        duration: Double
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(
                title
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )


            Text(
                "\(frames) frames"
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold,
                    design: .rounded
                )
            )


            Text(
                String(
                    format:
                        "%.2fs",
                    duration
                )
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }


    // MARK: - Done

    private var doneButton: some View {

        Button {

            dismiss()

        } label: {

            HStack {

                Text(
                    "Back to Sign"
                )
                .fontWeight(
                    .semibold
                )


                Spacer()


                Image(
                    systemName:
                        "arrow.right"
                )
            }
            .foregroundStyle(
                .white
            )
            .padding(
                .horizontal,
                20
            )
            .frame(
                height: 56
            )
            .background(
                Color.black
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
        }
        .buttonStyle(
            .plain
        )
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Disclaimer

    private var disclaimer: some View {

        Text(
            "Scores measure similarity to the recorded target motion, not linguistic correctness."
        )
        .font(
            .caption
        )
        .foregroundStyle(
            .secondary
        )
        .multilineTextAlignment(
            .center
        )
        .padding(
            .horizontal,
            34
        )
    }


    // MARK: - Helpers

    private var accent: Color {

        Color(
            red: 0.95,
            green: 0.37,
            blue: 0.55
        )
    }


    private var scoreMessage: String {

        switch result.overallScore {

        case 90...:

            return "Very close"


        case 80..<90:

            return "Strong attempt"


        case 65..<80:

            return "Getting there"


        default:

            return "Keep practicing"
        }
    }
}
