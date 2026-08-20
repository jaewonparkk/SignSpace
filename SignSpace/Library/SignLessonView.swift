import SwiftUI

struct SignLessonView: View {

    let sign: SavedSign


    // MARK: - 3D

    @State private var motionToExplore:
        SignMotion?


    // MARK: - Practice

    @State private var showPractice =
        false

    @State private var practiceAttempt:
        SignMotion?

    @State private var pendingResult:
        PracticeMatchResult?

    @State private var resultToShow:
        PracticeMatchResult?


    // MARK: - Body

    var body: some View {

        ZStack {

            Color(
                red: 1.0,
                green: 0.97,
                blue: 0.95
            )
            .ignoresSafeArea()


            if let motion =
                sign.targetMotion {

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 22
                    ) {

                        titleSection

                        preview(
                            motion
                        )

                        howItMoves

                        whatToNotice

                        actions(
                            motion
                        )


                        Spacer(
                            minLength: 40
                        )
                    }
                    .padding(
                        .top,
                        10
                    )
                }

            } else {

                brokenLesson
            }
        }
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            item:
                $motionToExplore
        ) { motion in

            NavigationStack {

                SignViewerView(
                    motion: motion
                )
            }
        }
        .fullScreenCover(
            isPresented:
                $showPractice,
            onDismiss: {

                guard let result =
                        pendingResult
                else {
                    return
                }


                pendingResult =
                    nil


                DispatchQueue.main.asyncAfter(
                    deadline:
                        .now() + 0.2
                ) {

                    resultToShow =
                        result
                }
            }
        ) {

            if let motion =
                sign.targetMotion {

                NavigationStack {

                    TryItYourselfView(
                        targetMotion:
                            motion
                    ) { attempt in

                        practiceAttempt =
                            attempt


                        pendingResult =
                            MotionMatcher.compare(
                                target:
                                    motion,
                                user:
                                    attempt
                            )
                    }
                }
            }
        }
        .sheet(
            item:
                $resultToShow
        ) { result in

            if
                let target =
                    sign.targetMotion,
                let attempt =
                    practiceAttempt {

                NavigationStack {

                    PracticeResultView(
                        targetMotion:
                            target,
                        userMotion:
                            attempt,
                        result:
                            result
                    )
                }
            }
        }
    }


    // MARK: - Title

    private var titleSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                sign.name
            )
            .font(
                .system(
                    size: 36,
                    weight: .bold,
                    design: .rounded
                )
            )


            HStack(
                spacing: 8
            ) {

                badge(
                    sign.difficulty
                )


                Text("·")


                Text(
                    sign.handDescription
                )


                Text("·")


                Text(
                    sign.durationText
                )
            }
            .font(
                .subheadline
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding(
            .horizontal,
            22
        )
    }


    // MARK: - Preview

    private func preview(
        _ motion: SignMotion
    ) -> some View {

        ZStack {

            if !motion.frames.isEmpty {

                RealityKitHandView(
                    motion:
                        motion,
                    currentFrameIndex:
                        min(
                            motion.frames.count / 2,
                            motion.frames.count - 1
                        ),
                    yaw:
                        0,
                    pitch:
                        0,
                    zoom:
                        0.9,
                    showTrail:
                        true
                )

            } else {

                Color.black
            }


            VStack {

                HStack {

                    Text(
                        "3D Preview"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .padding(
                        .horizontal,
                        12
                    )
                    .padding(
                        .vertical,
                        8
                    )
                    .background(
                        .black.opacity(
                            0.4
                        )
                    )
                    .clipShape(
                        Capsule()
                    )


                    Spacer()
                }
                .padding(14)


                Spacer()


                Text(
                    "Rotate and inspect the full motion in Explore in 3D."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.8
                    )
                )
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .vertical,
                    9
                )
                .background(
                    .black.opacity(
                        0.4
                    )
                )
                .clipShape(
                    Capsule()
                )
                .padding(
                    .bottom,
                    14
                )
            }
        }
        .frame(
            height: 300
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
        )
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - How It Moves

    private var howItMoves: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                "How it moves"
            )
            .font(
                .system(
                    size: 20,
                    weight: .bold,
                    design: .rounded
                )
            )


            Text(
                sign.lessonDescription.isEmpty
                ? "Explore the movement in 3D, then try matching it yourself."
                : sign.lessonDescription
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
        .padding(
            .horizontal,
            22
        )
    }


    // MARK: - Notice

    private var whatToNotice: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "What to notice"
            )
            .font(
                .system(
                    size: 20,
                    weight: .bold,
                    design: .rounded
                )
            )


            if sign.notices.isEmpty {

                noticeRow(
                    "Watch the hand shape, palm orientation, and movement path."
                )

            } else {

                ForEach(
                    sign.notices,
                    id: \.self
                ) { notice in

                    noticeRow(
                        notice
                    )
                }
            }
        }
        .padding(20)
        .background(
            Color.white.opacity(
                0.72
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


    private func noticeRow(
        _ text: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(
                systemName:
                    "checkmark.circle.fill"
            )
            .foregroundStyle(
                accent
            )
            .padding(
                .top,
                1
            )


            Text(text)
                .font(
                    .system(
                        size: 15
                    )
                )
        }
    }


    // MARK: - Actions

    private func actions(
        _ motion: SignMotion
    ) -> some View {

        VStack(
            spacing: 12
        ) {

            Button {

                motionToExplore =
                    motion

            } label: {

                HStack {

                    Image(
                        systemName:
                            "cube.transparent"
                    )


                    Text(
                        "Explore in 3D"
                    )
                    .fontWeight(
                        .semibold
                    )


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
                    19
                )
                .frame(
                    height: 58
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


            Button {

                practiceAttempt =
                    nil

                pendingResult =
                    nil

                resultToShow =
                    nil

                showPractice =
                    true

            } label: {

                HStack {

                    Image(
                        systemName:
                            "camera.fill"
                    )


                    Text(
                        "Try It Yourself"
                    )
                    .fontWeight(
                        .semibold
                    )


                    Spacer()


                    Image(
                        systemName:
                            "chevron.right"
                    )
                }
                .foregroundStyle(
                    accent
                )
                .padding(
                    .horizontal,
                    19
                )
                .frame(
                    height: 58
                )
                .background(
                    Color.white
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .stroke(
                        accent.opacity(
                            0.22
                        ),
                        lineWidth: 1
                    )
                }
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
        }
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Broken Lesson

    private var brokenLesson: some View {

        VStack(
            spacing: 14
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(
                    size: 38
                )
            )


            Text(
                "Motion data unavailable"
            )
            .font(
                .headline
            )


            Text(
                "This lesson's recorded motion could not be loaded."
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                .secondary
            )
        }
    }


    // MARK: - Badge

    private func badge(
        _ text: String
    ) -> some View {

        Text(text)
            .font(
                .system(
                    size: 12,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                accent
            )
            .padding(
                .horizontal,
                9
            )
            .padding(
                .vertical,
                5
            )
            .background(
                Color(
                    red: 1.0,
                    green: 0.89,
                    blue: 0.93
                )
            )
            .clipShape(
                Capsule()
            )
    }


    private var accent: Color {

        Color(
            red: 0.95,
            green: 0.37,
            blue: 0.55
        )
    }
}
