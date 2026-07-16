import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var isLoading = true
    @Published var error: String?

    func load() async {
        isLoading = true; error = nil
        do {
            async let n = TMDBService.shared.nowPlaying()
            async let u = TMDBService.shared.upcoming()
            async let p = TMDBService.shared.popular()
            (nowPlaying, upcoming, popular) = try await (n, u, p)
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

struct HomeView: View {
    @StateObject private var model = HomeViewModel()
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    header
                    if model.isLoading { LoadingStateView(message: "Accendiamo il proiettore…") }
                    else if let error = model.error { errorView(error) }
                    else {
                        if let featured = model.nowPlaying.first { HeroMovieView(movie: featured) }
                        movieSection("Ora al cinema", subtitle: "I titoli disponibili nelle sale italiane", movies: model.nowPlaying)
                        movieSection("Prossimamente", subtitle: "Le uscite da non perdere", movies: model.upcoming)
                        movieSection("Popolari", subtitle: "I film più cercati del momento", movies: model.popular)
                    }
                    TMDBCreditView().padding(.bottom, 20)
                }.padding(.horizontal, 18)
            }.refreshable { await model.load() }
        }
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
        .task { if model.nowPlaying.isEmpty { await model.load() } }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) { Text("CINEORA").font(.system(size: 29, weight: .black, design: .rounded)); Text("Il cinema, adesso.").foregroundStyle(CineTheme.secondaryText) }
            Spacer()
            Image(systemName: "sparkles.tv.fill").font(.title2).foregroundStyle(CineTheme.gradient).padding(12).background(CineTheme.card).clipShape(Circle())
        }.padding(.top, 8)
    }

    private func movieSection(_ title: String, subtitle: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: title, subtitle: subtitle)
            ScrollView(.horizontal, showsIndicators: false) { LazyHStack(alignment: .top, spacing: 14) { ForEach(movies) { MoviePosterCard(movie: $0) } } }
        }
    }
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) { Image(systemName: "wifi.exclamationmark").font(.largeTitle); Text(message).multilineTextAlignment(.center); Button("Riprova") { Task { await model.load() } }.buttonStyle(.borderedProminent).tint(CineTheme.accent) }.frame(maxWidth: .infinity, minHeight: 260)
    }
}

struct HeroMovieView: View {
    let movie: Movie
    var body: some View {
        NavigationLink(value: movie) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(url: movie.backdropURL).frame(height: 300).clipped()
                LinearGradient(colors: [.clear, CineTheme.background.opacity(0.95)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 10) {
                    Text("IN PRIMO PIANO").font(.caption.bold()).tracking(1.4).foregroundStyle(CineTheme.accent)
                    Text(movie.title).font(.system(size: 30, weight: .black, design: .rounded)).lineLimit(2)
                    HStack { Label(movie.formattedRating, systemImage: "star.fill"); if !movie.year.isEmpty { Text("•"); Text(movie.year) } }
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                    Label("Scopri il film", systemImage: "play.fill").font(.subheadline.bold()).padding(.horizontal, 15).padding(.vertical, 10).background(CineTheme.gradient).clipShape(Capsule())
                }.padding(20)
            }
            .frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }.buttonStyle(.plain)
    }
}
