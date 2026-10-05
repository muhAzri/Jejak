@MainActor
struct GetLocationPermission {
    private let service: LocationPermissionService
    init(_ service: LocationPermissionService) { self.service = service }
    func callAsFunction() -> LocationPermission { service.current() }
}
