@MainActor
struct ObserveLocationPermission {
    private let service: LocationPermissionService
    init(_ service: LocationPermissionService) { self.service = service }
    func callAsFunction() -> AsyncStream<LocationPermission> { service.updates() }
}
