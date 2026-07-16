import SwiftUI

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var details: MovieDetails?
    @Published var loading = true
    func load(id: Int) async { do { details = try await TMDBService.shared.details(id: id) } catch {}; loading = false }
}

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var model = MovieDetailViewModel()
    @EnvironmentObject private var favorites: FavoritesStore
    @Environment(\.openURL) private var openURL
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    if model.loading { LoadingStateView(message: "Carico la scheda…") }
                    else if let d = model.details { details(d) }
                }.padding(.bottom, 30)
            }
        }.navigationBarTitleDisplayMode(.inline).task { await model.load(id: movie.id) }
    }
    private var hero: some View {
        ZStack(alignment: .bottom) {
            RemoteImage(url: model.details?.backdropURL ?? movie.backdropURL).frame(height: 350).clipped()
            LinearGradient(colors: [.clear, CineTheme.background], startPoint: .center, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: 15) {
                RemoteImage(url: model.details?.posterURL ?? movie.posterURL).frame(width: 115, height: 172).clipShape(RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title).font(.title.bold()).lineLimit(3)
                    Label(movie.formattedRating, systemImage: "star.fill").foregroundStyle(.yellow).font(.subheadline.bold())
                    Button { favorites.toggle(movie) } label: { Label(favorites.contains(movie) ? "Nella mia lista" : "Aggiungi alla lista", systemImage: favorites.contains(movie) ? "heart.fill" : "heart").font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 9).background(CineTheme.gradient).clipShape(Capsule()) }
                }
            }.padding(.horizontal, 18)
        }
    }
    @ViewBuilder private func details(_ d: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 10) {
                if let runtime = d.runtime { infoChip("\(runtime) min", "clock.fill") }
                if let date = d.releaseDate, !date.isEmpty { infoChip(date, "calendar") }
            }
            if !d.genres.isEmpty { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(d.genres) { Text($0.name).font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 8).background(CineTheme.card).clipShape(Capsule()) } } } }
            VStack(alignment: .leading, spacing: 10) { Text("Trama").font(.title2.bold()); Text(d.overview.isEmpty ? "Trama non ancora disponibile in italiano." : d.overview).foregroundStyle(.white.opacity(0.8)).lineSpacing(5) }
            if let url = d.trailerURL { Button { openURL(url) } label: { Label("Guarda il trailer", systemImage: "play.rectangle.fill").frame(maxWidth: .infinity).padding().background(CineTheme.gradient).clipShape(RoundedRectangle(cornerRadius: 17)) } }
            if let cast = d.credits?.cast.prefix(12), !cast.isEmpty {
                VStack(alignment: .leading, spacing: 14) { Text("Cast principale").font(.title2.bold()); ScrollView(.horizontal, showsIndicators: false) { HStack(alignment: .top, spacing: 14) { ForEach(Array(cast)) { person in VStack { RemoteImage(url: person.imageURL).frame(width: 86, height: 110).clipShape(RoundedRectangle(cornerRadius: 15)); Text(person.name).font(.caption.bold()).lineLimit(2); Text(person.character ?? "").font(.caption2).foregroundStyle(CineTheme.secondaryText).lineLimit(1) }.frame(width: 90) } } } }
            }
        }.padding(.horizontal, 18)
    }
    private func infoChip(_ text: String, _ icon: String) -> some View { Label(text, systemImage: icon).font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 9).background(CineTheme.cardStrong).clipShape(Capsule()) }
}
