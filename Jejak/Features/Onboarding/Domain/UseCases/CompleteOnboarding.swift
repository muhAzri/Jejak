struct CompleteOnboarding {
    private let repository: OnboardingRepository
    init(_ repository: OnboardingRepository) { self.repository = repository }
    func callAsFunction() { repository.markCompleted() }
}
