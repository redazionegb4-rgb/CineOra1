import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class CinemaNearbyViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var position: MapCameraPosition = .automatic
    @Published var cinemas: [MKMapItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let locationManager = CLLocationManager()
    private var hasRequestedSearch = false

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Attiva la posizione nelle Impostazioni per trovare i cinema vicini."
        @unknown default:
            break
        }
    }

    func search(in city: String) async {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "cinema"
        request.naturalLanguageQuery = "cinema a \(trimmed)"

        do {
            let response = try await MKLocalSearch(request: request).start()
            cinemas = Array(response.mapItems.prefix(20))
            if let first = cinemas.first {
                let coordinate = first.placemark.coordinate
                position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 12000, longitudinalMeters: 12000))
            }
            if cinemas.isEmpty { errorMessage = "Nessun cinema trovato in questa zona." }
        } catch {
            errorMessage = "Non è stato possibile completare la ricerca."
        }
        isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        position = .region(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 12000, longitudinalMeters: 12000))
        guard !hasRequestedSearch else { return }
        hasRequestedSearch = true
        Task { await searchNearby(location: location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Non riesco a rilevare la posizione. Puoi cercare una città manualmente."
    }

    private func searchNearby(location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "cinema"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 18000, longitudinalMeters: 18000)

        do {
            let response = try await MKLocalSearch(request: request).start()
            cinemas = response.mapItems
                .sorted {
                    let first = CLLocation(latitude: $0.placemark.coordinate.latitude, longitude: $0.placemark.coordinate.longitude)
                    let second = CLLocation(latitude: $1.placemark.coordinate.latitude, longitude: $1.placemark.coordinate.longitude)
                    return first.distance(from: location) < second.distance(from: location)
                }
            if cinemas.isEmpty { errorMessage = "Nessun cinema trovato nelle vicinanze." }
        } catch {
            errorMessage = "Non è stato possibile cercare i cinema vicini."
        }
        isLoading = false
    }
}

struct CinemaNearbyView: View {
    @StateObject private var model = CinemaNearbyViewModel()
    @State private var city = ""

    var body: some View {
        ZStack {
            CineTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchBar
                    mapCard
                    resultHeader
                    cinemaList
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Cinema vicino a te")
        .navigationBarTitleDisplayMode(.inline)
        .task { model.start() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TROVA UNA SALA")
                .font(.caption.weight(.black))
                .tracking(1.8)
                .foregroundStyle(CineTheme.accent)
            Text("Cinema vicino a te")
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text("Visualizza le sale, la distanza e apri subito le indicazioni in Apple Maps.")
                .foregroundStyle(CineTheme.secondaryText)
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CineTheme.secondaryText)
            TextField("Cerca un'altra città", text: $city)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { Task { await model.search(in: city) } }
            Button {
                Task { await model.search(in: city) }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CineTheme.accent)
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 52)
        .background(CineTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(CineTheme.divider))
    }

    private var mapCard: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $model.position) {
                ForEach(Array(model.cinemas.enumerated()), id: \.offset) { _, item in
                    Marker(item.name ?? "Cinema", coordinate: item.placemark.coordinate)
                        .tint(CineTheme.accent)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button {
                model.start()
            } label: {
                Image(systemName: "location.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(CineTheme.accent)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding(14)
        }
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(CineTheme.divider))
    }

    private var resultHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Sale trovate")
                    .font(.title3.weight(.black))
                Text(model.cinemas.isEmpty ? "Cerca una zona o usa la posizione" : "\(model.cinemas.count) risultati")
                    .font(.subheadline)
                    .foregroundStyle(CineTheme.secondaryText)
            }
            Spacer()
            if model.isLoading { ProgressView().tint(CineTheme.accent) }
        }
    }

    @ViewBuilder
    private var cinemaList: some View {
        if let errorMessage = model.errorMessage {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(CineTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .cineCard(cornerRadius: 20)
        }

        LazyVStack(spacing: 12) {
            ForEach(Array(model.cinemas.enumerated()), id: \.offset) { _, cinema in
                CinemaResultRow(item: cinema)
            }
        }
    }
}

private struct CinemaResultRow: View {
    let item: MKMapItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(CineTheme.accent.opacity(0.14))
                Image(systemName: "film.fill")
                    .font(.title3)
                    .foregroundStyle(CineTheme.accent)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.name ?? "Cinema")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(address)
                    .font(.caption)
                    .foregroundStyle(CineTheme.secondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            Button {
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(width: 43, height: 43)
                    .background(CineTheme.accent)
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .cineCard(cornerRadius: 20)
    }

    private var address: String {
        let placemark = item.placemark
        return [placemark.thoroughfare, placemark.locality]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
