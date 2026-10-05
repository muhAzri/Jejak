@MainActor
struct TrackLocation {
    private let service: LocationTrackingService
    init(_ service: LocationTrackingService) { self.service = service }
    func callAsFunction() -> AsyncStream<LocationSample> { service.start() }
    func stop() { service.stop() }
}
