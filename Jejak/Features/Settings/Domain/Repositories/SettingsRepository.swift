protocol SettingsRepository {
    func distanceUnit() -> DistanceUnit
    func setDistanceUnit(_ unit: DistanceUnit)
}
