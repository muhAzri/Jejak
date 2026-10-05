struct GetDistanceUnit {
    private let repository: SettingsRepository
    init(_ repository: SettingsRepository) { self.repository = repository }
    func callAsFunction() -> DistanceUnit { repository.distanceUnit() }
}
