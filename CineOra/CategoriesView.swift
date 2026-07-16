import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var selected: Genre?
    @Published var movies: [Movie] = []
    @Published var loading = true
    func load() async { do { genres = try await TMDBService.shared.genres(); selected = selected ?? genres.first; if let selected { await loadMovies(selected) } } catch {} ; loading = false }
    func loadMovies(_ genre: Genre) async { selected = genre; loading = true; do { movies = try await TMDBService.shared.movies(genreID: genre.id) } catch {}; loading = false }
}

struct CategoriesView: View {
    @StateObject private var model = CategoriesViewModel()
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle(title: "Categorie", subtitle: "Trova il film giusto per il tuo momento")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(model.genres) { genre in Button(genre.name) { Task { await model.loadMovies(genre) } }.font(.subheadline.bold()).padding(.horizontal, 15).padding(.vertical, 10).background(model.selected == genre ? AnyShapeStyle(CineTheme.gradient) : AnyShapeStyle(CineTheme.card)).clipShape(Capsule()) } }
                    }
                    if model.loading { LoadingStateView(message: "Cerco i film…") }
                    else { LazyVGrid(columns: columns, spacing: 20) { ForEach(model.movies) { MoviePosterCard(movie: $0, width: 160) } } }
                }.padding(18)
            }
        }.navigationTitle("Categorie").navigationBarTitleDisplayMode(.inline).navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }.task { if model.genres.isEmpty { await model.load() } }
    }
}
