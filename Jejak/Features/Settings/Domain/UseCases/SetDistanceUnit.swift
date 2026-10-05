struct SetDistanceUnit {
    private let repository: SettingsRepository
    init(_ repository: SettingsRepository) { self.repository = repository }
    func callAsFunction(_ unit: DistanceUnit) { repository.setDistanceUnit(unit) }
}
