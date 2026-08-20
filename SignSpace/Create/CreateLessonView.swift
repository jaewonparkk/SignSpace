import SwiftUI
import SwiftData

struct CreateLessonView: View {

    // MARK: - SwiftData

    @Environment(\.modelContext)
    private var modelContext


    // MARK: - Tracking

    @StateObject private var handTracker =
        HandTrackingService()


    // MARK: - Lesson Metadata

    @State private var name =
        ""

    @State private var difficulty =
        "Beginner"

    @State private var lessonDescription =
        ""

    @State private var notice1 =
        ""

    @State private var notice2 =
        ""

    @State private var notice3 =
        ""


    // MARK: - Save UI

    @State private var showSavedAlert =
        false

    @State private var saveError:
        String?


    private let difficulties = [

        "Beginner",
        "Intermediate",
        "Advanced"
    ]


    // MARK: - Body

    var body: some View {

        ZStack {

            background


            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    header

                    metadataSection

                    recordingSection

                    if let recording =
                        handTracker.latestRecording {

                        capturedCard(
                            recording
                        )
                    }

                    saveButton


                    if let saveError {

                        Text(saveError)
                            .font(
                                .footnote
                            )
                            .foregroundStyle(
                                .red
                            )
                            .padding(
                                .horizontal,
                                22
                            )
                    }


                    Spacer(
                        minLength: 40
                    )
                }
                .padding(
                    .top,
                    12
                )
            }
        }
        .navigationBarHidden(
            true
        )
        .onAppear {

            handTracker.start()
        }
        .onDisappear {

            handTracker.stop()
        }
        .alert(
            "Lesson Saved",
            isPresented:
                $showSavedAlert
        ) {

            Button(
                "Done"
            ) {}

        } message: {

            Text(
                "Your sign is now available in the Learn tab."
            )
        }
    }


    // MARK: - Background

    private var background: some View {

        SignSpaceTheme.background
        .ignoresSafeArea()
    }


    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(
                "Create Lesson"
            )
            .font(
                .system(
                    size: 34,
                    weight: .bold,
                    design: .rounded
                )
            )


            Text(
                "Record a target movement learners can explore and practice."
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


    // MARK: - Metadata

    private var metadataSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            fieldTitle(
                "Sign name"
            )


            TextField(
                "e.g. Thank You",
                text:
                    $name
            )
            .textInputAutocapitalization(
                .words
            )
            .fieldStyle()


            fieldTitle(
                "Difficulty"
            )


            Picker(
                "Difficulty",
                selection:
                    $difficulty
            ) {

                ForEach(
                    difficulties,
                    id: \.self
                ) { difficulty in

                    Text(
                        difficulty
                    )
                    .tag(
                        difficulty
                    )
                }
            }
            .pickerStyle(
                .segmented
            )


            fieldTitle(
                "How it moves"
            )


            ZStack(
                alignment: .topLeading
            ) {

                if lessonDescription.isEmpty {

                    Text(
                        "e.g. Start near your chin, then move your hand forward."
                    )
                    .foregroundStyle(
                        .tertiary
                    )
                    .padding(
                        .horizontal,
                        16
                    )
                    .padding(
                        .vertical,
                        17
                    )
                }


                TextEditor(
                    text:
                        $lessonDescription
                )
                .scrollContentBackground(
                    .hidden
                )
                .frame(
                    minHeight: 110
                )
                .padding(
                    .horizontal,
                    10
                )
                .padding(
                    .vertical,
                    7
                )
            }
            .background(
                Color.white.opacity(
                    0.82
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
            )


            fieldTitle(
                "What to notice"
            )


            noticeField(
                number: 1,
                placeholder:
                    "e.g. Keep your hand flat",
                text:
                    $notice1
            )


            noticeField(
                number: 2,
                placeholder:
                    "e.g. Palm faces inward",
                text:
                    $notice2
            )


            noticeField(
                number: 3,
                placeholder:
                    "e.g. Move smoothly outward",
                text:
                    $notice3
            )
        }
        .padding(20)
        .background(
            Color.white.opacity(
                0.55
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .padding(
            .horizontal,
            20
        )
    }


    // MARK: - Recording

    private var recordingSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Target Motion"
            )
            .font(
                .system(
                    size: 21,
                    weight: .bold,
                    design: .rounded
                )
            )
            .padding(
                .horizontal,
                22
            )


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


                        if handTracker.isRecording {

                            Text(
                                "\(handTracker.recordedFrameCount) frames"
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .white
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
                    cornerRadius: 26,
                    style: .continuous
                )
            )
            .padding(
                .horizontal,
                20
            )


            Button {

                if handTracker.isRecording {

                    handTracker.stopRecording(
                        name:
                            cleanName.isEmpty
                            ? "Untitled Sign"
                            : cleanName
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
                                width: 29,
                                height: 29
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
                        : handTracker.latestRecording == nil
                        ? "Record Target Sign"
                        : "Record Again"
                    )
                    .fontWeight(
                        .semibold
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
                    height: 60
                )
                .background(
                    handTracker.isRecording
                    ? Color.red
                    : Color.white
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
    }


    // MARK: - Captured Card

    private func capturedCard(
        _ recording: SignMotion
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            Image(
                systemName:
                    "checkmark.circle.fill"
            )
            .font(
                .system(
                    size: 28
                )
            )
            .foregroundStyle(
                .green
            )


            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    "Target captured"
                )
                .font(
                    .headline
                )


                Text(
                    "\(recording.frameCount) frames · \(String(format: "%.2fs", recording.durationSeconds))"
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )
            }


            Spacer()


            Button {

                handTracker.clearRecording()

            } label: {

                Image(
                    systemName:
                        "trash"
                )
                .foregroundStyle(
                    .secondary
                )
                .frame(
                    width: 40,
                    height: 40
                )
            }
        }
        .padding(17)
        .background(
            Color.white.opacity(
                0.78
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


    // MARK: - Save

    private var saveButton: some View {

        Button {

            saveLesson()

        } label: {

            HStack {

                Image(
                    systemName:
                        "square.and.arrow.down.fill"
                )


                Text(
                    "Save Lesson"
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
                height: 58
            )
            .background(
                canSave
                ? accent
                : Color.gray.opacity(
                    0.45
                )
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
        .disabled(
            !canSave
        )
        .padding(
            .horizontal,
            20
        )
    }


    private func saveLesson() {

        guard
            canSave,
            let recording =
                handTracker.latestRecording
        else {
            return
        }


        let finalMotion =
            SignMotion(
                id:
                    recording.id,
                name:
                    cleanName,
                createdAt:
                    recording.createdAt,
                frames:
                    recording.frames
            )


        let savedSign =
            SavedSign(
                name:
                    cleanName,
                difficulty:
                    difficulty,
                lessonDescription:
                    lessonDescription
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                notice1:
                    notice1
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                notice2:
                    notice2
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                notice3:
                    notice3
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                motion:
                    finalMotion
            )


        modelContext.insert(
            savedSign
        )


        do {

            try modelContext.save()

            showSavedAlert =
                true

            resetForm()

        } catch {

            saveError =
                "Could not save lesson: \(error.localizedDescription)"
        }
    }


    // MARK: - Reset

    private func resetForm() {

        name =
            ""

        difficulty =
            "Beginner"

        lessonDescription =
            ""

        notice1 =
            ""

        notice2 =
            ""

        notice3 =
            ""

        saveError =
            nil

        handTracker.clearRecording()
    }


    // MARK: - Helpers

    private func fieldTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
    }


    private func noticeField(
        number: Int,
        placeholder: String,
        text: Binding<String>
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            Text(
                "\(number)"
            )
            .font(
                .system(
                    size: 13,
                    weight: .bold,
                    design: .rounded
                )
            )
            .frame(
                width: 28,
                height: 28
            )
            .background(
                SignSpaceTheme.softBlue
            )
            .clipShape(
                Circle()
            )


            TextField(
                placeholder,
                text:
                    text
            )
            .textInputAutocapitalization(
                .sentences
            )
        }
        .padding(
            .horizontal,
            14
        )
        .frame(
            height: 54
        )
        .background(
            Color.white.opacity(
                0.82
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }


    private var cleanName: String {

        name.trimmingCharacters(
            in:
                .whitespacesAndNewlines
        )
    }


    private var canSave: Bool {

        !cleanName.isEmpty
        &&
        handTracker.latestRecording != nil
        &&
        !handTracker.isRecording
    }


    private var accent: Color {

        SignSpaceTheme.primary
    }
}


// MARK: - TextField Style

private extension View {

    func fieldStyle() -> some View {

        self
            .padding(
                .horizontal,
                16
            )
            .frame(
                height: 54
            )
            .background(
                Color.white.opacity(
                    0.82
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
    }
}
