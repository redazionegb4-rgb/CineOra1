import SwiftUI

struct RemoteImage: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            case .failure: placeholder
            case .empty: ZStack { placeholder; ProgressView().tint(CineTheme.accent) }
            @unknown default: placeholder
            }
        }
    }
    private var placeholder: some View {
        ZStack {
            CineTheme.surfaceRaised
            Image(systemName: "film.stack.fill").font(.largeTitle).foregroundStyle(CineTheme.accent.opacity(0.65))
        }
    }
}

struct MoviePosterCard: View {
    let movie: Movie
    var width: CGFloat = 148
    var body: some View {
        NavigationLink(value: movie) {
            VStack(alignment: .leading, spacing: 9) {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: movie.posterURL)
                        .frame(width: width, height: width * 1.48)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.74)], startPoint: .center, endPoint: .bottom)
                    Text(movie.releaseBadge.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(CineTheme.accent.opacity(0.95))
                        .clipShape(Capsule())
                        .padding(9)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundStyle(CineTheme.accent)
                        Text(movie.formattedRating)
                    }
                    .font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(.black.opacity(0.72)).clipShape(Capsule()).padding(8)
                }
                Text(movie.title)
                    .font(.subheadline.weight(.bold)).lineLimit(2)
                    .multilineTextAlignment(.leading).foregroundStyle(.white)
                Text(movie.formattedReleaseDate)
                    .font(.caption).foregroundStyle(CineTheme.secondaryText).lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
        }.buttonStyle(.plain)
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.weight(.black)).foregroundStyle(.white)
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(CineTheme.secondaryText) }
            }
            Spacer()
            if let actionTitle { Text(actionTitle).font(.caption.bold()).foregroundStyle(CineTheme.accent) }
        }
    }
}

struct ReleaseInfoPill: View {
    let movie: Movie
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "calendar.badge.clock")
            Text(movie.releaseBadge)
            Text("•")
            Text(movie.formattedReleaseDate)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(CineTheme.surfaceRaised)
        .clipShape(Capsule())
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
