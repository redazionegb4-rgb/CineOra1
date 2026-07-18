import SwiftUI

@main
struct CineOraApp: App {
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var reminders = ReminderStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(favorites)
                .environmentObject(reminders)
                .preferredColorScheme(.dark)
        }
    }
}
