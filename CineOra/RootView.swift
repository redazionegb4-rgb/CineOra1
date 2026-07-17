import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Cinema", systemImage: "film.stack.fill") }
            NavigationStack { CategoriesView() }
                .tabItem { Label("Generi", systemImage: "rectangle.3.group.fill") }
            NavigationStack { SearchMoviesView() }
                .tabItem { Label("Cerca", systemImage: "magnifyingglass") }
            NavigationStack { FavoritesView() }
                .tabItem { Label("Lista", systemImage: "bookmark.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Info", systemImage: "info.circle.fill") }
        }
        .tint(CineTheme.accent)
        .toolbarBackground(CineTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
