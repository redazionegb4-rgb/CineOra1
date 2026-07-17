import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = false
    @State private var showAbout = false

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    featureCard
                    informationCard
                    creditsCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Altro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CineTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Notifiche in arrivo", isPresented: $notificationsEnabled) {
            Button("Va bene", role: .cancel) { }
        } message: {
            Text("Nella prossima build potrai ricevere un avviso quando esce un film salvato nella tua lista.")
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [CineTheme.accent2.opacity(0.9), CineTheme.accent.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.09)).frame(width: 150).offset(x: 220, y: -30)
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "popcorn.fill").font(.system(size: 36)).foregroundStyle(.white)
                Text("CineOra").font(.system(size: 32, weight: .black, design: .rounded))
                Text("Tutto il cinema, nel momento giusto.").font(.subheadline).foregroundStyle(.white.opacity(0.84))
                Text("Versione 1.0 • Build 2").font(.caption.bold()).foregroundStyle(.white.opacity(0.68))
            }.padding(22)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var featureCard: some View {
        VStack(spacing: 0) {
            settingRow(icon: "bell.badge.fill", title: "Notifiche sulle uscite", subtitle: "Avvisi per i film della tua lista") {
                notificationsEnabled = true
            }
            Divider().overlay(.white.opacity(0.08)).padding(.leading, 68)
            settingRow(icon: "calendar", title: "Calendario uscite", subtitle: "Date italiane mostrate in ogni scheda") { }
            Divider().overlay(.white.opacity(0.08)).padding(.leading, 68)
            settingRow(icon: "moon.stars.fill", title: "Tema cinema", subtitle: "Grafica ottimizzata in modalità scura") { }
        }.cineCard(cornerRadius: 24)
    }

    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Informazioni", systemImage: "info.circle.fill").font(.headline).foregroundStyle(.white)
            Text("CineOra mostra i film attualmente nelle sale italiane, le prossime uscite, i titoli popolari e le date di uscita disponibili.")
                .font(.subheadline).foregroundStyle(CineTheme.secondaryText).lineSpacing(4)
            Text("Gli orari dei singoli cinema e la disponibilità dei biglietti non sono inclusi in questa versione.")
                .font(.caption).foregroundStyle(CineTheme.secondaryText)
        }.padding(18).cineCard(cornerRadius: 22)
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Crediti e dati", systemImage: "database.fill").font(.headline).foregroundStyle(.white)
            TMDBCreditView()
            Text("Questo prodotto utilizza l’API TMDB ma non è approvato o certificato da TMDB.")
                .font(.caption).foregroundStyle(CineTheme.secondaryText).lineSpacing(3)
        }.padding(18).cineCard(cornerRadius: 22)
    }

    private func settingRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3).foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(CineTheme.gradient).clipShape(RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.body.weight(.semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(CineTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(CineTheme.secondaryText)
            }.padding(15)
        }.buttonStyle(.plain)
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
