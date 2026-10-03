struct GetOnboardingStatus {
    private let repository: OnboardingRepository
    init(_ repository: OnboardingRepository) { self.repository = repository }
    func callAsFunction() -> Bool { repository.isCompleted() }
}
