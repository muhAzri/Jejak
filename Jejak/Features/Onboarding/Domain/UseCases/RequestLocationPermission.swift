@MainActor
struct RequestLocationPermission {
    private let service: LocationPermissionService
    init(_ service: LocationPermissionService) { self.service = service }

    @discardableResult
    func callAsFunction() async -> LocationPermission { await service.requestWhenInUse() }
}
