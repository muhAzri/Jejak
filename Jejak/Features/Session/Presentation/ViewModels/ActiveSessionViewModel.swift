import Foundation
import Observation

enum SessionPhase: Equatable {
    /// Waiting for the first good fix; nothing is recorded yet.
    case searching
    case recording
    case paused
    /// Stopped; the summary decides between saving and discarding.
    case finished
}

@MainActor
@Observable
final class ActiveSessionViewModel {
    /// Sessions shorter than either limit can't be saved.
    static let minDistance: Double = 100
    static let minDuration: TimeInterval = 60
    /// With no fix for this long the signal counts as weak.
    static let staleFixInterval: TimeInterval = 10

    let activity: ActivityType
    private(set) var unit: DistanceUnit
    private(set) var phase: SessionPhase = .searching
    private(set) var isLocked = false
    private(set) var isShowingTooShort = false
    private(set) var recorder: SessionRecorder
    /// The latest fix, accepted or not; drives the signal chip.
    private(set) var lastSample: LocationSample?
    /// Updated every second by `runClock()`; all elapsed times are measured against it.
    private(set) var now: Date

    private(set) var startDate: Date?
    private(set) var endDate: Date?
    /// Moving time banked before the current recording stretch.
    private var bankedDuration: TimeInterval = 0
    private var recordingSince: Date?
    private(set) var pausedSince: Date?

    private let trackLocation: TrackLocation
    private let saveSession: SaveSession
    private let clock: () -> Date

    init(activity: ActivityType,
         getDistanceUnit: GetDistanceUnit,
         trackLocation: TrackLocation,
         saveSession: SaveSession,
         clock: @escaping () -> Date = { .now }) {
        self.activity = activity
        recorder = SessionRecorder(activity: activity)
        self.trackLocation = trackLocation
        self.saveSession = saveSession
        self.clock = clock
        now = clock()
        unit = getDistanceUnit()
    }

    // MARK: Derived state

    var signal: GPSSignal {
        guard let lastSample else { return .searching }
        if now.timeIntervalSince(lastSample.timestamp) > Self.staleFixInterval { return .weak }
        return GPSSignal(accuracy: lastSample.horizontalAccuracy)
    }

    /// The position dot: smoothed, so it stays on the route instead of jumping with every fix.
    var position: LocationSample? { recorder.estimatedPosition ?? lastSample }

    var distanceMeters: Double { recorder.distanceMeters }
    var route: [RoutePoint] { recorder.route }

    var duration: TimeInterval {
        bankedDuration + (recordingSince.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }

    var pausedDuration: TimeInterval {
        pausedSince.map { max(0, now.timeIntervalSince($0)) } ?? 0
    }

    /// Hidden while paused or when the signal is weak, as the estimate would be misleading.
    var currentPace: Double? {
        guard phase == .recording, signal == .good else { return nil }
        return RoutePace.recent(route)
    }

    var averagePace: Double? { distanceMeters > 0 ? duration / distanceMeters : nil }

    var canSave: Bool { distanceMeters >= Self.minDistance && duration >= Self.minDuration }

    // MARK: Lifetime

    /// Consumes location fixes for as long as the calling task runs.
    func track() async {
        for await sample in trackLocation() {
            receive(sample)
        }
    }

    /// Ticks `now` once a second for as long as the calling task runs.
    func runClock() async {
        while !Task.isCancelled {
            tick()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    func tick() { now = clock() }

    func receive(_ sample: LocationSample) {
        // Core Location first replays its last known fix, which can be minutes old and miles away.
        guard clock().timeIntervalSince(sample.timestamp) <= Self.staleFixInterval else { return }
        lastSample = sample
        now = max(now, sample.timestamp)
        switch phase {
        case .searching:
            if GPSSignal(accuracy: sample.horizontalAccuracy) == .good {
                startRecording()
                recorder.record(sample)
            }
        case .recording:
            recorder.record(sample)
        case .paused, .finished:
            break
        }
    }

    // MARK: Actions

    /// "Start Anyway" while still searching for GPS.
    func startRecording() {
        guard phase == .searching else { return }
        now = clock()
        startDate = now
        recordingSince = now
        phase = .recording
    }

    func pause() {
        guard phase == .recording else { return }
        now = clock()
        bankDuration()
        pausedSince = now
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        now = clock()
        recordingSince = now
        pausedSince = nil
        recorder.startNewSegment()
        phase = .recording
    }

    func lock() { isLocked = true }
    func unlock() { isLocked = false }

    /// Hold-to-finish completed. Too-short sessions ask whether to keep going instead.
    func finish() {
        guard phase == .recording || phase == .paused else { return }
        now = clock()
        if !canSave {
            isShowingTooShort = true
            return
        }
        bankDuration()
        recorder.finish()
        pausedSince = nil
        endDate = now
        phase = .finished
        trackLocation.stop()
    }

    /// "Keep Going" on the too-short sheet.
    func keepGoing() {
        isShowingTooShort = false
        resume()
    }

    func save() {
        guard phase == .finished, let startDate, let endDate else { return }
        saveSession(SessionSummary(activity: activity,
                                   startDate: startDate,
                                   endDate: endDate,
                                   distanceMeters: distanceMeters,
                                   duration: duration,
                                   route: route))
    }

    /// Cancel, discard, or leaving while searching: nothing is stored.
    func discard() {
        isShowingTooShort = false
        trackLocation.stop()
    }

    private func bankDuration() {
        if let recordingSince { bankedDuration += max(0, now.timeIntervalSince(recordingSince)) }
        recordingSince = nil
    }
}
