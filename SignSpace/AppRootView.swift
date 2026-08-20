import SwiftUI

enum SignSpaceTheme {
    static let primary = Color(red: 0.08, green: 0.38, blue: 0.88)
    static let background = Color(red: 0.96, green: 0.98, blue: 1.0)
    static let backgroundDeep = Color(red: 0.90, green: 0.95, blue: 1.0)
    static let softBlue = Color(red: 0.86, green: 0.92, blue: 1.0)
}

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
        .tint(SignSpaceTheme.primary)
    }
}


#Preview {
    AppRootView()
}
