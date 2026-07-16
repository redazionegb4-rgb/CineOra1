import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var movies: [Movie] = [] { didSet { save() } }
    private let key = "cineora.favorites"

    init() {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([Movie].self, from: data) else { return }
        movies = decoded
    }
    func contains(_ movie: Movie) -> Bool { movies.contains(where: { $0.id == movie.id }) }
    func toggle(_ movie: Movie) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) { movies.remove(at: index) } else { movies.insert(movie, at: 0) }
    }
    private func save() { if let data = try? JSONEncoder().encode(movies) { UserDefaults.standard.set(data, forKey: key) } }
}
