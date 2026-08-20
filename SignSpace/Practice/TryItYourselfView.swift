//
//  TryItYourselfView.swift
//  SignSpace
//
//  Created by Jaewon Park on 8/18/26.
//

import SwiftUI

struct TryItYourselfView: View {

    let targetMotion: SignMotion

    let onComplete: (SignMotion) -> Void


    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss


    // MARK: - Hand Tracking

    @StateObject private var handTracker =
        HandTrackingService()


    // MARK: - Body

    var body: some View {

        ZStack {

            SignSpaceTheme.background
            .ignoresSafeArea()


            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    header

                    targetCard

                    cameraView

                    recordingControls

                    if let attempt =
                        handTracker.latestRecording {

                        capturedAttemptCard(
                            attempt
                        )

                    } else {

                        instructions
                    }


                    if let error =
                        handTracker.errorMessage {

                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 22)
                    }


                    Spacer(
                        minLength: 30
                    )
                }
                .padding(.top, 16)
            }
        }
        .toolbar {

            ToolbarItem(
                placement: .topBarLeading
            ) {

                Button {

                    dismiss()

                } label: {

                    Image(
                        systemName: "xmark"
                    )
                }
            }
        }
        .onAppear {

            handTracker.start()
        }
        .onDisappear {

            handTracker.stop()
        }
    }


    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(
                "Try It Yourself"
            )
            .font(
                .system(
                    size: 32,
                    weight: .bold,
                    design: .rounded
                )
            )


            Text(
                "Perform the sign the way you just learned it."
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
            22
        )
    }


    // MARK: - Target

    private var targetCard: some View {

        HStack(
            spacing: 14
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(
                    SignSpaceTheme.softBlue
                )
                .frame(
                    width: 52,
                    height: 52
                )


                Image(
                    systemName:
                        "hand.raised.fill"
                )
                .font(
                    .system(
                        size: 23
                    )
                )
            }


            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "Practicing"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


                Text(
                    targetMotion.name
                )
                .font(
                    .headline
                )
            }


            Spacer()


            VStack(
                alignment: .trailing,
                spacing: 3
            ) {

                Text(
                    "Target"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


                Text(
                    String(
                        format:
                            "%.1fs",
                        targetMotion.durationSeconds
                    )
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold,
                        design: .rounded
                    )
                )
            }
        }
        .padding(16)
        .background(
            Color.white.opacity(0.75)
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


    // MARK: - Camera

    private var cameraView: some View {

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


            // MARK: Top Status

            VStack {

                HStack(
                    spacing: 8
                ) {

                    Circle()
                        .fill(
                            statusColor
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


                    if handTracker.isRecording {

                        Text(
                            "\(handTracker.recordedFrameCount) frames"
                        )
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(0.85)
                        )
                    }
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
                    .black.opacity(0.45)
                )


                Spacer()


                if !handTracker.isRecording &&
                    handTracker.latestRecording == nil {

                    Text(
                        "Keep your hand inside the frame"
                    )
                    .font(
                        .caption
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
                        8
                    )
                    .background(
                        .black.opacity(0.35)
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
    }


    // MARK: - Recording Controls

    private var recordingControls: some View {

        VStack(
            spacing: 12
        ) {

            Button {

                if handTracker.isRecording {

                    handTracker.stopRecording(
                        name:
                            "\(targetMotion.name) Practice"
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
                                width: 30,
                                height: 30
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
                                    width: 19,
                                    height: 19
                                )
                        }
                    }


                    Text(
                        handTracker.isRecording
                        ? "Finish Attempt"
                        : handTracker.latestRecording == nil
                        ? "Start Practice"
                        : "Record Again"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )


                    Spacer()
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
                    : Color.white.opacity(0.82)
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


            if handTracker.latestRecording != nil &&
                !handTracker.isRecording {

                Button {

                    handTracker.clearRecording()

                } label: {

                    Text(
                        "Discard Attempt"
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Instructions

    private var instructions: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Before you start"
            )
            .font(
                .headline
            )


            instructionRow(
                number: "1",
                text:
                    "Position your hand clearly inside the camera."
            )


            instructionRow(
                number: "2",
                text:
                    "Perform the full sign from beginning to end."
            )


            instructionRow(
                number: "3",
                text:
                    "Tap Finish Attempt once the motion is complete."
            )
        }
        .padding(18)
        .background(
            Color.white.opacity(0.7)
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


    private func instructionRow(
        number: String,
        text: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Text(number)
                .font(
                    .system(
                        size: 13,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .frame(
                    width: 26,
                    height: 26
                )
                .background(
                    SignSpaceTheme.softBlue
                )
                .clipShape(
                    Circle()
                )


            Text(text)
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )
        }
    }


    // MARK: - Captured Attempt

    private func capturedAttemptCard(
        _ attempt: SignMotion
    ) -> some View {

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
                        "Attempt captured"
                    )
                    .font(
                        .headline
                    )


                    Text(
                        "Ready to compare with the target."
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
                        size: 27
                    )
                )
                .foregroundStyle(
                    .green
                )
            }


            Divider()


            HStack {

                stat(
                    title: "Frames",
                    value:
                        "\(attempt.frameCount)"
                )


                Spacer()


                stat(
                    title: "Duration",
                    value:
                        String(
                            format:
                                "%.2fs",
                            attempt.durationSeconds
                        )
                )


                Spacer()


                stat(
                    title: "Hands",
                    value:
                        maxHands(
                            in: attempt
                        )
                )
            }


            Button {

                handTracker.stop()

                onComplete(
                    attempt
                )

                dismiss()

            } label: {

                HStack {

                    Image(
                        systemName:
                            "arrow.right.circle.fill"
                    )


                    Text(
                        "Use This Attempt"
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
        .padding(20)
        .background(
            Color.white.opacity(0.82)
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


    // MARK: - Helpers

    private var statusColor: Color {

        if handTracker.isRecording {
            return .red
        }

        if handTracker.handLandmarks.isEmpty {
            return .orange
        }

        return .green
    }


    private func stat(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(title)
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


            Text(value)
                .font(
                    .system(
                        size: 16,
                        weight: .semibold,
                        design: .rounded
                    )
                )
        }
    }


    private func maxHands(
        in motion: SignMotion
    ) -> String {

        let maximum =
            motion.frames
                .map {
                    $0.hands.count
                }
                .max()
                ?? 0


        return "\(maximum)"
    }
}
