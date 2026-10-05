import Foundation
import Testing
@testable import Jejak

/// ~11.1 m per 0.0001° of latitude.
private let metersPerStep = Geo.distance(0, 0, 0.0001, 0)

private func sample(_ step: Int, at seconds: TimeInterval, accuracy: Double = 5, from start: Date) -> LocationSample {
    LocationSample(latitude: Double(step) * 0.0001, longitude: 0, horizontalAccuracy: accuracy,
                   timestamp: start.addingTimeInterval(seconds))
}

struct SessionRecorderTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    @Test func accumulatesDistanceAlongTheRoute() {
        var recorder = SessionRecorder()
        for step in 0...10 { recorder.record(sample(step, at: Double(step) * 4, from: start)) }
        #expect(recorder.route.count == 11)
        #expect(abs(recorder.distanceMeters - metersPerStep * 10) < 0.5)
    }

    @Test func dropsImpreciseJitteryAndImpossibleFixes() {
        var recorder = SessionRecorder()
        recorder.record(sample(0, at: 0, from: start))
        let imprecise = recorder.record(sample(1, at: 4, accuracy: 100, from: start))
        let jitter = recorder.record(LocationSample(latitude: 0.00001, longitude: 0, horizontalAccuracy: 5,
                                                    timestamp: start.addingTimeInterval(5)))   // ~1 m
        let jump = recorder.record(sample(50, at: 6, from: start))                            // 550 m in 6 s
        #expect(!imprecise && !jitter && !jump)
        #expect(recorder.route.count == 1)
        #expect(recorder.distanceMeters == 0)
    }

    @Test func marksWeakFixesAsEstimated() {
        var recorder = SessionRecorder()
        recorder.record(sample(0, at: 0, from: start))
        recorder.record(sample(1, at: 4, accuracy: 40, from: start))
        #expect(recorder.route.map(\.isEstimated) == [false, true])
    }

    @Test func doesNotCountTheGapAcrossAPause() {
        var recorder = SessionRecorder()
        recorder.record(sample(0, at: 0, from: start))
        recorder.record(sample(1, at: 4, from: start))
        recorder.startNewSegment()
        recorder.record(sample(20, at: 60, from: start))
        recorder.record(sample(21, at: 64, from: start))
        #expect(abs(recorder.distanceMeters - metersPerStep * 2) < 0.5)
        #expect(recorder.route.map(\.segment) == [0, 0, 1, 1])
    }
}

struct RoutePaceTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    private func route(secondsPerStep: [TimeInterval], segment: Int = 0) -> [RoutePoint] {
        var time: TimeInterval = 0
        return secondsPerStep.enumerated().map { step, seconds in
            time += seconds
            return RoutePoint(latitude: Double(step) * 0.0001, longitude: 0,
                              timestamp: start.addingTimeInterval(time), isEstimated: false, segment: segment)
        }
    }

    @Test func recentPaceUsesTheLastThirtySeconds() throws {
        // 5 s per step for a while, then 3 s per step.
        let points = route(secondsPerStep: Array(repeating: 5, count: 20) + Array(repeating: 3, count: 12))
        let pace = try #require(RoutePace.recent(points))
        #expect(abs(pace - 3 / metersPerStep) < 0.01)
    }

    @Test func recentPaceIsNilWhenStandingStill() {
        let points = route(secondsPerStep: [0, 30])
        #expect(RoutePace.recent(points) == nil)
    }

    @Test func extremesFindFastestAndSlowestStretch() throws {
        let points = route(secondsPerStep: Array(repeating: 6, count: 40) + Array(repeating: 3, count: 40))
        let extremes = try #require(RoutePace.extremes(points))
        #expect(abs(extremes.fastest - 3 / metersPerStep) < 0.01)
        #expect(abs(extremes.slowest - 6 / metersPerStep) < 0.01)
    }

    @Test func noExtremesForShortRoutes() {
        #expect(RoutePace.extremes(route(secondsPerStep: Array(repeating: 4, count: 5))) == nil)
    }
}

@MainActor
struct ActiveSessionViewModelTests {
    private final class Clock { var now = Date(timeIntervalSince1970: 1_000_000) }

