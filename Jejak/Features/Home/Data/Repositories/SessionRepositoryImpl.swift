/// Sessions are not recorded yet (Active Session and Summary come next), so there is never a last session.
/// Replace with the real store once saving lands.
final class SessionRepositoryImpl: SessionRepository {
    func latest() -> SessionSummary? { nil }
}
