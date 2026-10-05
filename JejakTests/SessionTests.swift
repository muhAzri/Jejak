import Foundation
import Testing
@testable import Jejak

/// ~11.1 m per 0.0001° of latitude.
private let metersPerStep = Geo.distance(0, 0, 0.0001, 0)

private func sample(_ step: Int, at seconds: TimeInterval, accuracy: Double = 5, from start: Date) -> LocationSample {
    LocationSample(latitude: Double(step) * 0.0001, longitude: 0, horizontalAccuracy: accuracy,
                   timestamp: start.addingTimeInterval(seconds))
}

/// Deterministic Gaussian noise, so the noisy-GPS tests are repeatable.
private struct Noise {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func gaussian(_ sigma: Double) -> Double {
        let u1 = max(uniform(), .leastNonzeroMagnitude)
        let u2 = uniform()
        return sigma * sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }

    private mutating func uniform() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}

/// A fix `east`/`north` meters from the origin, blurred by `sigma` meters of GPS noise.
private func noisyFix(east: Double, north: Double, at time: Date, sigma: Double, noise: inout Noise,
                      altitude: Double = 0, verticalAccuracy: Double = -1) -> LocationSample {
    LocationSample(latitude: (north + noise.gaussian(sigma)) / TrackFilter.metersPerDegree,
                   longitude: (east + noise.gaussian(sigma)) / TrackFilter.metersPerDegree,
                   horizontalAccuracy: sigma * 1.5,
                   timestamp: time,
                   altitude: altitude,
                   verticalAccuracy: verticalAccuracy)
}

