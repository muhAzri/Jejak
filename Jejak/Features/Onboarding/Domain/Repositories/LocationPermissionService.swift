enum LocationPermission: Equatable {
    case notDetermined
    case denied
    case whenInUse
    case always
}

@MainActor
protocol LocationPermissionService {
    func current() -> LocationPermission
    /// Shows the system dialog if the status is still undetermined, then returns the resulting status.
    func requestWhenInUse() async -> LocationPermission
}
