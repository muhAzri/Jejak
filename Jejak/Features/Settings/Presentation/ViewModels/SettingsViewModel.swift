import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var unit: DistanceUnit
    private(set) var locationPermission: LocationPermission

    private let setDistanceUnit: SetDistanceUnit
    private let getLocationPermission: GetLocationPermission
    private let observeLocationPermission: ObserveLocationPermission
    private let requestLocationPermission: RequestLocationPermission

    init(getDistanceUnit: GetDistanceUnit,
         setDistanceUnit: SetDistanceUnit,
         getLocationPermission: GetLocationPermission,
         observeLocationPermission: ObserveLocationPermission,
         requestLocationPermission: RequestLocationPermission) {
        self.setDistanceUnit = setDistanceUnit
        self.getLocationPermission = getLocationPermission
        self.observeLocationPermission = observeLocationPermission
        self.requestLocationPermission = requestLocationPermission
        unit = getDistanceUnit()
        locationPermission = getLocationPermission()
    }

    /// The app language, named in that language ("Indonesia", "English").
    let languageName: String = {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        let name = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }()

    let version: String = {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }()

    func select(_ unit: DistanceUnit) {
        guard unit != self.unit else { return }
        self.unit = unit
        setDistanceUnit(unit)
    }

    /// iOS Settings only lists Location for an app that has asked at least once,
    /// so a never-asked app shows the system dialog instead of sending the user there.
    var locationRowRequestsPermission: Bool { locationPermission == .notDetermined }

    /// Re-reads the permission, e.g. after returning from iOS Settings.
    func refresh() { locationPermission = getLocationPermission() }

    /// Follows permission changes for as long as the calling task runs.
    func observePermission() async {
        for await permission in observeLocationPermission() {
            locationPermission = permission
        }
    }

    func requestPermission() async {
        await requestLocationPermission()
        locationPermission = getLocationPermission()
    }
}
