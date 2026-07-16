import SwiftUI

@main
struct CineOraApp: App {
    @StateObject private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(favorites)
                .preferredColorScheme(.dark)
        }
    }
}
