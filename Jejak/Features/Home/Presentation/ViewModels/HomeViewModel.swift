import Observation

/// Location notice shown above the start cards.
enum HomeNotice: Equatable {
    case none
    /// Never asked (e.g. "Not Now" in onboarding): offers the system dialog right here.
    case locationNotRequested
    case locationDenied
    case locationAllowedOnce
}

@MainActor
@Observable
final class HomeViewModel {
    private(set) var permission: LocationPermission
    private(set) var lastSession: SessionSummary?
    private(set) var unit: DistanceUnit
    private(set) var isRequestingPermission = false
    private var isOnceNoticeDismissed = false

    private let getLastSession: GetLastSession
    private let deleteSession: DeleteSession
    private let getDistanceUnit: GetDistanceUnit
    private let getLocationPermission: GetLocationPermission
    private let observeLocationPermission: ObserveLocationPermission
    private let requestLocationPermission: RequestLocationPermission

    init(getLastSession: GetLastSession,
         deleteSession: DeleteSession,
         getDistanceUnit: GetDistanceUnit,
         getLocationPermission: GetLocationPermission,
         observeLocationPermission: ObserveLocationPermission,
         requestLocationPermission: RequestLocationPermission) {
        self.getLastSession = getLastSession
        self.deleteSession = deleteSession
        self.getDistanceUnit = getDistanceUnit
        self.getLocationPermission = getLocationPermission
        self.observeLocationPermission = observeLocationPermission
        self.requestLocationPermission = requestLocationPermission
        permission = getLocationPermission()
        lastSession = getLastSession()
        unit = getDistanceUnit()
    }

    var notice: HomeNotice {
        switch permission {
        case .notDetermined: .locationNotRequested
        case .denied: .locationDenied
        case .allowedOnce where !isOnceNoticeDismissed: .locationAllowedOnce
        default: .none
        }
    }

    /// Starting needs location; when it is off the cards are locked and the notice explains why.
    var canStart: Bool { permission != .denied }

    /// Re-reads everything Home shows: on appear, after Settings, and when returning from iOS Settings.
    func refresh() {
        permission = getLocationPermission()
        lastSession = getLastSession()
        unit = getDistanceUnit()
    }

    /// Removes a saved session for good; the one before it, if any, becomes the last session.
    func delete(_ session: SessionSummary) {
        deleteSession(id: session.id)
        lastSession = getLastSession()
    }

    /// Follows permission changes for as long as the calling task runs.
    func observePermission() async {
        for await permission in observeLocationPermission() {
            self.permission = permission
        }
    }

    func dismissOnceNotice() { isOnceNoticeDismissed = true }

    /// Shows the system dialog when iOS still allows asking.
    func requestPermission() async {
        guard !permission.isGranted, permission != .denied, !isRequestingPermission else { return }
        isRequestingPermission = true
        await requestLocationPermission()
        isRequestingPermission = false
        permission = getLocationPermission()
    }

    /// Asks for location if needed. Returns true when a session may start.
    func prepareToStart() async -> Bool {
        guard canStart, !isRequestingPermission else { return false }
        await requestPermission()
        return permission.isGranted
    }
}
