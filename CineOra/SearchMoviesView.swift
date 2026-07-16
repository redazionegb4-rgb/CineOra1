import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var results: [Movie] = []
    @Published var loading = false
    func search(_ query: String) async {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 else { results = []; return }
        loading = true; do { results = try await TMDBService.shared.search(query) } catch { results = [] }; loading = false
    }
}

struct SearchMoviesView: View {
    @StateObject private var model = SearchViewModel()
    @State private var query = ""
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle(title: "Cerca", subtitle: "Titoli, saghe e film da riscoprire")
                    HStack { Image(systemName: "magnifyingglass"); TextField("Cerca un film…", text: $query).textInputAutocapitalization(.never).submitLabel(.search).onSubmit { Task { await model.search(query) } }; if !query.isEmpty { Button { query = ""; model.results = [] } label: { Image(systemName: "xmark.circle.fill") } } }
                        .padding(14).cineCard(cornerRadius: 18)
                    if model.loading { LoadingStateView(message: "Ricerca in corso…") }
                    else if resultsEmpty { ContentUnavailableView("Trova il tuo prossimo film", systemImage: "film.stack", description: Text("Scrivi almeno due lettere per iniziare.")) }
                    else { LazyVGrid(columns: columns, spacing: 20) { ForEach(model.results) { MoviePosterCard(movie: $0, width: 160) } } }
                }.padding(18)
            }
        }.navigationTitle("Cerca").navigationBarTitleDisplayMode(.inline).navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
    }
    private var resultsEmpty: Bool { model.results.isEmpty }
}
