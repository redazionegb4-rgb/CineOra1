import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var selected: Genre?
    @Published var movies: [Movie] = []
    @Published var loading = true

    func load() async {
        do {
            genres = try await TMDBService.shared.genres()
            selected = selected ?? genres.first
            if let selected { await loadMovies(selected) }
        } catch { }
        loading = false
    }

    func loadMovies(_ genre: Genre) async {
        selected = genre; loading = true
        do { movies = try await TMDBService.shared.movies(genreID: genre.id) } catch { movies = [] }
        loading = false
    }
}

struct CategoriesView: View {
    @StateObject private var model = CategoriesViewModel()
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("GENERI").font(.caption.weight(.black)).tracking(2).foregroundStyle(CineTheme.accent)
                            Text("Scegli il tuo film").font(.system(size: 30, weight: .black, design: .rounded))
                            Text("Esplora le sale per atmosfera, non per elenco.").foregroundStyle(CineTheme.secondaryText)
                        }
                        genreMenu
                        if model.loading { LoadingStateView(message: "Selezioniamo i titoli…") }
                        else {
                            Text(model.selected?.name.uppercased() ?? "FILM")
                                .font(.caption.weight(.black)).tracking(1.7).foregroundStyle(CineTheme.accent)
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(model.movies) { movie in
                                    MoviePosterCard(movie: movie, width: max(130, (proxy.size.width - 50) / 2))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 36)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
        .task { if model.genres.isEmpty { await model.load() } }
    }

    private var genreMenu: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(model.genres) { genre in
                    Button {
                        Task { await model.loadMovies(genre) }
                    } label: {
                        HStack(spacing: 8) {
                            Circle().fill(model.selected == genre ? Color.black : CineTheme.accent).frame(width: 7, height: 7)
                            Text(genre.name).font(.subheadline.bold())
                        }
                        .foregroundStyle(model.selected == genre ? .black : .white)
                        .padding(.horizontal, 15).padding(.vertical, 11)
                        .background(model.selected == genre ? CineTheme.accent : CineTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
