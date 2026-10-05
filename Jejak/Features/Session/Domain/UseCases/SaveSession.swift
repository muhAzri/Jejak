struct SaveSession {
    private let repository: SessionRepository
    init(_ repository: SessionRepository) { self.repository = repository }
    func callAsFunction(_ session: SessionSummary, rawTrack: [RecordedFix]) {
        repository.save(session)
        repository.saveRawTrack(rawTrack, id: session.id)
    }
}
