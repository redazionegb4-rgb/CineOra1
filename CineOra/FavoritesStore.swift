import Foundation
import UserNotifications

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

@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var movies: [Movie] = [] { didSet { save() } }
    private let key = "cineora.releaseReminders"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
            movies = decoded
        }
    }

    func contains(_ movie: Movie) -> Bool { movies.contains { $0.id == movie.id } }

    func toggle(_ movie: Movie) async {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies.remove(at: index)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: movie)])
        } else {
            guard ReleaseDateFormatter.isFuture(movie.releaseDate) else { return }
            let granted = await requestPermission()
            movies.insert(movie, at: 0)
            if granted { schedule(movie) }
        }
    }

    func remove(_ movie: Movie) {
        movies.removeAll { $0.id == movie.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: movie)])
    }

    private func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    private func schedule(_ movie: Movie) {
        guard let release = ReleaseDateFormatter.date(movie.releaseDate) else { return }
        let calendar = Calendar.current
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: release) ?? release
        var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        components.hour = 10
        components.minute = 0
        guard let fireDate = calendar.date(from: components), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Domani al cinema"
        content.body = "\(movie.title) arriva nelle sale domani."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: movie), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func identifier(for movie: Movie) -> String { "cineora.release.\(movie.id)" }
    private func save() { if let data = try? JSONEncoder().encode(movies) { UserDefaults.standard.set(data, forKey: key) } }
}
