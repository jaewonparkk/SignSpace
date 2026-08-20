import SwiftUI
import SwiftData

@main
struct SignSpaceApp: App {

    var body: some Scene {

        WindowGroup {

            AppRootView()
        }
        .modelContainer(
            for:
                SavedSign.self
        )
    }
}
