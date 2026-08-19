import SwiftUI

struct SignViewerView: View {

    let motion: SignMotion


    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss


    // MARK: - Playback

    @State private var currentFrameIndex = 0

    @State private var isPlaying = false

    @State private var playbackSpeed: Double = 1.0


    // MARK: - 3D View

    @State private var yaw: Float = 0

    @State private var pitch: Float = 0

    @State private var zoom: Float = 1.0

    @State private var showTrail = true


    // MARK: - View Presets

    private enum ViewPreset {

        case front
        case side
        case top
        case custom
    }


    @State private var viewPreset:
        ViewPreset = .front


    // MARK: - Practice

    @State private var showPractice = false

    @State private var practiceAttempt:
        SignMotion?

    @State private var pendingPracticeResult:
        PracticeMatchResult?

    @State private var practiceResultToShow:
        PracticeMatchResult?


    // MARK: - Gesture State

    @State private var previousDrag:
        CGSize = .zero

    @State private var previousMagnification:
        CGFloat = 1.0


    // MARK: - Body

    var body: some View {

        ZStack {

            Color(
                red: 0.98,
                green: 0.96,
                blue: 0.95
            )
            .ignoresSafeArea()


            VStack(
                spacing: 0
            ) {

                viewer

                controls
            }
        }
        .navigationTitle(
            motion.name
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {

            ToolbarItem(
                placement:
                    .topBarLeading
            ) {

                Button {

                    isPlaying = false

                    dismiss()

                } label: {

                    Image(
                        systemName:
                            "xmark"
                    )
                }
            }


            ToolbarItem(
                placement:
                    .topBarTrailing
            ) {

                Button(
                    "Reset"
                ) {

                    resetView()
                }
            }
        }
        .task(
            id: isPlaying
        ) {

            guard isPlaying else {
                return
            }


            await runPlayback()
        }
        .fullScreenCover(
            isPresented:
                $showPractice,
            onDismiss: {

                guard
                    let result =
                        pendingPracticeResult
                else {

                    return
                }


                pendingPracticeResult =
                    nil


                // Give the full-screen camera
                // presentation a moment to disappear
                // before presenting the result sheet.

                DispatchQueue.main.asyncAfter(
                    deadline:
                        .now()
                        + 0.2
                ) {

                    practiceResultToShow =
                        result
                }
            }
        ) {

            NavigationStack {

                TryItYourselfView(
                    targetMotion:
                        motion
                ) { attempt in

                    practiceAttempt =
                        attempt


                    pendingPracticeResult =
                        MotionMatcher.compare(
                            target:
                                motion,
                            user:
                                attempt
                        )
                }
            }
        }
        .sheet(
            item:
                $practiceResultToShow
        ) { result in

            if let attempt =
                practiceAttempt {

                NavigationStack {

                    PracticeResultView(
                        targetMotion:
                            motion,
                        userMotion:
                            attempt,
                        result:
                            result
                    )
                }

            } else {

                Text(
                    "Practice attempt unavailable."
                )
            }
        }
    }


    // MARK: - Viewer

    private var viewer: some View {

        ZStack {

            // MARK: RealityKit

            if motion.frames.isEmpty {

                VStack(
                    spacing: 12
                ) {

                    Image(
                        systemName:
                            "hand.raised.slash"
                    )
                    .font(
                        .system(
                            size: 42
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.7
                        )
                    )


                    Text(
                        "No motion frames"
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        .white
                    )
                }

            } else {

                RealityKitHandView(
                    motion:
                        motion,
                    currentFrameIndex:
                        safeFrameIndex,
                    yaw:
                        yaw,
                    pitch:
                        pitch,
                    zoom:
                        zoom,
                    showTrail:
                        showTrail
                )
            }


            // MARK: Overlay

            VStack {

                // MARK: Trail

                HStack {

                    Spacer()


                    Button {

                        showTrail.toggle()

                    } label: {

                        HStack(
                            spacing: 7
                        ) {

                            Image(
                                systemName:
                                    showTrail
                                    ? "eye"
                                    : "eye.slash"
                            )


                            Text(
                                "Trail"
                            )
                        }
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
                            14
                        )
                        .padding(
                            .vertical,
                            9
                        )
                        .background(
                            .black.opacity(
                                0.45
                            )
                        )
                        .clipShape(
                            Capsule()
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
                .padding(
                    .horizontal,
                    16
                )
                .padding(
                    .top,
                    16
                )


                Spacer()


                // MARK: Presets

                HStack(
                    spacing: 6
                ) {

                    presetButton(
                        title:
                            "Front",
                        preset:
                            .front
                    )


                    presetButton(
                        title:
                            "Side",
                        preset:
                            .side
                    )


                    presetButton(
                        title:
                            "Top",
                        preset:
                            .top
                    )
                }
                .padding(6)
                .background(
                    .black.opacity(
                        0.40
                    )
                )
                .clipShape(
                    Capsule()
                )
                .padding(
                    .bottom,
                    10
                )


                // MARK: Hint

                HStack(
                    spacing: 7
                ) {

                    Image(
                        systemName:
                            "hand.draw"
                    )


                    Text(
                        "Drag to rotate"
                    )


                    Text("·")


                    Image(
                        systemName:
                            "arrow.up.left.and.arrow.down.right"
                    )


                    Text(
                        "Pinch to zoom"
                    )
                }
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.78
                    )
                )
                .padding(
                    .horizontal,
                    16
                )
                .padding(
                    .vertical,
                    10
                )
                .background(
                    .black.opacity(
                        0.35
                    )
                )
                .clipShape(
                    Capsule()
                )
                .padding(
                    .bottom,
                    16
                )
            }
        }
        .frame(
            maxWidth:
                .infinity
        )
        .frame(
            height:
                430
        )
        .contentShape(
            Rectangle()
        )
        .gesture(
            rotationGesture
        )
        .simultaneousGesture(
            zoomGesture
        )
    }


    // MARK: - Controls

    private var controls: some View {

        ScrollView {

            VStack(
                spacing: 18
            ) {

                // MARK: Motion Info

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            "3D Motion"
                        )
                        .font(
                            .headline
                        )


                        Text(
                            "\(motion.frameCount) frames · \(formattedDuration)"
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }


                    Spacer()


                    Text(
                        "\(safeFrameIndex + 1) / \(max(motion.frameCount, 1))"
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }


                // MARK: Timeline

                if motion.frames.count > 1 {

                    Slider(
                        value: Binding(
                            get: {

                                Double(
                                    safeFrameIndex
                                )
                            },
                            set: {

                                isPlaying =
                                    false


                                currentFrameIndex =
                                    Int(
                                        $0.rounded()
                                    )
                            }
                        ),
                        in:
                            0...Double(
                                motion.frames.count
                                - 1
                            ),
                        step:
                            1
                    )
                }


                // MARK: Playback Controls

                HStack(
                    spacing: 16
                ) {

                    Button {

                        stepBackward()

                    } label: {

                        Image(
                            systemName:
                                "backward.frame.fill"
                        )
                        .font(
                            .title3
                        )
                        .frame(
                            width: 44,
                            height: 44
                        )
                    }


                    Button {

                        togglePlayback()

                    } label: {

                        Image(
                            systemName:
                                isPlaying
                                ? "pause.fill"
                                : "play.fill"
                        )
                        .font(
                            .title2
                        )
                        .foregroundStyle(
                            .white
                        )
                        .frame(
                            width: 62,
                            height: 62
                        )
                        .background(
                            Color(
                                red: 0.95,
                                green: 0.37,
                                blue: 0.55
                            )
                        )
                        .clipShape(
                            Circle()
                        )
                    }


                    Button {

                        stepForward()

                    } label: {

                        Image(
                            systemName:
                                "forward.frame.fill"
                        )
                        .font(
                            .title3
                        )
                        .frame(
                            width: 44,
                            height: 44
                        )
                    }


                    Spacer()


                    Picker(
                        "Speed",
                        selection:
                            $playbackSpeed
                    ) {

                        Text("0.5×")
                            .tag(0.5)

                        Text("1×")
                            .tag(1.0)

                        Text("2×")
                            .tag(2.0)
                    }
                    .pickerStyle(
                        .menu
                    )
                }


                Divider()


                // MARK: Previous Attempt

                if let attempt =
                    practiceAttempt {

                    HStack(
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "checkmark.circle.fill"
                        )
                        .font(
                            .title2
                        )
                        .foregroundStyle(
                            .green
                        )


                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text(
                                "Practice attempt completed"
                            )
                            .font(
                                .system(
                                    size: 15,
                                    weight: .semibold
                                )
                            )


                            Text(
                                "\(attempt.frameCount) frames · \(String(format: "%.2fs", attempt.durationSeconds))"
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }


                        Spacer()
                    }
                    .padding(14)
                    .background(
                        Color(
                            red: 0.94,
                            green: 0.98,
                            blue: 0.94
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                }


                // MARK: Try It Yourself

                Button {

                    isPlaying =
                        false


                    practiceAttempt =
                        nil


                    pendingPracticeResult =
                        nil


                    practiceResultToShow =
                        nil


                    showPractice =
                        true

                } label: {

                    HStack(
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "camera.fill"
                        )


                        Text(
                            practiceAttempt == nil
                            ? "Try It Yourself"
                            : "Try Again"
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
                        18
                    )
                    .frame(
                        height: 56
                    )
                    .background(
                        Color(
                            red: 0.95,
                            green: 0.37,
                            blue: 0.55
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 17,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(
                    .plain
                )
                .disabled(
                    motion.frames.isEmpty
                )
            }
            .padding(22)
        }
        .background(
            Color.white
        )
    }


    // MARK: - Preset Button

    private func presetButton(
        title: String,
        preset: ViewPreset
    ) -> some View {

        Button {

            applyPreset(
                preset
            )

        } label: {

            Text(
                title
            )
            .font(
                .system(
                    size: 13,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                viewPreset == preset
                ? Color.black
                : Color.white
            )
            .padding(
                .horizontal,
                16
            )
            .padding(
                .vertical,
                8
            )
            .background(
                viewPreset == preset
                ? Color.white
                : Color.clear
            )
            .clipShape(
                Capsule()
            )
        }
        .buttonStyle(
            .plain
        )
    }


    // MARK: - Apply Preset

    private func applyPreset(
        _ preset: ViewPreset
    ) {

        isPlaying =
            false


        viewPreset =
            preset


        switch preset {

        case .front:

            yaw = 0

            pitch = 0


        case .side:

            yaw =
                .pi / 2

            pitch = 0


        case .top:

            yaw = 0

            pitch =
                -.pi / 2


        case .custom:

            break
        }
    }


    // MARK: - Rotation

    private var rotationGesture:
        some Gesture {

        DragGesture()
            .onChanged { value in

                viewPreset =
                    .custom


                let deltaX =
                    value.translation.width
                    - previousDrag.width


                let deltaY =
                    value.translation.height
                    - previousDrag.height


                yaw +=
                    Float(
                        deltaX
                    )
                    * 0.008


                pitch +=
                    Float(
                        deltaY
                    )
                    * 0.008


                pitch =
                    min(
                        max(
                            pitch,
                            -1.4
                        ),
                        1.4
                    )


                previousDrag =
                    value.translation
            }
            .onEnded { _ in

                previousDrag =
                    .zero
            }
    }


    // MARK: - Zoom

    private var zoomGesture:
        some Gesture {

        MagnificationGesture()
            .onChanged { value in

                let change =
                    value
                    / previousMagnification


                zoom *=
                    Float(
                        change
                    )


                zoom =
                    min(
                        max(
                            zoom,
                            0.55
                        ),
                        2.5
                    )


                previousMagnification =
                    value
            }
            .onEnded { _ in

                previousMagnification =
                    1.0
            }
    }


    // MARK: - Playback

    private func togglePlayback() {

        guard
            !motion.frames.isEmpty
        else {

            return
        }


        if isPlaying {

            isPlaying =
                false

            return
        }


        if currentFrameIndex >=
            motion.frames.count - 1 {

            currentFrameIndex =
                0
        }


        isPlaying =
            true
    }


    @MainActor
    private func runPlayback() async {

        guard
            motion.frames.count > 1
        else {

            isPlaying =
                false

            return
        }


        while
            isPlaying &&
            currentFrameIndex
            < motion.frames.count - 1 {

            let current =
                motion.frames[
                    currentFrameIndex
                ]


            let next =
                motion.frames[
                    currentFrameIndex + 1
                ]


            let capturedDelay =
                max(
                    next.timestampMilliseconds
                    - current.timestampMilliseconds,
                    10
                )


            let adjustedDelay =
                Double(
                    capturedDelay
                )
                / playbackSpeed


            let nanoseconds =
                UInt64(
                    adjustedDelay
                    * 1_000_000
                )


            try? await Task.sleep(
                nanoseconds:
                    nanoseconds
            )


            guard
                !Task.isCancelled,
                isPlaying
            else {

                return
            }


            currentFrameIndex +=
                1
        }


        if currentFrameIndex >=
            motion.frames.count - 1 {

            isPlaying =
                false
        }
    }


    // MARK: - Frame Controls

    private func stepBackward() {

        isPlaying =
            false


        currentFrameIndex =
            max(
                currentFrameIndex - 1,
                0
            )
    }


    private func stepForward() {

        isPlaying =
            false


        currentFrameIndex =
            min(
                currentFrameIndex + 1,
                max(
                    motion.frames.count - 1,
                    0
                )
            )
    }


    // MARK: - Reset

    private func resetView() {

        yaw = 0

        pitch = 0

        zoom = 1

        viewPreset =
            .front
    }


    // MARK: - Helpers

    private var safeFrameIndex: Int {

        guard
            !motion.frames.isEmpty
        else {

            return 0
        }


        return min(
            max(
                currentFrameIndex,
                0
            ),
            motion.frames.count - 1
        )
    }


    private var formattedDuration:
        String {

        String(
            format:
                "%.2fs",
            motion.durationSeconds
        )
    }
}
