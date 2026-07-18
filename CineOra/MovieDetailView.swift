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
    @EnvironmentObject private var reminders: ReminderStore
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CineTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        hero(width: proxy.size.width, topInset: proxy.safeAreaInsets.top)

                        VStack(alignment: .leading, spacing: 24) {
                            releaseCard

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
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 48)
                    }
                    .frame(width: proxy.size.width)
                }
                .ignoresSafeArea(edges: .top)
            }
            // La freccia è un overlay esterno allo ScrollView: non può scorrere con la pagina.
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.62), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))
                        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .padding(.leading, 16)
                .padding(.top, 8)
                .zIndex(999)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await model.load(id: movie.id) }
    }

    private func hero(width: CGFloat, topInset: CGFloat) -> some View {
        let heroHeight: CGFloat = 560 + topInset

        return ZStack(alignment: .bottom) {
            RemoteImage(url: model.details?.backdropURL ?? movie.backdropURL)
                .frame(width: width, height: heroHeight)
                .clipped()
                .overlay(Color.black.opacity(0.13))

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.05), location: 0.0),
                    .init(color: .black.opacity(0.12), location: 0.42),
                    .init(color: CineTheme.background.opacity(0.86), location: 0.78),
                    .init(color: CineTheme.background, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom, spacing: 18) {
                RemoteImage(url: model.details?.posterURL ?? movie.posterURL)
                    .frame(width: 126, height: 190)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.20)))
                    .shadow(color: .black.opacity(0.65), radius: 18, y: 10)

                VStack(alignment: .leading, spacing: 12) {
                    Text(model.details?.title ?? movie.title)
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.70)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 9) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(CineTheme.accent)
                        Text(String(format: "%.1f", model.details?.voteAverage ?? movie.voteAverage))
                            .font(.headline.weight(.bold))
                        Text("•")
                            .foregroundStyle(.white.opacity(0.45))
                        Text(model.details?.releaseBadge.uppercased() ?? movie.releaseBadge.uppercased())
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(CineTheme.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(.white)

                    Label(model.details?.formattedReleaseDate ?? movie.formattedReleaseDate, systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
        .frame(width: width, height: heroHeight)
        .clipped()
    }

    private var releaseCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).fill(CineTheme.accent.opacity(0.15))
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundStyle(CineTheme.accent)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.details?.releaseBadge ?? movie.releaseBadge)
                        .font(.headline.weight(.heavy))
                    Text(model.details?.formattedReleaseDate ?? movie.formattedReleaseDate)
                        .font(.subheadline)
                        .foregroundStyle(CineTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                Button { favorites.toggle(movie) } label: {
                    Label(
                        favorites.contains(movie) ? "In lista" : "La mia lista",
                        systemImage: favorites.contains(movie) ? "checkmark.circle.fill" : "plus.circle.fill"
                    )
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.black)
                    .background(CineTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if ReleaseDateFormatter.isFuture(movie.releaseDate) {
                    Button { Task { await reminders.toggle(movie) } } label: {
                        Label(
                            reminders.contains(movie) ? "Promemoria attivo" : "Avvisami",
                            systemImage: reminders.contains(movie) ? "bell.fill" : "bell.badge"
                        )
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(CineTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .cineCard(cornerRadius: 22)
    }

    @ViewBuilder
    private func detailsContent(_ details: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionLabel("TRAMA")
            Text(details.overview.isEmpty ? "Trama non disponibile in italiano." : details.overview)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
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
                    .background(CineTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }

        if !details.genres.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("GENERI")
                FlexibleGenres(genres: details.genres)
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
                                    .frame(width: 88, height: 114)
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
                            .frame(width: 96)
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
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
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
