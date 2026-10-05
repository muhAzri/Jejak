protocol SessionRepository {
    /// The most recently saved session, if any.
    func latest() -> SessionSummary?
    func save(_ session: SessionSummary)
}
