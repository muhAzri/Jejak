import Swinject

final class SessionAssembly: Assembly {
    func assemble(container: Container) {
        // Services
        container.register(LocationTrackingService.self) { _ in
            MainActor.assumeIsolated { LocationTrackingServiceImpl() }
        }.inObjectScope(.container)

        // Use cases
        container.register(TrackLocation.self) { r in
            MainActor.assumeIsolated {
                TrackLocation(r.resolve(LocationTrackingService.self)!)
            }
        }.inObjectScope(.container)

        container.register(SaveSession.self) { r in
            SaveSession(r.resolve(SessionRepository.self)!)
        }.inObjectScope(.container)

        // ViewModel: new instance per session
        container.register(ActiveSessionViewModel.self) { (r, activity: ActivityType) in
            MainActor.assumeIsolated {
                ActiveSessionViewModel(
                    activity: activity,
                    getDistanceUnit: r.resolve(GetDistanceUnit.self)!,
                    trackLocation: r.resolve(TrackLocation.self)!,
                    saveSession: r.resolve(SaveSession.self)!
                )
            }
        }
    }
}