struct SessionRecorderTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    @Test func accumulatesDistanceAlongTheRoute() {
        var recorder = SessionRecorder(activity: .run)
        for step in 0...10 { recorder.record(sample(step, at: Double(step) * 4, from: start)) }
        #expect(recorder.isMoving)
        #expect(recorder.route.first?.latitude == 0)
        // The smoothed estimate trails the last fix by a little.
        #expect(abs(recorder.distanceMeters - metersPerStep * 10) < 3)
    }

    @Test func dropsImpreciseJitteryAndImpossibleFixes() {
        var recorder = SessionRecorder(activity: .run)
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
        var recorder = SessionRecorder(activity: .run)
        recorder.record(sample(0, at: 0, from: start))
        for step in 1...8 { recorder.record(sample(step, at: Double(step) * 4, accuracy: 40, from: start)) }
        #expect(recorder.route.first?.isEstimated == false)
        #expect(recorder.route.count > 1)
        #expect(recorder.route.dropFirst().allSatisfy { $0.isEstimated })
    }

    @Test func doesNotCountTheGapAcrossAPause() {
        var recorder = SessionRecorder(activity: .run)
        for step in 0...5 { recorder.record(sample(step, at: Double(step) * 4, from: start)) }
        recorder.startNewSegment()
        for step in 20...25 { recorder.record(sample(step, at: Double(step) * 4, from: start)) }
        #expect(abs(recorder.distanceMeters - metersPerStep * 10) < 4)
        #expect(Set(recorder.route.map(\.segment)) == [0, 1])
    }

    @Test func standingStillAddsNoDistance() {
        var noise = Noise(seed: 7)
        var withoutDoppler = SessionRecorder(activity: .run)
        var withDoppler = SessionRecorder(activity: .run)
        for second in 0..<300 {
            let fix = noisyFix(east: 0, north: 0, at: start.addingTimeInterval(Double(second)), sigma: 5, noise: &noise)
            withoutDoppler.record(fix)
            withDoppler.record(LocationSample(latitude: fix.latitude, longitude: fix.longitude,
                                              horizontalAccuracy: fix.horizontalAccuracy, timestamp: fix.timestamp,
                                              speed: abs(noise.gaussian(0.15)), speedAccuracy: 0.3))
        }
        // Summing the raw fixes would make this a ~2 km "run".
        #expect(withoutDoppler.distanceMeters < 30)
        #expect(withDoppler.distanceMeters == 0)
        #expect(!withDoppler.isMoving)
    }

    @Test func followsCornersWithoutCuttingThem() {
        var noise = Noise(seed: 5)
        var recorder = SessionRecorder(activity: .run)
        // Three laps of a 100 m square at 3 m/s.
        for second in 0...400 {
            let along = (Double(second) * 3).truncatingRemainder(dividingBy: 400)
            let side = Int(along / 100)
            let offset = along - Double(side) * 100
            let (east, north) = [(offset, 0), (100, offset), (100 - offset, 100), (0, 100 - offset)][side]
            recorder.record(noisyFix(east: east, north: north, at: start.addingTimeInterval(Double(second)), sigma: 4, noise: &noise))
        }
        #expect(abs(recorder.distanceMeters - 1200) < 1200 * 0.04)
    }

    @Test func noisyRunMeasuresCloseToTheTrueDistance() {
        var noise = Noise(seed: 42)
        var recorder = SessionRecorder(activity: .run)
        var raw = 0.0
        var previous: LocationSample?
        // 10 minutes at 3 m/s: 1800 m.
        for second in 0...600 {
            let fix = noisyFix(east: Double(second) * 3, north: 0, at: start.addingTimeInterval(Double(second)),
                               sigma: 4, noise: &noise)
            if let previous { raw += Geo.distance(previous.latitude, previous.longitude, fix.latitude, fix.longitude) }
            previous = fix
            recorder.record(fix)
        }
        #expect(abs(recorder.distanceMeters - 1800) < 1800 * 0.03)
        #expect(raw > 1800 * 1.3)   // what the old naive sum would have reported
    }

    @Test func stopAtATrafficLightIsNotCounted() {
        var noise = Noise(seed: 3)
        var recorder = SessionRecorder(activity: .run)
        var east = 0.0
        for second in 0...180 {
            // Run, wait a minute at the light, run on: 120 s × 3 m/s = 360 m.
            if !(60..<120).contains(second) { east += 3 }
            recorder.record(noisyFix(east: east, north: 0, at: start.addingTimeInterval(Double(second)), sigma: 4, noise: &noise))
        }
        #expect(abs(recorder.distanceMeters - 360) < 360 * 0.05)
    }

    @Test func rejectsAGPSSpikeMidRun() {
        var recorder = SessionRecorder(activity: .run)
        for second in 0...30 {
            let east = second == 15 ? 45 + 60.0 : Double(second) * 3   // one fix 60 m off the line
            recorder.record(LocationSample(latitude: 0, longitude: east / TrackFilter.metersPerDegree,
                                           horizontalAccuracy: 5, timestamp: start.addingTimeInterval(Double(second))))
        }
        #expect(abs(recorder.distanceMeters - 90) < 5)
    }

    @Test func plausibleSpeedDependsOnTheActivity() {
        let fast = LocationSample(latitude: 0, longitude: 0, horizontalAccuracy: 5, timestamp: start,
                                  speed: 7, speedAccuracy: 0.5)
        var run = SessionRecorder(activity: .run)
        var walk = SessionRecorder(activity: .walk)
        let runAccepted = run.record(fast)
        let walkAccepted = walk.record(fast)
        #expect(runAccepted)
        #expect(!walkAccepted)
    }

    @Test func dopplerSpeedTellsMovingFromStanding() {
        var recorder = SessionRecorder(activity: .walk)
        for second in 0...20 {
            recorder.record(LocationSample(latitude: Double(second) * 1.4 / TrackFilter.metersPerDegree, longitude: 0,
                                           horizontalAccuracy: 5, timestamp: start.addingTimeInterval(Double(second)),
                                           speed: 1.4, speedAccuracy: 0.3, course: 0, courseAccuracy: 10))
        }
        #expect(recorder.isMoving)
        #expect(abs(recorder.distanceMeters - 28) < 3)
    }

    @Test func keepsEveryRawFixAndReplaysToTheSameResult() {
        var noise = Noise(seed: 11)
        var recorder = SessionRecorder(activity: .run)
        for second in 0...60 {
            recorder.record(noisyFix(east: Double(second) * 3, north: 0, at: start.addingTimeInterval(Double(second)), sigma: 4, noise: &noise))
        }
        recorder.startNewSegment()
        for second in 200...260 {
            recorder.record(noisyFix(east: Double(second) * 3, north: 0, at: start.addingTimeInterval(Double(second)), sigma: 4, noise: &noise))
        }
        recorder.finish()
        #expect(recorder.rawTrack.count == 122)
        let replayed = SessionRecorder(activity: .run, replaying: recorder.rawTrack)
        #expect(replayed.route == recorder.route)
        #expect(replayed.distanceMeters == recorder.distanceMeters)
    }

    @Test func smoothsAltitudeIntoTheRoute() throws {
        var noise = Noise(seed: 5)
        var recorder = SessionRecorder(activity: .run)
        for second in 0...300 {
            // Climb 30 m over the run; GPS altitude is off by several meters each fix.
            let altitude = Double(second) / 10 + noise.gaussian(6)
            recorder.record(noisyFix(east: Double(second) * 3, north: 0, at: start.addingTimeInterval(Double(second)),
                                     sigma: 4, noise: &noise, altitude: altitude, verticalAccuracy: 8))
        }
        let gain = RouteElevation.gain(recorder.route)
        #expect(abs(gain - 30) < 8)
    }
}

