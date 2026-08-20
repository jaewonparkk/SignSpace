import SwiftUI

struct ContentView: View {

    @StateObject private var handTracker =
        HandTrackingService()

    @State private var motionToView:
        SignMotion?


    var body: some View {

        ZStack {

            SignSpaceTheme.background
            .ignoresSafeArea()


            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    // MARK: - Header

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(
                            "SignSpace"
                        )
                        .font(
                            .system(
                                size: 34,
                                weight: .bold,
                                design: .rounded
                            )
                        )


                        Text(
                            "Capture movement, not just video."
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .padding(
                        .horizontal,
                        24
                    )


                    // MARK: - Camera

                    ZStack {

                        CameraPreview(
                            session:
                                handTracker.session,
                            cameraDevice:
                                handTracker.cameraDevice
                        )


                        HandLandmarkOverlay(
                            hands:
                                handTracker.handLandmarks
                        )


                        VStack {

                            HStack(
                                spacing: 8
                            ) {

                                Circle()
                                    .fill(
                                        handTracker.isRecording
                                        ? Color.red
                                        : handTracker.handLandmarks.isEmpty
                                        ? Color.orange
                                        : Color.green
                                    )
                                    .frame(
                                        width: 8,
                                        height: 8
                                    )


                                Text(
                                    handTracker.statusText
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


                                Spacer()
                            }
                            .padding(
                                .horizontal,
                                14
                            )
                            .padding(
                                .vertical,
                                10
                            )
                            .background(
                                .black.opacity(
                                    0.45
                                )
                            )


                            Spacer()
                        }
                    }
                    .aspectRatio(
                        3.0 / 4.0,
                        contentMode: .fit
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


                    // MARK: - Record Button

                    Button {

                        if handTracker.isRecording {

                            handTracker.stopRecording(
                                name:
                                    "Test Sign"
                            )

                        } else {

                            handTracker.startRecording()
                        }

                    } label: {

                        HStack(
                            spacing: 12
                        ) {

                            ZStack {

                                Circle()
                                    .stroke(
                                        handTracker.isRecording
                                        ? Color.white
                                        : Color.red,
                                        lineWidth: 3
                                    )
                                    .frame(
                                        width: 28,
                                        height: 28
                                    )


                                if handTracker.isRecording {

                                    RoundedRectangle(
                                        cornerRadius: 4
                                    )
                                    .fill(
                                        .white
                                    )
                                    .frame(
                                        width: 12,
                                        height: 12
                                    )

                                } else {

                                    Circle()
                                        .fill(
                                            .red
                                        )
                                        .frame(
                                            width: 18,
                                            height: 18
                                        )
                                }
                            }


                            Text(
                                handTracker.isRecording
                                ? "Stop Recording"
                                : "Record Sign"
                            )
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )


                            Spacer()


                            if handTracker.isRecording {

                                Text(
                                    "\(handTracker.recordedFrameCount) frames"
                                )
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(
                                    .white.opacity(
                                        0.8
                                    )
                                )
                            }
                        }
                        .foregroundStyle(
                            handTracker.isRecording
                            ? Color.white
                            : Color.primary
                        )
                        .padding(
                            .horizontal,
                            20
                        )
                        .frame(
                            height: 64
                        )
                        .background(
                            handTracker.isRecording
                            ? Color.red
                            : Color.white.opacity(
                                0.8
                            )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 20,
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


                    // MARK: - Latest Recording

                    if let recording =
                        handTracker.latestRecording {

                        VStack(
                            alignment: .leading,
                            spacing: 16
                        ) {

                            HStack {

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(
                                        "Motion captured"
                                    )
                                    .font(
                                        .headline
                                    )


                                    Text(
                                        recording.name
                                    )
                                    .font(
                                        .subheadline
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }


                                Spacer()


                                Image(
                                    systemName:
                                        "checkmark.circle.fill"
                                )
                                .font(
                                    .system(
                                        size: 26
                                    )
                                )
                                .foregroundStyle(
                                    .green
                                )
                            }


                            Divider()


                            HStack {

                                recordingStat(
                                    title:
                                        "Frames",
                                    value:
                                        "\(recording.frameCount)"
                                )


                                Spacer()


                                recordingStat(
                                    title:
                                        "Duration",
                                    value:
                                        String(
                                            format:
                                                "%.2fs",
                                            recording.durationSeconds
                                        )
                                )


                                Spacer()


                                recordingStat(
                                    title:
                                        "3D",
                                    value:
                                        "✓"
                                )
                            }


                            Button {

                                // Stop the capture session behind
                                // the 3D viewer.

                                handTracker.stop()

                                motionToView =
                                    recording

                            } label: {

                                HStack {

                                    Image(
                                        systemName:
                                            "cube.transparent"
                                    )


                                    Text(
                                        "View 3D Motion"
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
                                    height: 54
                                )
                                .background(
                                    SignSpaceTheme.primary
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 16,
                                        style: .continuous
                                    )
                                )
                            }
                            .buttonStyle(
                                .plain
                            )
                        }
                        .padding(
                            20
                        )
                        .background(
                            Color.white.opacity(
                                0.78
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


                    // MARK: - Error

                    if let error =
                        handTracker.errorMessage {

                        Text(
                            error
                        )
                        .font(
                            .footnote
                        )
                        .foregroundStyle(
                            .red
                        )
                        .padding(
                            .horizontal,
                            24
                        )
                    }


                    Spacer(
                        minLength: 30
                    )
                }
                .padding(
                    .top,
                    20
                )
            }
        }
        .onAppear {

            handTracker.start()
        }
        .onDisappear {

            handTracker.stop()
        }
        .sheet(
            item:
                $motionToView,
            onDismiss: {

                // Restore camera when returning
                // to the capture screen.

                handTracker.start()
            }
        ) { motion in

            NavigationStack {

                SignViewerView(
                    motion:
                        motion
                )
            }
        }
    }


    // MARK: - Recording Stat

    private func recordingStat(
        title: String,
        value: String
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
                value
            )
            .font(
                .system(
                    size: 17,
                    weight: .semibold,
                    design: .rounded
                )
            )
        }
    }
}


#Preview {
    ContentView()
}
