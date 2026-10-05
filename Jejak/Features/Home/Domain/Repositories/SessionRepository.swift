import Foundation

protocol SessionRepository {
    /// The most recently saved session, if any.
    func latest() -> SessionSummary?
    func save(_ session: SessionSummary)
    /// Every fix as the device reported it, kept beside the session so it can be reprocessed later.
    func saveRawTrack(_ track: [RecordedFix], id: UUID)
    func rawTrack(id: UUID) -> [RecordedFix]
    /// Removes the session and its raw track.
    func delete(id: UUID)
}
