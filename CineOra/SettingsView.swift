import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SectionTitle(title: "CineOra", subtitle: "Versione 1.0 • Build 1")
                    VStack(spacing: 0) {
                        Label("Notifiche sulle uscite", systemImage: "bell.badge.fill").frame(maxWidth: .infinity, alignment: .leading).padding()
                        Divider().overlay(Color.white.opacity(0.1))
                        Label("Tema cinema", systemImage: "moon.stars.fill").frame(maxWidth: .infinity, alignment: .leading).padding()
                    }.cineCard()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Crediti dati").font(.headline)
                        TMDBCreditView()
                        Text("Questo prodotto utilizza l’API TMDB ma non è approvato o certificato da TMDB.").font(.caption).foregroundStyle(CineTheme.secondaryText)
                    }.padding().cineCard()
                    Text("Prima build: la sezione notifiche sarà attivata nella prossima versione.").font(.footnote).foregroundStyle(CineTheme.secondaryText)
                }.padding(18)
            }
        }.navigationTitle("Altro").navigationBarTitleDisplayMode(.inline)
    }
}

struct TMDBCreditView: View {
    var body: some View { HStack(spacing: 8) { Image(systemName: "database.fill").foregroundStyle(CineTheme.accent); Text("Dati e immagini forniti da TMDB").font(.caption).foregroundStyle(CineTheme.secondaryText) } }
}
