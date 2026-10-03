import Swinject

final class OnboardingAssembly: Assembly {
    func assemble(container: Container) {
        // Repository & services
        container.register(OnboardingRepository.self) { _ in
            OnboardingRepositoryImpl()
        }.inObjectScope(.container)

        container.register(LocationPermissionService.self) { _ in
            MainActor.assumeIsolated { LocationPermissionServiceImpl() }
        }.inObjectScope(.container)

        // Use cases
        container.register(GetOnboardingStatus.self) { r in
            GetOnboardingStatus(r.resolve(OnboardingRepository.self)!)
        }.inObjectScope(.container)

        container.register(CompleteOnboarding.self) { r in
            CompleteOnboarding(r.resolve(OnboardingRepository.self)!)
        }.inObjectScope(.container)

        container.register(RequestLocationPermission.self) { r in
            MainActor.assumeIsolated {
                RequestLocationPermission(r.resolve(LocationPermissionService.self)!)
            }
        }.inObjectScope(.container)

        // ViewModel: new instance per resolve
        container.register(OnboardingViewModel.self) { r in
            MainActor.assumeIsolated {
                OnboardingViewModel(
                    completeOnboarding: r.resolve(CompleteOnboarding.self)!,
                    requestLocationPermission: r.resolve(RequestLocationPermission.self)!
                )
            }
        }
    }
}
