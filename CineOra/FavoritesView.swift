import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: FavoritesStore
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle(title: "La mia lista", subtitle: "I film che vuoi vedere")
                    if store.movies.isEmpty { ContentUnavailableView("La tua lista è vuota", systemImage: "heart", description: Text("Apri un film e tocca il cuore per salvarlo.")) .frame(minHeight: 400) }
                    else { LazyVGrid(columns: columns, spacing: 20) { ForEach(store.movies) { MoviePosterCard(movie: $0, width: 160) } } }
                }.padding(18)
            }
        }.navigationTitle("La mia lista").navigationBarTitleDisplayMode(.inline).navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
    }
}
