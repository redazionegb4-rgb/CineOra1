import Foundation

struct MoviePage: Decodable { let results: [Movie] }

struct Movie: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let genreIDs: [Int]?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case genreIDs = "genre_ids"
    }

    var posterURL: URL? { posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") } }
    var backdropURL: URL? { backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") } }
    var year: String { String((releaseDate ?? "").prefix(4)) }
    var formattedRating: String { String(format: "%.1f", voteAverage) }
    var formattedReleaseDate: String { ReleaseDateFormatter.format(releaseDate) }
    var releaseBadge: String { ReleaseDateFormatter.badge(releaseDate) }
}

struct GenreResponse: Decodable { let genres: [Genre] }
struct Genre: Codable, Identifiable, Hashable { let id: Int; let name: String }

struct MovieDetails: Decodable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let runtime: Int?
    let genres: [Genre]
    let videos: VideoResponse?
    let credits: CreditsResponse?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, videos, credits
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }

    var backdropURL: URL? { backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w1280\($0)") } }
    var posterURL: URL? { posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") } }
    var formattedReleaseDate: String { ReleaseDateFormatter.format(releaseDate) }
    var releaseBadge: String { ReleaseDateFormatter.badge(releaseDate) }
    var trailerURL: URL? {
        guard let key = videos?.results.first(where: { $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") })?.key else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}

struct VideoResponse: Decodable { let results: [Video] }
struct Video: Decodable { let key: String; let site: String; let type: String }
struct CreditsResponse: Decodable { let cast: [CastMember] }
struct CastMember: Decodable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    enum CodingKeys: String, CodingKey { case id, name, character; case profilePath = "profile_path" }
    var imageURL: URL? { profilePath.flatMap { URL(string: "https://image.tmdb.org/t/p/w185\($0)") } }
}

enum ReleaseDateFormatter {
    private static let input: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let output: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    static func date(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return input.date(from: value)
    }

    static func format(_ value: String?) -> String {
        guard let date = date(value) else { return "Data non disponibile" }
        return output.string(from: date)
    }

    static func badge(_ value: String?) -> String {
        guard let date = date(value) else { return "Data da definire" }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let release = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: today, to: release).day ?? 0
        if days == 0 { return "Esce oggi" }
        if days == 1 { return "Esce domani" }
        if days > 1 && days <= 7 { return "Esce tra \(days) giorni" }
        if days > 7 { return "In uscita" }
        return "Al cinema"
    }
}
