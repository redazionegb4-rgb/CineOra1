import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var results: [Movie] = []
    @Published var loading = false
    func search(_ query: String) async {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 else { results = []; return }
        loading = true
        do { results = try await TMDBService.shared.search(query) } catch { results = [] }
        loading = false
    }
}

struct SearchMoviesView: View {
    @StateObject private var model = SearchViewModel()
    @State private var query = ""
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("RICERCA").font(.caption.weight(.black)).tracking(2).foregroundStyle(CineTheme.accent)
                            Text("Trova un film").font(.system(size: 30, weight: .black, design: .rounded))
                            Text("Cerca un titolo, una saga o qualcosa da riscoprire.").foregroundStyle(CineTheme.secondaryText)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass").foregroundStyle(CineTheme.accent)
                            TextField("Titolo del film", text: $query)
                                .submitLabel(.search)
                                .onSubmit { Task { await model.search(query) } }
                            if !query.isEmpty {
                                Button { query = ""; model.results = [] } label: { Image(systemName: "xmark.circle.fill") }
                                    .foregroundStyle(CineTheme.secondaryText)
                            }
                        }
                        .padding(16).background(CineTheme.surface).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(CineTheme.divider))

                        if model.loading { LoadingStateView(message: "Ricerca in corso…") }
                        else if model.results.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "movieclapper").font(.system(size: 42)).foregroundStyle(CineTheme.accent)
                                Text("Scrivi almeno due lettere").font(.headline)
                                Text("I risultati appariranno qui.").foregroundStyle(CineTheme.secondaryText)
                            }.frame(maxWidth: .infinity, minHeight: 330)
                        } else {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(model.results) { movie in
                                    MoviePosterCard(movie: movie, width: max(130, (proxy.size.width - 50) / 2))
                                }
                            }
                        }
                    }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 36)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
    }
}
