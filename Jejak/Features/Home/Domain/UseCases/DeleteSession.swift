import Foundation

struct DeleteSession {
    private let repository: SessionRepository
    init(_ repository: SessionRepository) { self.repository = repository }
    func callAsFunction(id: UUID) { repository.delete(id: id) }
}
