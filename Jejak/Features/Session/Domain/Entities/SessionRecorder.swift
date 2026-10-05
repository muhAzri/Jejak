import Foundation

/// Turns location fixes into a route and a distance. Pure value logic; the view model decides when to feed it.
///
/// Each fix goes through: quality check → outlier rejection and Kalman smoothing (`TrackFilter`)
/// → stop detection → distance. The raw fixes are kept as they came, so a session can be replayed.
struct SessionRecorder: Equatable {
    /// Fixes less precise than this are dropped entirely.
    static let maxUsableAccuracy: Double = 65
    /// After this long without an accepted fix, the estimate is stale and the filter starts over.
    static let maxGap: TimeInterval = 10
    /// Rejections in a row after which GPS is trusted over the filter's own estimate.
    static let maxConsecutiveOutliers = 5
    /// Fixes in a row that must look like movement before a stop ends, so one wild estimate doesn't.
    static let fixesToStart = 3

    let activity: ActivityType
    private(set) var route: [RoutePoint] = []
    private(set) var segment = 0
    /// Every fix handed to `record`, accepted or not.
    private(set) var rawTrack: [RecordedFix] = []
    /// False while standing still (or before moving at all); GPS wander then neither draws nor counts.
    private(set) var isMoving = false
    private var stretch = 0
    private var filter: TrackFilter?
    private var altitudeFilter: AltitudeFilter?
    private var outliersInARow = 0
    private var movingFixesInARow = 0
    /// Where the runner stopped.
    private var stop: RoutePoint?
    /// The latest smoothed position; while moving it runs up to one point spacing ahead of the route.
    private var latest: RoutePoint?
    private var routeDistance: Double = 0

    init(activity: ActivityType) {
        self.activity = activity
    }

    /// Reprocesses a recorded session with the current algorithm.
    init(activity: ActivityType, replaying fixes: [RecordedFix]) {
        self.init(activity: activity)
        for fix in fixes {
            while stretch < fix.stretch { startNewSegment() }
            record(fix.sample)
        }
        finish()
    }

    /// Meters covered, including the stretch since the last route point.
    var distanceMeters: Double {
        guard isMoving, let latest, let last = route.last, last.segment == latest.segment else { return routeDistance }
        return routeDistance + Geo.distance(last, latest)
    }

    /// The smoothed current position, carrying the latest fix's accuracy and time.
    var estimatedPosition: LocationSample? {
        guard let latest, let last = rawTrack.last?.sample else { return nil }
        return LocationSample(latitude: latest.latitude, longitude: latest.longitude,
                              horizontalAccuracy: last.horizontalAccuracy, timestamp: last.timestamp)
    }

    /// Feeds a fix through the pipeline. Returns whether it added a point to the route.
    @discardableResult
    mutating func record(_ sample: LocationSample) -> Bool {
        rawTrack.append(RecordedFix(sample: sample, stretch: stretch))
        let profile = activity.motionProfile
        guard sample.horizontalAccuracy >= 0, sample.horizontalAccuracy <= Self.maxUsableAccuracy,
              sample.speed <= profile.maxSpeed else { return false }

        guard var next = filter,
              sample.timestamp.timeIntervalSince(next.timestamp) <= Self.maxGap,
              outliersInARow < Self.maxConsecutiveOutliers else {
            return restart(at: sample)
        }
        guard next.update(with: sample) else {
            outliersInARow += 1
            return false
        }
        outliersInARow = 0
        filter = next
        altitudeFilter?.update(with: sample)
        if altitudeFilter == nil { altitudeFilter = AltitudeFilter(sample) }

        let point = makePoint(next.latitude, next.longitude, sample)
        latest = point
        if isMoving {
            if next.speed < profile.stopSpeed {
                isMoving = false
                stop = point
            } else if let last = route.last,
                      Geo.distance(last, point) < max(profile.pointSpacing, 3 * next.positionAccuracy) {
                // Chords well beyond the estimate's own wobble keep leftover jitter from adding up.
                return false
            }
        } else {
            // Leaving the stop: past both the GPS's own wander and the starting speed, for a few fixes running.
            guard let stop, next.speed >= profile.startSpeed,
                  Geo.distance(stop, point) > max(profile.stopRadius, sample.horizontalAccuracy) else {
                movingFixesInARow = 0
                return false
            }
            movingFixesInARow += 1
            guard movingFixesInARow >= Self.fixesToStart else { return false }
            movingFixesInARow = 0
            isMoving = true
        }
        append(point)
        return true
    }

    /// Called on resume: the gap while paused is neither drawn nor counted.
    mutating func startNewSegment() {
        commitLatest()
        stretch += 1
        filter = nil
        latest = nil
        isMoving = false
        if route.last?.segment == segment { segment += 1 }
    }

    /// Called when the session ends: draws the route up to the final position.
    mutating func finish() {
        commitLatest()
    }

    private mutating func commitLatest() {
        guard isMoving, let latest, route.last != latest else { return }
        append(latest)
    }

    /// Starts the filter afresh from this fix: at the beginning, after a resume, after a signal gap,
    /// or once GPS has disagreed with the estimate for too long.
    private mutating func restart(at sample: LocationSample) -> Bool {
        commitLatest()
        filter = TrackFilter(sample, profile: activity.motionProfile)
        altitudeFilter = AltitudeFilter(sample)
        outliersInARow = 0
        movingFixesInARow = 0
        isMoving = false
        let profile = activity.motionProfile
        if let last = route.last, last.segment == segment {
            let step = Geo.distance(last.latitude, last.longitude, sample.latitude, sample.longitude)
            if step <= max(profile.stopRadius, sample.horizontalAccuracy) {
                // Still where the route left off.
                stop = last
                latest = last
                return false
            }
            // Bridge the gap only at a speed the activity allows; otherwise break the route here.
            let elapsed = sample.timestamp.timeIntervalSince(last.timestamp)
            if elapsed <= 0 || step / elapsed > profile.maxSpeed { segment += 1 }
        }
        let point = makePoint(sample.latitude, sample.longitude, sample)
        stop = point
        latest = point
        append(point)
        return true
    }

    private mutating func append(_ point: RoutePoint) {
        if let last = route.last, last.segment == point.segment { routeDistance += Geo.distance(last, point) }
        route.append(point)
    }

    private func makePoint(_ latitude: Double, _ longitude: Double, _ sample: LocationSample) -> RoutePoint {
        RoutePoint(latitude: latitude,
                   longitude: longitude,
                   timestamp: sample.timestamp,
                   isEstimated: GPSSignal(accuracy: sample.horizontalAccuracy) != .good,
                   segment: segment,
                   altitude: altitudeFilter?.altitude)
    }
}

enum Geo {
    /// Great-circle distance in meters.
    static func distance(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let radius = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * radius * atan2(sqrt(a), sqrt(1 - a))
    }

    static func distance(_ a: RoutePoint, _ b: RoutePoint) -> Double {
        distance(a.latitude, a.longitude, b.latitude, b.longitude)
    }
}
