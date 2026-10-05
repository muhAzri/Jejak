import Foundation

final class SettingsRepositoryImpl: SettingsRepository {
    private let defaults: UserDefaults
    private let unitKey = "settings.distanceUnit"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    /// Defaults to the region's measurement system until the user picks one.
    func distanceUnit() -> DistanceUnit {
        if let raw = defaults.string(forKey: unitKey), let unit = DistanceUnit(rawValue: raw) {
            return unit
        }
        return Locale.current.measurementSystem == .us ? .miles : .kilometers
    }

    func setDistanceUnit(_ unit: DistanceUnit) { defaults.set(unit.rawValue, forKey: unitKey) }
}
