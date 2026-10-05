@MainActor
protocol LocationTrackingService {
    /// Starts precise location updates (continuing in the background) and emits every fix
    /// until the stream's consumer stops listening or `stop()` is called.
    func start() -> AsyncStream<LocationSample>
    func stop()
}
