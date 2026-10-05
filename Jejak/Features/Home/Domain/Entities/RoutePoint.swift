import Foundation

/// One recorded location along a session's route.
struct RoutePoint: Equatable, Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    /// Recorded with a weak GPS fix; drawn dotted.
    let isEstimated: Bool
    /// Increments after every pause (or a GPS jump too far to bridge), so the route is not joined (or timed) across it.
    let segment: Int
    /// Smoothed altitude in meters; nil when GPS gave none (and for sessions saved before it was recorded).
    let altitude: Double?

    init(latitude: Double, longitude: Double, timestamp: Date, isEstimated: Bool, segment: Int, altitude: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.isEstimated = isEstimated
        self.segment = segment
        self.altitude = altitude
    }
}