struct RouteElevationTests {
    private func route(_ altitudes: [Double?], segments: [Int]? = nil) -> [RoutePoint] {
        altitudes.enumerated().map { index, altitude in
            RoutePoint(latitude: 0, longitude: 0, timestamp: Date(timeIntervalSince1970: Double(index)),
                       isEstimated: false, segment: segments?[index] ?? 0, altitude: altitude)
        }
    }

    @Test func ignoresWobbleBelowTheThreshold() {
        #expect(RouteElevation.gain(route([10, 12, 10, 12, 10, 12])) == 0)
    }

    @Test func countsClimbsAndSkipsDescents() {
        #expect(RouteElevation.gain(route([10, 14, 20, 15, 18, 25, nil, 25])) == 20)
    }

    @Test func doesNotClimbAcrossAPause() {
        #expect(RouteElevation.gain(route([10, 10, 40, 40], segments: [0, 0, 1, 1])) == 0)
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
        var rawTracks: [UUID: [RecordedFix]] = [:]
        func latest() -> SessionSummary? { saved.last }
        func save(_ session: SessionSummary) { saved.append(session) }
        func saveRawTrack(_ track: [RecordedFix], id: UUID) { rawTracks[id] = track }
        func rawTrack(id: UUID) -> [RecordedFix] { rawTracks[id] ?? [] }
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
        #expect(abs(saved.distanceMeters - metersPerStep * 19) < 2)
        #expect(saved.duration == 76)
        #expect(sessions.rawTrack(id: saved.id).count == 20)
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

    @Test func deletingTheLatestSessionFallsBackToTheOneBefore() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "sessions-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let older = SessionSummary(activity: .walk, startDate: Date(timeIntervalSince1970: 100), distanceMeters: 800, duration: 600)
        let newer = SessionSummary(activity: .run, startDate: Date(timeIntervalSince1970: 5_000), distanceMeters: 5_240, duration: 1_721)
        let repository = SessionRepositoryImpl(fileURL: url)
        repository.save(older)
        repository.save(newer)

        repository.delete(id: newer.id)
        #expect(SessionRepositoryImpl(fileURL: url).latest() == older)

        repository.delete(id: older.id)
        #expect(SessionRepositoryImpl(fileURL: url).latest() == nil)
    }

    @Test func storesRawTracksBesideSessionsAndDeletesThemTogether() {
        let url = FileManager.default.temporaryDirectory.appending(path: "sessions-\(UUID().uuidString).json")
        let rawDirectory = url.deletingPathExtension().appendingPathExtension("raw")
        defer {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: rawDirectory)
        }

        let session = SessionSummary(activity: .run, startDate: Date(timeIntervalSince1970: 5_000), distanceMeters: 500, duration: 200)
        let track = [RecordedFix(sample: LocationSample(latitude: -6.2, longitude: 106.8, horizontalAccuracy: 5,
                                                        timestamp: Date(timeIntervalSince1970: 5_000), speed: 3,
                                                        speedAccuracy: 0.4, course: 90, courseAccuracy: 12,
                                                        altitude: 8, verticalAccuracy: 4),
                                 stretch: 0)]
        let repository = SessionRepositoryImpl(fileURL: url)
        repository.save(session)
        repository.saveRawTrack(track, id: session.id)
        #expect(SessionRepositoryImpl(fileURL: url).rawTrack(id: session.id) == track)

        repository.delete(id: session.id)
        #expect(repository.rawTrack(id: session.id).isEmpty)
    }

    @Test func readsSessionsSavedBeforeAltitudeWasRecorded() throws {
        let json = #"[{"id":"9B1DEB4D-3B7D-4BAD-9BDD-2B0D7B3DCB6D","activity":"run","startDate":0,"endDate":60,"distanceMeters":200,"duration":60,"route":[{"latitude":1,"longitude":2,"timestamp":0,"isEstimated":false,"segment":0}]}]"#
        let sessions = try JSONDecoder().decode([SessionSummary].self, from: Data(json.utf8))
        #expect(sessions.first?.route.first?.altitude == nil)
    }
}
