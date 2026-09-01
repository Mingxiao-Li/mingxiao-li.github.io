import SwiftUI

@main
struct MingxiaoStudioApp: App {
    @StateObject private var store = SiteStore()

    var body: some Scene {
        WindowGroup("Mingxiao Studio") {
            RootView()
                .environmentObject(store)
        }
        .windowResizability(.contentSize)
    }
}
