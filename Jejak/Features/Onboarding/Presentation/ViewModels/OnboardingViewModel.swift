import Observation

enum OnboardingStep: Int, CaseIterable {
    case intro, privacy, location
}

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var step: OnboardingStep = .intro
    private(set) var isRequestingPermission = false

    private let completeOnboarding: CompleteOnboarding
    private let requestLocationPermission: RequestLocationPermission

    init(completeOnboarding: CompleteOnboarding, requestLocationPermission: RequestLocationPermission) {
        self.completeOnboarding = completeOnboarding
        self.requestLocationPermission = requestLocationPermission
    }

    var showsSkip: Bool { step != .location }

    func nextTapped() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    /// Skip jumps to the permission step so location is still explained before the system dialog.
    func skipTapped() { step = .location }

    /// Completes onboarding whatever the user answers in the system dialog; Home handles a denied state.
    func allowLocationTapped() async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        await requestLocationPermission()
        isRequestingPermission = false
        completeOnboarding()
    }

    func laterTapped() { completeOnboarding() }
}
