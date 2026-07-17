import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    featureCard
                    informationCard
                    creditsCard
                    Text("Versione 1.0 • Build 4").font(.caption).foregroundStyle(CineTheme.secondaryText).frame(maxWidth: .infinity)
                }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 40)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CINEORA").font(.caption.weight(.black)).tracking(2).foregroundStyle(CineTheme.accent)
            Text("Il tuo cinema personale").font(.system(size: 30, weight: .black, design: .rounded))
            Text("Date, uscite e titoli da non perdere, tutti in un solo posto.").foregroundStyle(CineTheme.secondaryText)
        }
    }

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingRow(icon: "bell.badge.fill", title: "Promemoria uscite", subtitle: "In arrivo in una prossima versione")
            Divider().overlay(CineTheme.divider).padding(.leading, 66)
            settingRow(icon: "heart.fill", title: "La mia lista", subtitle: "Film salvati sul dispositivo")
            Divider().overlay(CineTheme.divider).padding(.leading, 66)
            settingRow(icon: "moon.stars.fill", title: "Tema cinematografico", subtitle: "Interfaccia scura ottimizzata")
        }.cineCard(cornerRadius: 22)
    }

    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Cosa trovi in CineOra", systemImage: "sparkles.tv.fill").font(.headline).foregroundStyle(CineTheme.accent)
            Text("Film attualmente nelle sale, prossime uscite, date italiane, categorie, trailer, cast e una lista personale.")
                .foregroundStyle(.white.opacity(0.86)).lineSpacing(5)
            Text("Gli orari dei singoli cinema e i biglietti non sono ancora inclusi.")
                .font(.caption).foregroundStyle(CineTheme.secondaryText)
        }.padding(18).cineCard(cornerRadius: 22)
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dati cinematografici", systemImage: "externaldrive.fill").font(.headline).foregroundStyle(CineTheme.accent)
            TMDBCreditView()
            Text("Questo prodotto utilizza l’API TMDB ma non è approvato o certificato da TMDB.")
                .font(.caption).foregroundStyle(CineTheme.secondaryText).lineSpacing(4)
        }.padding(18).cineCard(cornerRadius: 22)
    }

    private func settingRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(CineTheme.accent)
                .frame(width: 42, height: 42).background(CineTheme.surfaceRaised).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.bold))
                Text(subtitle).font(.caption).foregroundStyle(CineTheme.secondaryText)
            }
            Spacer()
        }.padding(15)
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
