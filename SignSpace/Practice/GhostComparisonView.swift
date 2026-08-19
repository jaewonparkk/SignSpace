import SwiftUI

struct GhostComparisonView: View {

    let targetMotion: SignMotion

    let userMotion: SignMotion


    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss


    // MARK: - Playback

    @State private var progress:
        Double = 0

    @State private var isPlaying =
        false

    @State private var playbackSpeed:
        Double = 1.0


    // MARK: - 3D View

    @State private var yaw:
        Float = 0

    @State private var pitch:
        Float = 0

    @State private var zoom:
        Float = 1.0


    // MARK: - Preset

    private enum ViewPreset {

        case front
        case side
        case top
        case custom
    }


    @State private var viewPreset:
        ViewPreset = .front


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
            "Compare Motion"
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

                    isPlaying =
                        false

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

            RealityKitComparisonView(
                targetMotion:
                    targetMotion,
                userMotion:
                    userMotion,
                progress:
                    progress,
                yaw:
                    yaw,
                pitch:
                    pitch,
                zoom:
                    zoom
            )


            VStack {

                // MARK: Legend

                HStack {

                    legendItem(
                        title:
                            "Target",
                        color:
                            Color(
                                red: 1.0,
                                green: 0.34,
                                blue: 0.58
                            )
                    )


                    legendItem(
                        title:
                            "You",
                        color:
                            Color.white.opacity(
                                0.7
                            )
                    )


                    Spacer()
                }
                .padding(
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


                Text(
                    "Rotate the view to inspect where your motion differs."
                )
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
            height:
                500
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
                        "Ghost Comparison"
                    )
                    .font(
                        .headline
                    )


                    Text(
                        "Pink target · White your attempt"
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
                    "\(Int((progress * 100).rounded()))%"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .bold,
                        design: .rounded
                    )
                )
            }


            Slider(
                value:
                    $progress,
                in:
                    0...1
            )
            .onChange(
                of:
                    progress
            ) {

                if isPlaying &&
                    progress >= 1 {

                    isPlaying =
                        false
                }
            }


            HStack(
                spacing: 18
            ) {

                Button {

                    progress =
                        max(
                            progress - 0.05,
                            0
                        )

                    isPlaying =
                        false

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

                    progress =
                        min(
                            progress + 0.05,
                            1
                        )

                    isPlaying =
                        false

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
                }
                .pickerStyle(
                    .menu
                )
            }


            Divider()


            HStack {

                comparisonStat(
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


                comparisonStat(
                    title:
                        "You",
                    frames:
                        userMotion.frameCount,
                    duration:
                        userMotion.durationSeconds
                )
            }
        }
        .padding(22)
        .background(
            Color.white
        )
    }


    // MARK: - Legend

    private func legendItem(
        title: String,
        color: Color
    ) -> some View {

        HStack(
            spacing: 7
        ) {

            Circle()
                .fill(
                    color
                )
                .frame(
                    width: 10,
                    height: 10
                )


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
                .white
            )
        }
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
                0.40
            )
        )
        .clipShape(
            Capsule()
        )
    }


    // MARK: - Presets

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


    private func applyPreset(
        _ preset: ViewPreset
    ) {

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


    // MARK: - Gestures

    private var rotationGesture:
        some Gesture {

        DragGesture()
            .onChanged { value in

                viewPreset =
                    .custom


                let dx =
                    value.translation.width
                    - previousDrag.width


                let dy =
                    value.translation.height
                    - previousDrag.height


                yaw +=
                    Float(dx)
                    * 0.008


                pitch +=
                    Float(dy)
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
                    1
            }
    }


    // MARK: - Playback

    private func togglePlayback() {

        if isPlaying {

            isPlaying =
                false

            return
        }


        if progress >= 1 {

            progress =
                0
        }


        isPlaying =
            true
    }


    @MainActor
    private func runPlayback()
        async {

        while
            isPlaying &&
            progress < 1 {

            let duration =
                max(
                    targetMotion.durationSeconds,
                    userMotion.durationSeconds,
                    0.5
                )


            let increment =
                (
                    1.0
                    / duration
                    / 30.0
                )
                * playbackSpeed


            try? await Task.sleep(
                nanoseconds:
                    33_000_000
            )


            guard
                !Task.isCancelled,
                isPlaying
            else {

                return
            }


            progress =
                min(
                    progress
                    + increment,
                    1
                )
        }


        isPlaying =
            false
    }


    // MARK: - Stats

    private func comparisonStat(
        title: String,
        frames: Int,
        duration: Double
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
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


    // MARK: - Reset

    private func resetView() {

        progress =
            0

        yaw =
            0

        pitch =
            0

        zoom =
            1

        viewPreset =
            .front

        isPlaying =
            false
    }
}
