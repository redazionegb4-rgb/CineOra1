import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var reminders: ReminderStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    remindersCard
                    linksCard
                    aboutCard
                    creditsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 42)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INFO E IMPOSTAZIONI")
                .font(.caption.weight(.black))
                .tracking(2)
                .foregroundStyle(CineTheme.accent)
            Text("Tutto sotto controllo")
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text("Gestisci le uscite che aspetti e consulta le informazioni essenziali di CineOra.")
                .foregroundStyle(CineTheme.secondaryText)
                .lineSpacing(3)
        }
    }

    private var remindersCard: some View {
        NavigationLink {
            ActiveRemindersView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(CineTheme.accent.opacity(0.16))
                    Image(systemName: "bell.badge.fill")
                        .font(.title2)
                        .foregroundStyle(CineTheme.accent)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Promemoria attivi")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                    Text(reminders.movies.isEmpty ? "Nessuna uscita programmata" : "\(reminders.movies.count) film in attesa")
                        .font(.subheadline)
                        .foregroundStyle(CineTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CineTheme.secondaryText)
            }
            .padding(18)
            .cineCard(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var linksCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "hand.raised.fill", title: "Privacy", subtitle: "Come vengono gestiti i dati") {
                open("https://3-cuo.icu/cineora/privacy.html")
            }
            Divider().overlay(CineTheme.divider).padding(.leading, 70)
            infoRow(icon: "questionmark.bubble.fill", title: "Assistenza", subtitle: "Aiuto e domande frequenti") {
                open("https://3-cuo.icu/cineora/support.html")
            }
            Divider().overlay(CineTheme.divider).padding(.leading, 70)
            infoRow(icon: "exclamationmark.bubble.fill", title: "Segnala un problema", subtitle: "Contatta il supporto") {
                open("mailto:assistenza@3-cuo.icu?subject=Problema%20CineOra")
            }
        }
        .cineCard(cornerRadius: 22)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Cos’è CineOra", systemImage: "film.stack.fill")
                .font(.headline.weight(.heavy))
                .foregroundStyle(CineTheme.accent)
            Text("Una guida semplice e aggiornata ai film nelle sale italiane e alle prossime uscite. Puoi esplorare generi, trailer, cast e salvare i titoli che vuoi vedere.")
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(5)
            Text("Gli orari dei singoli cinema e l’acquisto dei biglietti non sono inclusi.")
                .font(.caption)
                .foregroundStyle(CineTheme.secondaryText)
        }
        .padding(18)
        .cineCard(cornerRadius: 22)
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dati cinematografici", systemImage: "externaldrive.fill")
                .font(.headline.weight(.heavy))
                .foregroundStyle(CineTheme.accent)
            TMDBCreditView()
            Text("Questo prodotto utilizza l’API TMDB ma non è approvato o certificato da TMDB.")
                .font(.caption)
                .foregroundStyle(CineTheme.secondaryText)
                .lineSpacing(4)
        }
        .padding(18)
        .cineCard(cornerRadius: 22)
    }

    private func infoRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(CineTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(CineTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.body.weight(.bold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(CineTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CineTheme.secondaryText)
            }
            .padding(15)
        }
        .buttonStyle(.plain)
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        openURL(url)
    }
}

struct ActiveRemindersView: View {
    @EnvironmentObject private var reminders: ReminderStore

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            if reminders.movies.isEmpty {
                ContentUnavailableView(
                    "Nessun promemoria attivo",
                    systemImage: "bell.slash.fill",
                    description: Text("Apri un film in uscita e premi Avvisami per ricevere una notifica il giorno prima.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(reminders.movies) { movie in
                            reminderRow(movie)
                        }
                    }
                    .padding(18)
                }
            }
        }
        .navigationTitle("Promemoria attivi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reminderRow(_ movie: Movie) -> some View {
        HStack(spacing: 14) {
            RemoteImage(url: movie.posterURL)
                .frame(width: 72, height: 108)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 7) {
                Text(movie.title)
                    .font(.headline.weight(.heavy))
                    .lineLimit(2)
                Text(movie.formattedReleaseDate)
                    .font(.subheadline)
                    .foregroundStyle(CineTheme.secondaryText)
                Text(countdown(movie))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CineTheme.accent)
                Label("Notifica il giorno prima", systemImage: "bell.fill")
                    .font(.caption2)
                    .foregroundStyle(CineTheme.secondaryText)
            }
            Spacer(minLength: 4)
            Button(role: .destructive) { reminders.remove(movie) } label: {
                Image(systemName: "trash.fill")
                    .frame(width: 38, height: 38)
                    .background(Color.red.opacity(0.14))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .cineCard(cornerRadius: 20)
    }

    private func countdown(_ movie: Movie) -> String {
        guard let days = ReleaseDateFormatter.daysUntil(movie.releaseDate) else { return "Data da definire" }
        if days == 0 { return "Esce oggi" }
        if days == 1 { return "Manca 1 giorno" }
        if days > 1 { return "Mancano \(days) giorni" }
        return "Uscita già avvenuta"
    }
}

struct TMDBCreditView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(CineTheme.accent)
            Text("Dati e immagini forniti da TMDB").font(.caption).foregroundStyle(CineTheme.secondaryText)
        }
    }
}
