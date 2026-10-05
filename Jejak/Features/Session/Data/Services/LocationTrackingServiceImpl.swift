import CoreLocation
import Foundation

@MainActor
final class LocationTrackingServiceImpl: NSObject, LocationTrackingService, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: AsyncStream<LocationSample>.Continuation?
    private var streamID: UUID?
    /// Keeps When In Use updates running while the screen is off or another app is in front.
    private var backgroundSession: CLBackgroundActivitySession?

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() -> AsyncStream<LocationSample> {
        continuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: LocationSample.self, bufferingPolicy: .bufferingNewest(32))
        self.continuation = continuation
        let id = UUID()
        streamID = id
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                // A newer start() owns the updates now.
                guard self.streamID == id else { return }
                self.continuation = nil
                self.stopUpdates()
            }
        }

        backgroundSession = CLBackgroundActivitySession()
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        return stream
    }

    func stop() {
        continuation?.finish()
        continuation = nil
        stopUpdates()
    }

    private func stopUpdates() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        backgroundSession?.invalidate()
        backgroundSession = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            continuation?.yield(LocationSample(latitude: location.coordinate.latitude,
                                               longitude: location.coordinate.longitude,
                                               horizontalAccuracy: location.horizontalAccuracy,
                                               timestamp: location.timestamp))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // kCLErrorLocationUnknown is transient; the signal chip shows the gap. Other errors end the stream.
        if (error as? CLError)?.code != .locationUnknown { stop() }
    }
}
