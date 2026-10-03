import Foundation

final class OnboardingRepositoryImpl: OnboardingRepository {
    private let defaults: UserDefaults
    private let key = "onboarding.completed"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func isCompleted() -> Bool { defaults.bool(forKey: key) }
    func markCompleted() { defaults.set(true, forKey: key) }
}
