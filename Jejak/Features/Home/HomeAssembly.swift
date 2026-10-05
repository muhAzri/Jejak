import Swinject

final class HomeAssembly: Assembly {
    func assemble(container: Container) {
        // Repository
        container.register(SessionRepository.self) { _ in
            SessionRepositoryImpl()
        }.inObjectScope(.container)

        // Use cases
        container.register(GetLastSession.self) { r in
            GetLastSession(r.resolve(SessionRepository.self)!)
        }.inObjectScope(.container)

        container.register(DeleteSession.self) { r in
            DeleteSession(r.resolve(SessionRepository.self)!)
        }.inObjectScope(.container)

        // ViewModel: new instance per resolve
        container.register(HomeViewModel.self) { r in
            MainActor.assumeIsolated {
                HomeViewModel(
                    getLastSession: r.resolve(GetLastSession.self)!,
                    deleteSession: r.resolve(DeleteSession.self)!,
                    getDistanceUnit: r.resolve(GetDistanceUnit.self)!,
                    getLocationPermission: r.resolve(GetLocationPermission.self)!,
                    observeLocationPermission: r.resolve(ObserveLocationPermission.self)!,
                    requestLocationPermission: r.resolve(RequestLocationPermission.self)!
                )
            }
        }
    }
}
