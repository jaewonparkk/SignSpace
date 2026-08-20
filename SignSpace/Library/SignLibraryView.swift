import SwiftUI
import SwiftData

struct SignLibraryView: View {

    // MARK: - SwiftData

    @Environment(\.modelContext)
    private var modelContext


    @Query(
        sort: \SavedSign.createdAt,
        order: .reverse
    )
    private var signs: [SavedSign]


    // MARK: - Body

    var body: some View {

        ZStack {

            background


            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 26
                ) {

                    header


                    if signs.isEmpty {

                        emptyState

                    } else {

                        libraryContent
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
    }


    // MARK: - Background

    private var background: some View {

        LinearGradient(
            colors: [

                Color(
                    red: 1.0,
                    green: 0.97,
                    blue: 0.95
                ),

                Color(
                    red: 1.0,
                    green: 0.94,
                    blue: 0.95
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }


    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        "SignSpace"
                    )
                    .font(
                        .system(
                            size: 36,
                            weight: .bold,
                            design: .rounded
                        )
                    )


                    Text(
                        "Learn signs in space."
                    )
                    .font(
                        .system(
                            size: 17
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }


                Spacer()


                ZStack {

                    Circle()
                        .fill(
                            Color.white.opacity(
                                0.78
                            )
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
                    .foregroundStyle(
                        accent
                    )
                }
            }
        }
        .padding(
            .horizontal,
            22
        )
    }


    // MARK: - Library

    private var libraryContent: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                Text(
                    "Learn"
                )
                .font(
                    .system(
                        size: 25,
                        weight: .bold,
                        design: .rounded
                    )
                )


                Spacer()


                Text(
                    "\(signs.count) lesson\(signs.count == 1 ? "" : "s")"
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


            LazyVStack(
                spacing: 14
            ) {

                ForEach(signs) { sign in

                    NavigationLink {

                        SignLessonView(
                            sign: sign
                        )

                    } label: {

                        signCard(
                            sign
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                    .contextMenu {

                        Button(
                            role: .destructive
                        ) {

                            delete(
                                sign
                            )

                        } label: {

                            Label(
                                "Delete Lesson",
                                systemImage:
                                    "trash"
                            )
                        }
                    }
                }
            }
            .padding(
                .horizontal,
                20
            )
        }
    }


    // MARK: - Sign Card

    private func signCard(
        _ sign: SavedSign
    ) -> some View {

        HStack(
            spacing: 16
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    Color(
                        red: 1.0,
                        green: 0.87,
                        blue: 0.91
                    )
                )
                .frame(
                    width: 72,
                    height: 72
                )


                Image(
                    systemName:
                        "hand.raised.fill"
                )
                .font(
                    .system(
                        size: 30
                    )
                )
                .foregroundStyle(
                    accent
                )
            }


            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text(
                    sign.name
                )
                .font(
                    .system(
                        size: 18,
                        weight: .semibold,
                        design: .rounded
                    )
                )


                HStack(
                    spacing: 7
                ) {

                    metadataPill(
                        sign.difficulty
                    )


                    Text("·")
                        .foregroundStyle(
                            .tertiary
                        )


                    Text(
                        sign.handDescription
                    )


                    Text("·")
                        .foregroundStyle(
                            .tertiary
                        )


                    Text(
                        sign.durationText
                    )
                }
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }


            Spacer()


            Image(
                systemName:
                    "chevron.right"
            )
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                .tertiary
            )
        }
        .padding(16)
        .background(
            Color.white.opacity(
                0.82
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }


    private func metadataPill(
        _ text: String
    ) -> some View {

        Text(text)
            .font(
                .system(
                    size: 11,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                accent
            )
            .padding(
                .horizontal,
                8
            )
            .padding(
                .vertical,
                4
            )
            .background(
                Color(
                    red: 1.0,
                    green: 0.90,
                    blue: 0.93
                )
            )
            .clipShape(
                Capsule()
            )
    }


    // MARK: - Empty

    private var emptyState: some View {

        VStack(
            spacing: 18
        ) {

            ZStack {

                Circle()
                    .fill(
                        Color.white.opacity(
                            0.8
                        )
                    )
                    .frame(
                        width: 112,
                        height: 112
                    )


                Image(
                    systemName:
                        "hand.raised.fill"
                )
                .font(
                    .system(
                        size: 45
                    )
                )
                .foregroundStyle(
                    accent
                )
            }


            VStack(
                spacing: 7
            ) {

                Text(
                    "No lessons yet"
                )
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .rounded
                    )
                )


                Text(
                    "Create your first target sign from the Create tab."
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
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .top,
            90
        )
        .padding(
            .horizontal,
            40
        )
    }


    // MARK: - Delete

    private func delete(
        _ sign: SavedSign
    ) {

        modelContext.delete(
            sign
        )


        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to delete lesson:",
                error
            )
        }
    }


    // MARK: - Accent

    private var accent: Color {

        Color(
            red: 0.95,
            green: 0.37,
            blue: 0.55
        )
    }
}
