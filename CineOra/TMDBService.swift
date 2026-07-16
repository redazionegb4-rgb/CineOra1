import Foundation

enum TMDBError: LocalizedError {
    case invalidURL, badResponse
    var errorDescription: String? { "Non è stato possibile caricare i dati di TMDB." }
}

actor TMDBService {
    static let shared = TMDBService()
    private let apiKey = "d22a67ddfd10dcfcd75debafb31508ce"
    private let baseURL = "https://api.themoviedb.org/3"

    private func request<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else { throw TMDBError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "it-IT"),
            URLQueryItem(name: "region", value: "IT")
        ] + query
        guard let url = components.url else { throw TMDBError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw TMDBError.badResponse }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func nowPlaying() async throws -> [Movie] { try await request(MoviePage.self, path: "/movie/now_playing").results }
    func upcoming() async throws -> [Movie] { try await request(MoviePage.self, path: "/movie/upcoming").results }
    func popular() async throws -> [Movie] { try await request(MoviePage.self, path: "/movie/popular").results }
    func genres() async throws -> [Genre] { try await request(GenreResponse.self, path: "/genre/movie/list").genres }
    func search(_ text: String) async throws -> [Movie] {
        try await request(MoviePage.self, path: "/search/movie", query: [URLQueryItem(name: "query", value: text), URLQueryItem(name: "include_adult", value: "false")]).results
    }
    func movies(genreID: Int) async throws -> [Movie] {
        try await request(MoviePage.self, path: "/discover/movie", query: [
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "false")
        ]).results
    }
    func details(id: Int) async throws -> MovieDetails {
        try await request(MovieDetails.self, path: "/movie/\(id)", query: [URLQueryItem(name: "append_to_response", value: "videos,credits")])
    }
}

private extension TMDBService {
    func request<T: Decodable>(_ type: T.Type, path: String, query: [URLQueryItem] = []) async throws -> T {
        try await request(path, query: query)
    }
}
