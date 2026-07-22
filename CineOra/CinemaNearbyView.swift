import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class CinemaNearbyViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let maximumRadius: CLLocationDistance = 100_000

    @Published var position: MapCameraPosition = .automatic
    @Published var cinemas: [MKMapItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var referenceLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var hasRequestedSearch = false

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        errorMessage = nil

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Attiva la posizione nelle Impostazioni per trovare i cinema nel raggio di 100 km. Puoi anche cercare una città manualmente."
        @unknown default:
            errorMessage = "Non è stato possibile verificare il permesso della posizione."
        }
    }

    func search(in city: String) async {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        cinemas = []

        do {
            let placemarks = try await geocoder.geocodeAddressString(trimmed)
            guard let coordinate = placemarks.first?.location?.coordinate else {
                errorMessage = "Località non trovata. Controlla il nome e riprova."
                isLoading = false
                return
            }

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            referenceLocation = location
            await searchCinemas(around: location)
        } catch {
            errorMessage = "Non è stato possibile trovare questa località."
            isLoading = false
        }
    }

    func distanceText(for item: MKMapItem) -> String? {
        guard let referenceLocation else { return nil }
        let itemLocation = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )
        let kilometres = itemLocation.distance(from: referenceLocation) / 1_000

        if kilometres < 1 {
            return "\(Int(kilometres * 1_000)) m"
        }
        return String(format: "%.1f km", kilometres)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        referenceLocation = location

        guard !hasRequestedSearch else {
            updateMapRegion(centeredOn: location)
            return
        }

        hasRequestedSearch = true
        Task { await searchCinemas(around: location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Non riesco a rilevare la posizione. Puoi cercare una città manualmente."
    }

    private func searchCinemas(around location: CLLocation) async {
        isLoading = true
        errorMessage = nil

        let request = MKLocalSearch.Request()
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.movieTheater])
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: Self.maximumRadius * 2,
            longitudinalMeters: Self.maximumRadius * 2
        )

        do {
            let response = try await MKLocalSearch(request: request).start()

            let filtered = response.mapItems
                .filter { item in
                    guard item.pointOfInterestCategory == .movieTheater else { return false }
                    let itemLocation = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    return itemLocation.distance(from: location) <= Self.maximumRadius
                }
                .sorted { first, second in
                    distance(of: first, from: location) < distance(of: second, from: location)
                }

            cinemas = removeDuplicates(from: filtered)
            updateMapRegion(centeredOn: location)

            if cinemas.isEmpty {
                errorMessage = "Nessun cinema trovato nel raggio di 100 km."
            }
        } catch {
            cinemas = []
            updateMapRegion(centeredOn: location)
            errorMessage = "Non è stato possibile cercare i cinema nel raggio di 100 km."
        }

        isLoading = false
    }

    private func distance(of item: MKMapItem, from location: CLLocation) -> CLLocationDistance {
        CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        ).distance(from: location)
    }

    private func removeDuplicates(from items: [MKMapItem]) -> [MKMapItem] {
        var keys = Set<String>()
        return items.filter { item in
            let coordinate = item.placemark.coordinate
            let key = "\(item.name?.lowercased() ?? "cinema")|\(String(format: "%.4f", coordinate.latitude))|\(String(format: "%.4f", coordinate.longitude))"
            return keys.insert(key).inserted
        }
    }

    private func updateMapRegion(centeredOn location: CLLocation) {
        position = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: Self.maximumRadius * 2.15,
                longitudinalMeters: Self.maximumRadius * 2.15
            )
        )
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
            Text("Mostriamo esclusivamente cinema entro un raggio massimo di 100 km dalla posizione o dalla città cercata.")
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
                UserAnnotation()

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
                Text("Cinema trovati")
                    .font(.title3.weight(.black))
                Text(model.cinemas.isEmpty ? "Ricerca entro 100 km" : "\(model.cinemas.count) risultati entro 100 km")
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
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.system(size: 34))
                    .foregroundStyle(CineTheme.accent)
                Text(errorMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .cineCard(cornerRadius: 20)
        }

        LazyVStack(spacing: 12) {
            ForEach(Array(model.cinemas.enumerated()), id: \.offset) { _, cinema in
                CinemaResultRow(item: cinema, distanceText: model.distanceText(for: cinema))
            }
        }
    }
}

private struct CinemaResultRow: View {
    let item: MKMapItem
    let distanceText: String?

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

                if let distanceText {
                    Label(distanceText, systemImage: "location.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CineTheme.accent)
                }
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
        let components = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.postalCode,
            placemark.locality
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        return components.isEmpty ? "Indirizzo non disponibile" : components.joined(separator: ", ")
    }
}
