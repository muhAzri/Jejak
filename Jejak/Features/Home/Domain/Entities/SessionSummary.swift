import Foundation

/// A saved session as shown on Home.
struct SessionSummary: Equatable {
    let activity: ActivityType
    let startDate: Date
    let distanceMeters: Double
    let duration: TimeInterval

    /// Seconds per meter; nil when no distance was covered.
    var pace: Double? { distanceMeters > 0 ? duration / distanceMeters : nil }
}
