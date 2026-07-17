import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var isLoading = true
    @Published var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            async let n = TMDBService.shared.nowPlaying()
            async let u = TMDBService.shared.upcoming()
            async let p = TMDBService.shared.popular()
            (nowPlaying, upcoming, popular) = try await (n, u, p)
        } catch {
            self.error = error.localizedDescription
        }
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
                    if model.isLoading {
                        LoadingStateView(message: "Prepariamo la sala…")
                    } else if let error = model.error {
                        errorView(error)
                    } else {
                        if !model.nowPlaying.isEmpty {
                            RotatingHeroCarousel(movies: Array(model.nowPlaying.prefix(6)))
                        }
                        releaseStrip
                        movieSection("Nelle sale", subtitle: "I film disponibili adesso", movies: model.nowPlaying)
                        movieSection("Prossime uscite", subtitle: "Scopri quando arrivano al cinema", movies: model.upcoming)
                        movieSection("Più popolari", subtitle: "I titoli di cui parlano tutti", movies: model.popular)
                    }
                    TMDBCreditView().padding(.bottom, 24)
                }
                .padding(.horizontal, 18)
            }
            .refreshable { await model.load() }
        }
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
        .task { if model.nowPlaying.isEmpty { await model.load() } }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var masthead: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CINEORA")
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .tracking(1)
                Text("La tua guida alle uscite in sala")
                    .font(.subheadline)
                    .foregroundStyle(CineTheme.secondaryText)
            }
            Spacer()
            ZStack {
                Circle().fill(CineTheme.surfaceRaised)
                Image(systemName: "ticket.fill").foregroundStyle(CineTheme.accent).font(.title2)
            }
            .frame(width: 48, height: 48)
        }
        .padding(.top, 10)
    }

    private var releaseStrip: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle(title: "Calendario cinema", subtitle: "Le prossime date da ricordare")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(model.upcoming.prefix(8))) { movie in
                        NavigationLink(value: movie) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(movie.releaseBadge.uppercased())
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(CineTheme.accent)
                                Text(movie.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(movie.formattedReleaseDate)
                                    .font(.caption)
                                    .foregroundStyle(CineTheme.secondaryText)
                            }
                            .padding(15)
                            .frame(width: 194, height: 116, alignment: .leading)
                            .background(CineTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(alignment: .leading) {
                                Rectangle().fill(CineTheme.accent).frame(width: 4).clipShape(Capsule()).padding(.vertical, 14)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func movieSection(_ title: String, subtitle: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: title, subtitle: subtitle)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(movies) { MoviePosterCard(movie: $0) }
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundStyle(CineTheme.accent)
            Text(message).multilineTextAlignment(.center)
            Button("Riprova") { Task { await model.load() } }
                .buttonStyle(.borderedProminent)
                .tint(CineTheme.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }
}

private struct RotatingHeroCarousel: View {
    let movies: [Movie]
    @State private var selectedIndex = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    HeroMovieView(movie: movie)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 370)

            HStack(spacing: 7) {
                ForEach(movies.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? CineTheme.accent : Color.white.opacity(0.22))
                        .frame(width: index == selectedIndex ? 22 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }
        }
        .onReceive(timer) { _ in
            guard movies.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                selectedIndex = (selectedIndex + 1) % movies.count
            }
        }
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
                    Text("ORA AL CINEMA")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.6)
                        .foregroundStyle(CineTheme.accent)
                    Text(movie.title)
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .lineLimit(2)
                    Text("\(movie.releaseBadge) • \(movie.formattedReleaseDate)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    HStack(spacing: 12) {
                        Label("Apri scheda", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(CineTheme.accent)
                            .clipShape(Capsule())
                        Label(movie.formattedRating, systemImage: "star.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(20)
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(CineTheme.divider))
        }
        .buttonStyle(.plain)
    }
}
