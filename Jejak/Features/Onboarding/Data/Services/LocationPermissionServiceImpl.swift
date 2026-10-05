import CoreLocation
import Foundation

@MainActor
final class LocationPermissionServiceImpl: NSObject, LocationPermissionService, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let defaults: UserDefaults
    private var continuation: CheckedContinuation<LocationPermission, Never>?
    private var subscribers: [UUID: AsyncStream<LocationPermission>.Continuation] = [:]
    private let wasGrantedKey = "location.wasGranted"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        manager.delegate = self
    }

    /// iOS has no API for "Allow Once": it reports When In Use, then resets to not-determined after
    /// the app session ends. A not-determined status after a grant is therefore treated as Allow Once.
    func current() -> LocationPermission {
        let status = manager.authorizationStatus
        if status == .notDetermined && defaults.bool(forKey: wasGrantedKey) { return .allowedOnce }
        return Self.map(status)
    }

    func requestWhenInUse() async -> LocationPermission {
        guard manager.authorizationStatus == .notDetermined else { return current() }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func updates() -> AsyncStream<LocationPermission> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: LocationPermission.self,
                                                             bufferingPolicy: .bufferingNewest(1))
        subscribers[id] = continuation
        continuation.yield(current())
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.subscribers[id] = nil }
        }
        return stream
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: defaults.set(true, forKey: wasGrantedKey)
        case .denied, .restricted: defaults.set(false, forKey: wasGrantedKey)
        default: break
        }
        let permission = current()
        for subscriber in subscribers.values { subscriber.yield(permission) }

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
