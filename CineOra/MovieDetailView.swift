import SwiftUI

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var details: MovieDetails?
    @Published var loading = true
    @Published var errorMessage: String?
    func load(id: Int) async {
        loading = true; errorMessage = nil
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    cinematicHeader
                    VStack(alignment: .leading, spacing: 24) {
                        releaseCard
                        if model.loading { LoadingStateView(message: "Carico la scheda…") }
                        else if let details = model.details { detailsBody(details) }
                        else { Text(model.errorMessage ?? "Dettagli non disponibili").foregroundStyle(CineTheme.secondaryText) }
                    }
                    .padding(.horizontal, 18).padding(.top, 22).padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CineTheme.background.opacity(0.96), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await model.load(id: movie.id) }
    }

    private var cinematicHeader: some View {
        ZStack(alignment: .bottom) {
            RemoteImage(url: model.details?.backdropURL ?? movie.backdropURL)
                .frame(height: 430).clipped()
            CineTheme.backdropGradient
            VStack(spacing: 14) {
                RemoteImage(url: model.details?.posterURL ?? movie.posterURL)
                    .frame(width: 142, height: 210).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18)))
                    .shadow(color: .black.opacity(0.65), radius: 18, y: 10)
                Text(model.details?.title ?? movie.title)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.75)
                    .padding(.horizontal, 22)
                HStack(spacing: 14) {
                    Label(String(format: "%.1f", model.details?.voteAverage ?? movie.voteAverage), systemImage: "star.fill")
                        .foregroundStyle(CineTheme.accent)
                    Text(model.details?.releaseBadge ?? movie.releaseBadge)
                        .font(.subheadline.black).foregroundStyle(.white)
                }
            }.padding(.bottom, 20)
        }
        .frame(height: 500)
    }

    private var releaseCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("USCITA IN ITALIA").font(.caption.weight(.black)).tracking(1.8).foregroundStyle(CineTheme.accent)
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "calendar.badge.clock").font(.title).foregroundStyle(CineTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.details?.releaseBadge ?? movie.releaseBadge).font(.title3.black)
                    Text(model.details?.formattedReleaseDate ?? movie.formattedReleaseDate).foregroundStyle(CineTheme.secondaryText)
                }
                Spacer()
            }
            Button {
                favorites.toggle(movie)
            } label: {
                Label(favorites.contains(movie) ? "Nella mia lista" : "Aggiungi alla mia lista", systemImage: favorites.contains(movie) ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .foregroundStyle(.black).background(CineTheme.accent).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }.padding(18).cineCard(cornerRadius: 22)
    }

    @ViewBuilder
    private func detailsBody(_ details: MovieDetails) -> some View {
        if !details.genres.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(details.genres) { genre in
                        Text(genre.name).font(.caption.bold()).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(CineTheme.surfaceRaised).clipShape(Capsule())
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("LA STORIA").font(.caption.weight(.black)).tracking(1.8).foregroundStyle(CineTheme.accent)
            Text(details.overview.isEmpty ? "Trama non disponibile in italiano." : details.overview)
                .font(.body).foregroundStyle(.white.opacity(0.88)).lineSpacing(6).fixedSize(horizontal: false, vertical: true)
        }

        HStack(spacing: 12) {
            infoBox(icon: "clock.fill", title: "Durata", value: details.runtime.map { "\($0) min" } ?? "Non indicata")
            infoBox(icon: "film.fill", title: "Formato", value: "Cinema")
        }

        if let trailer = details.trailerURL {
            Button { openURL(trailer) } label: {
                HStack { Image(systemName: "play.fill"); Text("Guarda il trailer") }
                    .font(.headline).foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(CineTheme.gradient).clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }

        if let cast = details.credits?.cast.prefix(12), !cast.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("CAST PRINCIPALE").font(.caption.weight(.black)).tracking(1.8).foregroundStyle(CineTheme.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Array(cast)) { person in
                            VStack(spacing: 8) {
                                RemoteImage(url: person.imageURL).frame(width: 86, height: 108).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                Text(person.name).font(.caption.bold()).lineLimit(2).multilineTextAlignment(.center)
                                Text(person.character ?? "").font(.caption2).foregroundStyle(CineTheme.secondaryText).lineLimit(2).multilineTextAlignment(.center)
                            }.frame(width: 94)
                        }
                    }
                }
            }
        }
    }

    private func infoBox(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(CineTheme.accent)
            Text(title).font(.caption).foregroundStyle(CineTheme.secondaryText)
            Text(value).font(.headline)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).cineCard(cornerRadius: 18)
    }
}
