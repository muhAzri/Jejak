import Swinject

final class SettingsAssembly: Assembly {
    func assemble(container: Container) {
        // Repository
        container.register(SettingsRepository.self) { _ in
            SettingsRepositoryImpl()
        }.inObjectScope(.container)

        // Use cases
        container.register(GetDistanceUnit.self) { r in
            GetDistanceUnit(r.resolve(SettingsRepository.self)!)
        }.inObjectScope(.container)

        container.register(SetDistanceUnit.self) { r in
            SetDistanceUnit(r.resolve(SettingsRepository.self)!)
        }.inObjectScope(.container)

        // ViewModel: new instance per resolve
        container.register(SettingsViewModel.self) { r in
            MainActor.assumeIsolated {
                SettingsViewModel(
                    getDistanceUnit: r.resolve(GetDistanceUnit.self)!,
                    setDistanceUnit: r.resolve(SetDistanceUnit.self)!,
                    getLocationPermission: r.resolve(GetLocationPermission.self)!,
                    observeLocationPermission: r.resolve(ObserveLocationPermission.self)!,
                    requestLocationPermission: r.resolve(RequestLocationPermission.self)!
                )
            }
        }
    }
}
