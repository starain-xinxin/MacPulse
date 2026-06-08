import Foundation
import CoreLocation

/// Manages CoreLocation authorization.
///
/// On macOS Sonoma and later, reading the current Wi-Fi SSID via CoreWLAN
/// requires the app to hold Location authorization. This manager requests
/// that authorization so `NetworkMonitorService` can resolve the SSID. It
/// also exposes the most recent placemark for optional precise geolocation.
@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    /// Whether the app currently holds authorization sufficient to read the SSID.
    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways
    }

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    /// Request location authorization. Safe to call repeatedly; the system
    /// only prompts once and returns the cached decision afterwards.
    func requestAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestAlwaysAuthorization()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
