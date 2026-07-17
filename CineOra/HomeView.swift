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
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 30) {
                    masthead
                    if model.isLoading { LoadingStateView(message: "Prepariamo la sala…") }
                    else if let error = model.error { errorView(error) }
                    else {
                        if let featured = model.nowPlaying.first { HeroMovieView(movie: featured) }
                        releaseStrip
                        movieSection("Nelle sale", subtitle: "I film disponibili adesso", movies: Array(model.nowPlaying.dropFirst()))
                        movieSection("Prossime uscite", subtitle: "Segna la data sul calendario", movies: model.upcoming)
                        movieSection("Più popolari", subtitle: "I titoli di cui parlano tutti", movies: model.popular)
                    }
                    TMDBCreditView().padding(.bottom, 24)
                }.padding(.horizontal, 18)
            }.refreshable { await model.load() }
        }
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
        .task { if model.nowPlaying.isEmpty { await model.load() } }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var masthead: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CINEORA").font(.system(size: 31, weight: .black, design: .rounded)).tracking(1)
                Text("La tua guida alle uscite in sala").font(.subheadline).foregroundStyle(CineTheme.secondaryText)
            }
            Spacer()
            ZStack {
                Circle().fill(CineTheme.surfaceRaised)
                Image(systemName: "ticket.fill").foregroundStyle(CineTheme.accent).font(.title2)
            }.frame(width: 48, height: 48)
        }.padding(.top, 10)
    }

    private var releaseStrip: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle(title: "Calendario cinema", subtitle: "Le prossime date da ricordare")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(model.upcoming.prefix(6))) { movie in
                        NavigationLink(value: movie) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(movie.releaseBadge.uppercased()).font(.caption2.weight(.black)).foregroundStyle(CineTheme.accent)
                                Text(movie.title).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(2)
                                Text(movie.formattedReleaseDate).font(.caption).foregroundStyle(CineTheme.secondaryText)
                            }
                            .padding(15).frame(width: 190, height: 112, alignment: .leading)
                            .background(CineTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(alignment: .leading) { Rectangle().fill(CineTheme.accent).frame(width: 4).clipShape(Capsule()).padding(.vertical, 14) }
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func movieSection(_ title: String, subtitle: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: title, subtitle: subtitle)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) { ForEach(movies) { MoviePosterCard(movie: $0) } }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundStyle(CineTheme.accent)
            Text(message).multilineTextAlignment(.center)
            Button("Riprova") { Task { await model.load() } }.buttonStyle(.borderedProminent).tint(CineTheme.accent)
        }.frame(maxWidth: .infinity, minHeight: 260)
    }
}

struct HeroMovieView: View {
    let movie: Movie
    var body: some View {
        NavigationLink(value: movie) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(url: movie.backdropURL).frame(height: 360).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.12), CineTheme.background.opacity(0.98)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 10) {
                    Text("FILM DEL MOMENTO").font(.caption2.weight(.black)).tracking(1.6).foregroundStyle(CineTheme.accent)
                    Text(movie.title).font(.system(size: 32, weight: .black, design: .rounded)).lineLimit(2)
                    ReleaseInfoPill(movie: movie)
                    HStack(spacing: 12) {
                        Label("Scheda film", systemImage: "info.circle.fill")
                            .font(.subheadline.bold()).foregroundStyle(.black)
                            .padding(.horizontal, 16).padding(.vertical, 11).background(CineTheme.accent).clipShape(Capsule())
                        Label(movie.formattedRating, systemImage: "star.fill").font(.subheadline.bold()).foregroundStyle(.white)
                    }
                }.padding(20)
            }
            .frame(height: 360).clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(CineTheme.divider))
        }.buttonStyle(.plain)
    }
}
