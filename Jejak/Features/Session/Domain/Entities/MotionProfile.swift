/// How someone can plausibly move during an activity; tunes the filter and the stop detection.
struct MotionProfile: Equatable {
    /// Faster than anyone doing this activity (m/s); anything above is a GPS jump.
    let maxSpeed: Double
    /// Typical change in velocity per second (m/s²): how quickly the filter lets the estimate turn or speed up.
    let accelerationNoise: Double
    /// Estimated speed (m/s) needed to count as moving again after a stop.
    let startSpeed: Double
    /// Estimated speed (m/s) below which the runner counts as stopped.
    let stopSpeed: Double
    /// Meters the estimate must leave the stop by before movement counts; never less than the fix's accuracy.
    let stopRadius: Double
    /// Minimum meters between route points while moving.
    let pointSpacing: Double
}

extension ActivityType {
    var motionProfile: MotionProfile {
        switch self {
        case .run: MotionProfile(maxSpeed: 12, accelerationNoise: 0.5, startSpeed: 0.8, stopSpeed: 0.5, stopRadius: 8, pointSpacing: 5)
        case .walk: MotionProfile(maxSpeed: 5, accelerationNoise: 0.3, startSpeed: 0.5, stopSpeed: 0.3, stopRadius: 6, pointSpacing: 3)
        }
    }
}
