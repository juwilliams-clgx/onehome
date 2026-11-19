import SwiftUI
import MapKit

/// MapKit equivalent of the web prototype's Leaflet map
/// (vision-board-prototype/.../property-map.ts): one price-pin annotation per
/// listing, with the currently-highlighted pin scaling up and darkening -
/// same visual language as the web's `.map-price-pin--highlighted`.
struct PropertyMapView: View {
    let listings: [Listing]
    @Environment(BrowseStore.self) private var browse
    @State private var cameraPosition: MapCameraPosition

    init(listings: [Listing]) {
        self.listings = listings
        _cameraPosition = State(initialValue: .region(Self.region(fitting: listings)))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(listings) { listing in
                Annotation(listing.formattedPrice, coordinate: listing.coordinate) {
                    PricePinView(listing: listing, isHighlighted: browse.highlightedListingID == listing.id)
                }
            }
        }
        .onChange(of: browse.highlightedListingID) { _, newID in
            guard let newID, let listing = listings.first(where: { $0.id == newID }) else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: listing.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    )
                )
            }
        }
    }

    /// A region wide enough to show every listing at once, used as the
    /// initial camera before any card has been focused or highlighted.
    private static func region(fitting listings: [Listing]) -> MKCoordinateRegion {
        guard !listings.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
            )
        }
        let lats = listings.map(\.lat)
        let lngs = listings.map(\.lng)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLng = lngs.min()!, maxLng = lngs.max()!
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
            span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.4 + 2, longitudeDelta: (maxLng - minLng) * 1.4 + 2)
        )
    }
}

private struct PricePinView: View {
    let listing: Listing
    let isHighlighted: Bool

    var body: some View {
        Text(listing.formattedPriceCompact)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHighlighted ? Color(red: 0.043, green: 0.290, blue: 0.341) : Color(red: 0.075, green: 0.478, blue: 0.561), in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: isHighlighted ? 6 : 3, y: 2)
            .scaleEffect(isHighlighted ? 1.18 : 1.0)
            .zIndex(isHighlighted ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
}

extension Listing {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// Short form for map pins ($2.5M / $610K), matching the web map's `formatPrice`.
    var formattedPriceCompact: String {
        if price >= 1_000_000 {
            let millions = Double(price) / 1_000_000
            return millions.truncatingRemainder(dividingBy: 1) == 0
                ? "$\(Int(millions))M"
                : String(format: "$%.1fM", millions)
        }
        return "$\(price / 1000)K"
    }
}
