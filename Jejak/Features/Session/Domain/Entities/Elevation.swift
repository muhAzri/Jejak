import Foundation

/// Smooths GPS altitude, which is far noisier than horizontal position, with a one-dimensional Kalman filter.
struct AltitudeFilter: Equatable {
    /// Fixes with a vertical error above this (meters) are ignored.
    static let maxUsableAccuracy: Double = 30
    /// How fast (m/s) the true altitude is expected to drift; climbing on foot rarely beats it.
    static let climbRate: Double = 0.5

    private(set) var altitude: Double
    private var variance: Double
    private var timestamp: Date

    /// Nil when the fix has no usable altitude.
    init?(_ sample: LocationSample) {
        guard Self.isUsable(sample) else { return nil }
        altitude = sample.altitude
        variance = sample.verticalAccuracy * sample.verticalAccuracy
        timestamp = sample.timestamp
    }

    mutating func update(with sample: LocationSample) {
        let elapsed = sample.timestamp.timeIntervalSince(timestamp)
        guard Self.isUsable(sample), elapsed > 0 else { return }
        variance += Self.climbRate * Self.climbRate * elapsed
        let gain = variance / (variance + sample.verticalAccuracy * sample.verticalAccuracy)
        altitude += gain * (sample.altitude - altitude)
        variance *= 1 - gain
        timestamp = sample.timestamp
    }

    private static func isUsable(_ sample: LocationSample) -> Bool {
        sample.verticalAccuracy > 0 && sample.verticalAccuracy <= maxUsableAccuracy
    }
}

enum RouteElevation {
    /// Total climb in meters. A rise only counts once it clears `threshold` above the lowest point
    /// since the last counted climb, so leftover altitude noise doesn't add up.
    static func gain(_ route: [RoutePoint], threshold: Double = 3) -> Double {
        var gain = 0.0
        var base: Double?
        var segment: Int?
        for point in route {
            guard let altitude = point.altitude else { continue }
            if point.segment != segment {
                segment = point.segment
                base = altitude
            }
            guard let low = base else { continue }
            if altitude - low >= threshold {
                gain += altitude - low
                base = altitude
            } else if altitude < low {
                base = altitude
            }
        }
        return gain
    }
}
