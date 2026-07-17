import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: FavoritesStore
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("WATCHLIST").font(.caption.weight(.black)).tracking(2).foregroundStyle(CineTheme.accent)
                            Text("La mia lista").font(.system(size: 30, weight: .black, design: .rounded))
                            Text("I film che non vuoi dimenticare.").foregroundStyle(CineTheme.secondaryText)
                        }
                        if store.movies.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "bookmark.fill").font(.system(size: 42)).foregroundStyle(CineTheme.accent)
                                Text("Nessun film salvato").font(.headline)
                                Text("Apri una scheda e aggiungila alla tua lista.").foregroundStyle(CineTheme.secondaryText).multilineTextAlignment(.center)
                            }.frame(maxWidth: .infinity, minHeight: 360)
                        } else {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(store.movies) { movie in
                                    MoviePosterCard(movie: movie, width: max(130, (proxy.size.width - 50) / 2))
                                }
                            }
                        }
                    }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 36)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Movie.self) { MovieDetailView(movie: $0) }
    }
}
