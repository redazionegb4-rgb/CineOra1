import SwiftUI

struct RemoteImage: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            case .failure: placeholder
            case .empty: ZStack { placeholder; ProgressView().tint(.white) }
            @unknown default: placeholder
            }
        }
    }
    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.45), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "film.fill").font(.largeTitle).foregroundStyle(.white.opacity(0.5))
        }
    }
}

struct MoviePosterCard: View {
    let movie: Movie
    var width: CGFloat = 145
    var body: some View {
        NavigationLink(value: movie) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: movie.posterURL)
                        .frame(width: width, height: width * 1.5)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Text(movie.releaseBadge)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
                .overlay(alignment: .topTrailing) {
                    Label(movie.formattedRating, systemImage: "star.fill")
                        .font(.caption2.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 5)
                        .background(.black.opacity(0.62)).clipShape(Capsule()).padding(7)
                }
                Text(movie.title)
                    .font(.subheadline.weight(.semibold)).lineLimit(2)
                    .multilineTextAlignment(.leading).foregroundStyle(.white)
                Text(movie.formattedReleaseDate)
                    .font(.caption2).foregroundStyle(CineTheme.secondaryText).lineLimit(1)
            }.frame(width: width, alignment: .leading)
        }.buttonStyle(.plain)
    }
}

struct SectionTitle: View {
    let title: String; var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.bold()).foregroundStyle(.white)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(CineTheme.secondaryText) }
        }
    }
}

struct LoadingStateView: View {
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            ProgressView().scaleEffect(1.2).tint(CineTheme.accent)
            Text(message).foregroundStyle(CineTheme.secondaryText)
        }.frame(maxWidth: .infinity, minHeight: 220)
    }
}
