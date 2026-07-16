import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Cinema", systemImage: "popcorn.fill") }
            NavigationStack { CategoriesView() }
                .tabItem { Label("Categorie", systemImage: "square.grid.2x2.fill") }
            NavigationStack { SearchMoviesView() }
                .tabItem { Label("Cerca", systemImage: "magnifyingglass") }
            NavigationStack { FavoritesView() }
                .tabItem { Label("La mia lista", systemImage: "heart.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Altro", systemImage: "ellipsis.circle.fill") }
        }
        .tint(CineTheme.accent)
    }
}
