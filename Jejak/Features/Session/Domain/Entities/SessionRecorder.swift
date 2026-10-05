import Foundation

/// Turns location fixes into a route and a distance. Pure value logic; the view model decides when to feed it.
struct SessionRecorder: Equatable {
    /// Fixes less precise than this are dropped entirely.
    static let maxUsableAccuracy: Double = 65
    /// Faster than any run; anything above is a GPS jump.
    static let maxSpeed: Double = 12
    /// Movement below this between fixes is treated as standing still (GPS jitter).
    static let minStep: Double = 3

    private(set) var route: [RoutePoint] = []
    private(set) var distanceMeters: Double = 0
    private(set) var segment = 0
    private var lastAccepted: LocationSample?

    /// Adds the fix to the route when it is usable. Returns whether it was accepted.
    @discardableResult
    mutating func record(_ sample: LocationSample) -> Bool {
        guard sample.horizontalAccuracy >= 0, sample.horizontalAccuracy <= Self.maxUsableAccuracy else { return false }

        if let last = lastAccepted {
            let step = Geo.distance(last.latitude, last.longitude, sample.latitude, sample.longitude)
            guard step >= Self.minStep else { return false }
            let elapsed = sample.timestamp.timeIntervalSince(last.timestamp)
            guard elapsed > 0, step / elapsed <= Self.maxSpeed else { return false }
            distanceMeters += step
        }

        route.append(RoutePoint(latitude: sample.latitude,
                                longitude: sample.longitude,
                                timestamp: sample.timestamp,
                                isEstimated: GPSSignal(accuracy: sample.horizontalAccuracy) != .good,
                                segment: segment))
        lastAccepted = sample
        return true
    }

    /// Called on resume: the gap while paused is neither drawn nor counted.
    mutating func startNewSegment() {
        guard lastAccepted != nil else { return }
        segment += 1
        lastAccepted = nil
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