    private struct Tracking: LocationTrackingService {
        func start() -> AsyncStream<LocationSample> { AsyncStream { _ in } }
        func stop() {}
    }

    private struct Settings: SettingsRepository {
        func distanceUnit() -> DistanceUnit { .kilometers }
        func setDistanceUnit(_ unit: DistanceUnit) {}
    }

    private final class Sessions: SessionRepository {
        var saved: [SessionSummary] = []
        func latest() -> SessionSummary? { saved.last }
        func save(_ session: SessionSummary) { saved.append(session) }
        func delete(id: UUID) { saved.removeAll { $0.id == id } }
    }

    private let clock = Clock()
    private let sessions = Sessions()

    private func makeModel() -> ActiveSessionViewModel {
        ActiveSessionViewModel(activity: .run,
                               getDistanceUnit: GetDistanceUnit(Settings()),
                               trackLocation: TrackLocation(Tracking()),
                               saveSession: SaveSession(sessions),
                               clock: { [clock] in clock.now })
    }

    /// Moves 1 step (~11 m) every 4 s, as long as `steps`.
    private func walk(_ model: ActiveSessionViewModel, from first: Int, steps: Int) {
        for step in first..<(first + steps) {
            clock.now += 4
            model.receive(LocationSample(latitude: Double(step) * 0.0001, longitude: 0,
                                         horizontalAccuracy: 5, timestamp: clock.now))
        }
    }

    @Test func startsRecordingOnTheFirstGoodFix() {
        let model = makeModel()
        model.receive(LocationSample(latitude: 0, longitude: 0, horizontalAccuracy: 50, timestamp: clock.now))
        #expect(model.phase == .searching)
        #expect(model.signal == .weak)
        model.receive(LocationSample(latitude: 0, longitude: 0, horizontalAccuracy: 5, timestamp: clock.now))
        #expect(model.phase == .recording)
        #expect(model.signal == .good)
    }

    @Test func pausedTimeIsNotCounted() {
        let model = makeModel()
        model.startRecording()
        clock.now += 60
        model.pause()
        clock.now += 300
        model.tick()
        #expect(model.pausedDuration == 300)
        model.resume()
        clock.now += 30
        model.tick()
        #expect(model.duration == 90)
    }

    @Test func tooShortSessionsAskToKeepGoing() {
        let model = makeModel()
        walk(model, from: 0, steps: 5)
        model.finish()
        #expect(model.isShowingTooShort)
        #expect(model.phase == .recording)
        model.keepGoing()
        #expect(!model.isShowingTooShort)
    }

    @Test func savesALongEnoughSession() throws {
        let model = makeModel()
        walk(model, from: 0, steps: 20)   // ~210 m in 76 s
        model.pause()
        model.finish()
        #expect(model.phase == .finished)
        model.save()
        let saved = try #require(sessions.saved.first)
        #expect(saved.activity == .run)
        #expect(saved.route.count == 20)
        #expect(abs(saved.distanceMeters - metersPerStep * 19) < 0.5)
        #expect(saved.duration == 76)
    }

    @Test func weakWhenFixesStopArriving() {
        let model = makeModel()
        walk(model, from: 0, steps: 3)
        #expect(model.signal == .good)
        clock.now += 11
        model.tick()
        #expect(model.signal == .weak)
        #expect(model.currentPace == nil)
    }
}

struct SessionRepositoryTests {
    @Test func savesAndReloadsTheLatestSession() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "sessions-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let older = SessionSummary(activity: .walk, startDate: Date(timeIntervalSince1970: 100), distanceMeters: 800, duration: 600)
        let newer = SessionSummary(activity: .run, startDate: Date(timeIntervalSince1970: 5_000), distanceMeters: 5_240, duration: 1_721,
                                   route: [RoutePoint(latitude: -6.2, longitude: 106.8, timestamp: Date(timeIntervalSince1970: 5_000),
                                                      isEstimated: false, segment: 0)])
        let repository = SessionRepositoryImpl(fileURL: url)
        repository.save(newer)
        repository.save(older)

        #expect(SessionRepositoryImpl(fileURL: url).latest() == newer)
    }
}
