import CoreLocation
import Foundation

@MainActor
final class PoopLocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var lastErrorMessage: String?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestAccessIfNeeded() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .restricted, .denied:
            lastErrorMessage = "Location access is off. Enable it in Settings to save poop spots on the map."
        @unknown default:
            lastErrorMessage = "Location permission is unavailable right now."
        }
    }

    func refreshLocation() {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            requestAccessIfNeeded()
        case .restricted, .denied:
            lastErrorMessage = "Location access is off. Enable it in Settings to save poop spots on the map."
        @unknown default:
            lastErrorMessage = "Location permission is unavailable right now."
        }
    }

    func captureLocationForLog() async -> CLLocation? {
        switch authorizationStatus {
        case .restricted, .denied:
            lastErrorMessage = "Location access is off. Enable it in Settings to save poop spots on the map."
            return nil
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            try? await Task.sleep(for: .milliseconds(500))
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }

        if let currentLocation, currentLocation.timestamp.timeIntervalSinceNow > -20 {
            return currentLocation
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                if let continuation = self.locationContinuation {
                    self.locationContinuation = nil
                    continuation.resume(returning: self.currentLocation)
                }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        lastErrorMessage = nil
        if let location = locations.last {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        lastErrorMessage = error.localizedDescription
        locationContinuation?.resume(returning: currentLocation)
        locationContinuation = nil
    }
}
