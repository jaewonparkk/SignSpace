import SwiftUI

struct AppRootView: View {

    @State private var selectedTab =
        0


    var body: some View {

        TabView(
            selection:
                $selectedTab
        ) {

            NavigationStack {

                SignLibraryView()
            }
            .tabItem {

                Label(
                    "Learn",
                    systemImage:
                        "books.vertical.fill"
                )
            }
            .tag(0)


            NavigationStack {

                CreateLessonView()
            }
            .tabItem {

                Label(
                    "Create",
                    systemImage:
                        "plus.square.fill"
                )
            }
            .tag(1)
        }
        .tint(
            Color(
                red: 0.95,
                green: 0.37,
                blue: 0.55
            )
        )
    }
}


#Preview {
    AppRootView()
}
