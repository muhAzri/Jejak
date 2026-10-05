enum LocationPermission: Equatable {
    case notDetermined
    /// Granted with "Allow Once" in an earlier launch; iOS will ask again at the next session.
    case allowedOnce
    case denied
    case whenInUse
    case always

    var isGranted: Bool { self == .whenInUse || self == .always }
}

@MainActor
protocol LocationPermissionService {
    func current() -> LocationPermission
    /// Shows the system dialog if the status is still undetermined, then returns the resulting status.
    func requestWhenInUse() async -> LocationPermission
    /// Emits the current status, then every change (system dialog, iOS Settings).
    func updates() -> AsyncStream<LocationPermission>
}
