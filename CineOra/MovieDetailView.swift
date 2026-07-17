import SwiftUI

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var details: MovieDetails?
    @Published var loading = true
    @Published var errorMessage: String?

    func load(id: Int) async {
        loading = true
        errorMessage = nil
        do {
            details = try await TMDBService.shared.details(id: id)
        } catch {
            errorMessage = "Non è stato possibile caricare tutti i dettagli."
        }
        loading = false
    }
}

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var model = MovieDetailViewModel()
    @EnvironmentObject private var favorites: FavoritesStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CineTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        header(width: proxy.size.width)

                        VStack(alignment: .leading, spacing: 22) {
                            releaseSection

                            if model.loading {
                                LoadingStateView(message: "Carico la scheda…")
                                    .frame(maxWidth: .infinity)
                            } else if let details = model.details {
                                detailsContent(details)
                            } else {
                                Text(model.errorMessage ?? "Dettagli non disponibili")
                                    .foregroundStyle(CineTheme.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .frame(width: max(proxy.size.width - 36, 0), alignment: .leading)
                        .padding(.top, 22)
                        .padding(.bottom, 50)
                    }
                    .frame(width: proxy.size.width)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CineTheme.background.opacity(0.98), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await model.load(id: movie.id) }
    }

    private func header(width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            RemoteImage(url: model.details?.backdropURL ?? movie.backdropURL)
                .frame(width: width, height: 330)
                .clipped()

            LinearGradient(
                colors: [.black.opacity(0.05), CineTheme.background.opacity(0.55), CineTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 13) {
                RemoteImage(url: model.details?.posterURL ?? movie.posterURL)
                    .frame(width: 132, height: 198)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.16)))
                    .shadow(color: .black.opacity(0.65), radius: 18, y: 10)

                Text(model.details?.title ?? movie.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(.white)
                    .frame(maxWidth: width - 44)

                HStack(spacing: 16) {
                    Label(String(format: "%.1f", model.details?.voteAverage ?? movie.voteAverage), systemImage: "star.fill")
                        .foregroundStyle(CineTheme.accent)
                    Text(model.details?.releaseBadge ?? movie.releaseBadge)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: width, height: 500)
        .clipped()
    }

    private var releaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(CineTheme.accent.opacity(0.14))
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundStyle(CineTheme.accent)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.details?.releaseBadge ?? movie.releaseBadge)
                        .font(.headline.weight(.heavy))
                    Text(model.details?.formattedReleaseDate ?? movie.formattedReleaseDate)
                        .font(.subheadline)
                        .foregroundStyle(CineTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }

            Button { favorites.toggle(movie) } label: {
                Label(
                    favorites.contains(movie) ? "Nella mia lista" : "Aggiungi alla mia lista",
                    systemImage: favorites.contains(movie) ? "checkmark.circle.fill" : "plus.circle.fill"
                )
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.black)
                .background(CineTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
        }
        .padding(18)
        .cineCard(cornerRadius: 22)
    }

    @ViewBuilder
    private func detailsContent(_ details: MovieDetails) -> some View {
        if !details.genres.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("GENERI")
                FlexibleGenres(genres: details.genres)
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("TRAMA")
            Text(details.overview.isEmpty ? "Trama non disponibile in italiano." : details.overview)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack(spacing: 12) {
            infoBox(icon: "clock.fill", title: "Durata", value: details.runtime.map { "\($0) min" } ?? "Non indicata")
            infoBox(icon: "film.fill", title: "Formato", value: "Cinema")
        }

        if let trailer = details.trailerURL {
            Button { openURL(trailer) } label: {
                Label("Guarda il trailer", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CineTheme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
        }

        if let cast = details.credits?.cast.prefix(12), !cast.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel("CAST PRINCIPALE")
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(Array(cast)) { person in
                            VStack(spacing: 8) {
                                RemoteImage(url: person.imageURL)
                                    .frame(width: 84, height: 108)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                Text(person.name)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                Text(person.character ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(CineTheme.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 92)
                        }
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.heavy))
            .tracking(1.7)
            .foregroundStyle(CineTheme.accent)
    }

    private func infoBox(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(CineTheme.accent)
            Text(title).font(.caption).foregroundStyle(CineTheme.secondaryText)
            Text(value).font(.headline.weight(.bold)).lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .cineCard(cornerRadius: 18)
    }
}

private struct FlexibleGenres: View {
    let genres: [Genre]
    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(genres) { genre in
                Text(genre.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(CineTheme.surfaceRaised)
                    .clipShape(Capsule())
            }
        }
    }
}
