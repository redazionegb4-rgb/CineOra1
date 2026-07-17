import SwiftUI

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var details: MovieDetails?
    @Published var loading = true
    @Published var errorMessage: String?

    func load(id: Int) async {
        loading = true
        do { details = try await TMDBService.shared.details(id: id) }
        catch { errorMessage = "Non è stato possibile caricare tutti i dettagli." }
        loading = false
    }
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
                VStack(spacing: 0) {
                    hero
                    if model.loading {
                        LoadingStateView(message: "Carico la scheda…")
                    } else if let details = model.details {
                        detailContent(details)
                    } else {
                        Text(model.errorMessage ?? "Dettagli non disponibili")
                            .foregroundStyle(CineTheme.secondaryText)
                            .padding(30)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 120)
            }
        }
        .toolbarBackground(CineTheme.background.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(id: movie.id) }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                RemoteImage(url: model.details?.backdropURL ?? movie.backdropURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 310)
                    .clipped()
                LinearGradient(
                    colors: [.clear, CineTheme.background.opacity(0.72), CineTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(spacing: 16) {
                RemoteImage(url: model.details?.posterURL ?? movie.posterURL)
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15)))
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    .padding(.top, -145)

                Text(model.details?.title ?? movie.title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    Label(String(format: "%.1f", model.details?.voteAverage ?? movie.voteAverage), systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                    Text((model.details?.releaseBadge ?? movie.releaseBadge).uppercased())
                        .foregroundStyle(CineTheme.accent)
                }
                .font(.subheadline.bold())

                Button { favorites.toggle(movie) } label: {
                    Label(
                        favorites.contains(movie) ? "Nella mia lista" : "Aggiungi alla mia lista",
                        systemImage: favorites.contains(movie) ? "heart.fill" : "heart"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CineTheme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func detailContent(_ details: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            releaseCard(details)

            if !details.genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(details.genres) { genre in
                            Text(genre.name)
                                .font(.caption.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(CineTheme.cardStrong)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Trama").font(.title2.bold()).foregroundStyle(.white)
                Text(details.overview.isEmpty ? "Trama non ancora disponibile in italiano." : details.overview)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let url = details.trailerURL {
                Button { openURL(url) } label: {
                    Label("Guarda il trailer", systemImage: "play.rectangle.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(CineTheme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            if let cast = details.credits?.cast.prefix(12), !cast.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Cast principale").font(.title2.bold()).foregroundStyle(.white)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(Array(cast)) { person in
                                VStack(spacing: 7) {
                                    RemoteImage(url: person.imageURL)
                                        .frame(width: 92, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    Text(person.name).font(.caption.bold()).foregroundStyle(.white).lineLimit(2)
                                    Text(person.character ?? "").font(.caption2).foregroundStyle(CineTheme.secondaryText).lineLimit(1)
                                }.frame(width: 94)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private func releaseCard(_ details: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar.badge.clock").font(.title2).foregroundStyle(CineTheme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(details.releaseBadge).font(.headline).foregroundStyle(.white)
                    Text(details.formattedReleaseDate).font(.subheadline).foregroundStyle(CineTheme.secondaryText)
                }
                Spacer()
            }
            if let runtime = details.runtime {
                Divider().overlay(.white.opacity(0.1))
                Label("Durata: \(runtime) minuti", systemImage: "clock.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.88))
            }
        }
        .padding(18)
        .cineCard(cornerRadius: 20)
    }
}
