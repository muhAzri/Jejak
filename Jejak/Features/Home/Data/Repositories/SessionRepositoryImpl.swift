import Foundation
import os

/// Sessions live in one JSON file in Application Support. Jejak has no server, so this is the only copy.
final class SessionRepositoryImpl: SessionRepository {
    private let fileURL: URL
    private var cache: [SessionSummary]?
    private let logger = Logger(subsystem: "Jejak", category: "SessionRepository")

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory.appending(path: "sessions.json")
    }

    func latest() -> SessionSummary? {
        all().max { $0.startDate < $1.startDate }
    }

    func save(_ session: SessionSummary) {
        var sessions = all().filter { $0.id != session.id }
        sessions.append(session)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(sessions).write(to: fileURL, options: [.atomic, .completeFileProtection])
            cache = sessions
        } catch {
            logger.error("Saving session failed: \(error.localizedDescription)")
        }
    }

    private func all() -> [SessionSummary] {
        if let cache { return cache }
        guard let data = try? Data(contentsOf: fileURL) else {
            cache = []
            return []
        }
        do {
            let sessions = try JSONDecoder().decode([SessionSummary].self, from: data)
            cache = sessions
            return sessions
        } catch {
            // Leave the file untouched so a later version can still recover it.
            logger.error("Reading sessions failed: \(error.localizedDescription)")
            return []
        }
    }
}
