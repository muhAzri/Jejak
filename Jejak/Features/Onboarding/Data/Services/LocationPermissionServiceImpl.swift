import CoreLocation

@MainActor
final class LocationPermissionServiceImpl: NSObject, LocationPermissionService, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<LocationPermission, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func current() -> LocationPermission { Self.map(manager.authorizationStatus) }

    func requestWhenInUse() async -> LocationPermission {
        guard manager.authorizationStatus == .notDetermined else { return current() }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        continuation?.resume(returning: Self.map(manager.authorizationStatus))
        continuation = nil
    }

    private static func map(_ status: CLAuthorizationStatus) -> LocationPermission {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted, .denied: .denied
        case .authorizedWhenInUse: .whenInUse
        case .authorizedAlways: .always
        @unknown default: .denied
        }
    }
}
