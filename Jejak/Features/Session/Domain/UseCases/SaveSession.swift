struct SaveSession {
    private let repository: SessionRepository
    init(_ repository: SessionRepository) { self.repository = repository }
    func callAsFunction(_ session: SessionSummary) { repository.save(session) }
}
