import SwiftUI

struct ContentView: View {

    @StateObject private var handTracker =
        HandTrackingService()


    var body: some View {

        ZStack {

            Color(
                red: 1.0,
                green: 0.97,
                blue: 0.95
            )
            .ignoresSafeArea()


            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                // MARK: Header

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text("SignSpace")
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
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)


                // MARK: Camera

                ZStack {

                    CameraPreview(
                        session: handTracker.session,
                        cameraDevice: handTracker.cameraDevice
                    )

                    HandLandmarkOverlay(
                        hands: handTracker.handLandmarks
                    )


                    // MARK: Top Status

                    VStack {

                        HStack {

                            Circle()
                                .fill(
                                    handTracker.handLandmarks.isEmpty
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
                            .foregroundStyle(.white)

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            .black.opacity(0.45)
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
                .padding(.horizontal, 20)


                // MARK: Information

                HStack(
                    spacing: 12
                ) {

                    Image(
                        systemName: "hand.raised.fill"
                    )
                    .font(.title2)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(
                            handTracker.handLandmarks.isEmpty
                            ? "No hand detected"
                            : "Tracking live"
                        )
                        .font(
                            .headline
                        )

                        Text(
                            handTracker.handLandmarks.isEmpty
                            ? "Hold one hand inside the camera frame."
                            : "\(handTracker.handLandmarks.count) hand\(handTracker.handLandmarks.count == 1 ? "" : "s") detected."
                        )
                        .font(
                            .subheadline
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer()
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
                .padding(.horizontal, 20)


                // MARK: Error

                if let error =
                    handTracker.errorMessage {

                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }


                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {

            handTracker.start()
        }
        .onDisappear {

            handTracker.stop()
        }
    }
}


#Preview {
    ContentView()
}
