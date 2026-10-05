import Foundation

/// A saved session, as shown on Home and stored on the device.
struct SessionSummary: Hashable, Identifiable, Codable {
    let id: UUID
    let activity: ActivityType
    let startDate: Date
    let endDate: Date
    let distanceMeters: Double
    /// Moving time: pauses are not counted.
    let duration: TimeInterval
    let route: [RoutePoint]

    init(id: UUID = UUID(),
         activity: ActivityType,
         startDate: Date,
         endDate: Date? = nil,
         distanceMeters: Double,
         duration: TimeInterval,
         route: [RoutePoint] = []) {
        self.id = id
        self.activity = activity
        self.startDate = startDate
        self.endDate = endDate ?? startDate.addingTimeInterval(duration)
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.route = route
    }

    /// Seconds per meter; nil when no distance was covered.
    var pace: Double? { distanceMeters > 0 ? duration / distanceMeters : nil }

    /// Hashes the id only, so pushing a session onto a navigation path doesn't walk its whole route.
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
