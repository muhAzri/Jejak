struct GetLastSession {
    private let repository: SessionRepository
    init(_ repository: SessionRepository) { self.repository = repository }
    func callAsFunction() -> SessionSummary? { repository.latest() }
}
