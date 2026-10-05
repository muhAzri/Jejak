import Foundation

/// One recorded location along a session's route.
struct RoutePoint: Equatable, Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    /// Recorded with a weak GPS fix; drawn dotted.
    let isEstimated: Bool
    /// Increments after every pause, so the route is not joined (or timed) across a pause.
    let segment: Int
}
