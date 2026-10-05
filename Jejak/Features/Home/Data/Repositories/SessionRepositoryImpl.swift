import Foundation
import os

/// Sessions live in one JSON file in Application Support. Jejak has no server, so this is the only copy.
/// Raw tracks are large and rarely read, so each one gets its own file beside it.
final class SessionRepositoryImpl: SessionRepository {
    private let fileURL: URL
    private let rawTrackDirectory: URL
    private var cache: [SessionSummary]?
    private let logger = Logger(subsystem: "Jejak", category: "SessionRepository")

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory.appending(path: "sessions.json")
        rawTrackDirectory = self.fileURL.deletingPathExtension().appendingPathExtension("raw")
    }

    func latest() -> SessionSummary? {
        all().max { $0.startDate < $1.startDate }
    }

    func save(_ session: SessionSummary) {
        var sessions = all().filter { $0.id != session.id }
        sessions.append(session)
        write(sessions)
    }

    func saveRawTrack(_ track: [RecordedFix], id: UUID) {
        do {
            try FileManager.default.createDirectory(at: rawTrackDirectory, withIntermediateDirectories: true)
            try JSONEncoder().encode(track).write(to: rawTrackURL(id), options: [.atomic, .completeFileProtection])
        } catch {
            logger.error("Writing raw track failed: \(error.localizedDescription)")
        }
    }

    func rawTrack(id: UUID) -> [RecordedFix] {
        guard let data = try? Data(contentsOf: rawTrackURL(id)) else { return [] }
        do {
            return try JSONDecoder().decode([RecordedFix].self, from: data)
        } catch {
            logger.error("Reading raw track failed: \(error.localizedDescription)")
            return []
        }
    }

    func delete(id: UUID) {
        write(all().filter { $0.id != id })
        try? FileManager.default.removeItem(at: rawTrackURL(id))
    }

    private func rawTrackURL(_ id: UUID) -> URL {
        rawTrackDirectory.appending(path: "\(id.uuidString).json")
    }

    private func write(_ sessions: [SessionSummary]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(sessions).write(to: fileURL, options: [.atomic, .completeFileProtection])
            cache = sessions
        } catch {
            logger.error("Writing sessions failed: \(error.localizedDescription)")
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
