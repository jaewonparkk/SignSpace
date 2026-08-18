import SwiftUI

struct SignViewerView: View {

    let motion: SignMotion


    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss


    // MARK: - Playback

    @State private var currentFrameIndex =
        0

    @State private var isPlaying =
        false

    @State private var playbackSpeed:
        Double = 1.0


    // MARK: - Viewer

    @State private var yaw:
        Float = 0

    @State private var pitch:
        Float = 0

    @State private var zoom:
        Float = 1.0


    @State private var showTrail =
        true


    // MARK: - Gesture

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
    }


    // MARK: - Viewer

    private var viewer: some View {

        ZStack {

            if motion.frames.isEmpty {

                Text(
                    "No motion frames"
                )

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


            VStack {

                HStack {

                    Spacer()


                    Button {

                        showTrail.toggle()

                    } label: {

                        HStack(
                            spacing: 6
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
                    }
                    .buttonStyle(
                        .plain
                    )
                }
                .padding(
                    16
                )


                Spacer()


                Text(
                    "Drag to rotate · Pinch to zoom"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.75
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
                470
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

        VStack(
            spacing: 20
        ) {

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


            // MARK: Playback

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
        }
        .padding(
            22
        )
        .background(
            Color.white
        )
    }


    // MARK: - Rotation

    private var rotationGesture:
        some Gesture {

        DragGesture()
            .onChanged { value in

                let deltaX =
                    value.translation.width
                    - previousDrag.width


                let deltaY =
                    value.translation.height
                    - previousDrag.height


                yaw +=
                    Float(deltaX)
                    * 0.008


                pitch +=
                    Float(deltaY)
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
                    Float(change)


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
    private func runPlayback()
        async {

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


            try? await Task.sleep(
                nanoseconds:
                    UInt64(
                        adjustedDelay
                        * 1_000_000
                    )
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


    // MARK: - Stepping

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

        yaw =
            0

        pitch =
            0

        zoom =
            1
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
