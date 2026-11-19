import Foundation
import CoreLocation
import Observation

/// Detects the buyer's approximate location so the search header can default
/// to it instead of a generic placeholder - same job as the web prototype's
/// IP-based LocationService, but done the native way: on-device GPS via
/// CoreLocation (with the system permission prompt), reverse-geocoded to a
/// city/state/zip. A phone has a far better, user-trusted location mechanism
/// than IP lookup, so this reconforms rather than porting the web technique.
@Observable
final class LocationStore: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var displayLocation: String?
    var isLoading = true

    override init() {
        super.init()
        manager.delegate = self
        requestLocation()
    }

    private func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            // Denied/restricted: the header just falls back to its placeholder.
            isLoading = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLoading = false
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            defer { self.isLoading = false }
            guard let placemark = placemarks?.first,
                  let city = placemark.locality,
                  let state = placemark.administrativeArea else {
                return
            }
            if let zip = placemark.postalCode {
                self.displayLocation = "\(city), \(state) \(zip)"
            } else {
                self.displayLocation = "\(city), \(state)"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
    }
}
