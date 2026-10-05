import Foundation

/// Display formatting for session metrics, following the active locale ("5,24" in Indonesian).
enum SessionFormat {
    static func distance(_ meters: Double, unit: DistanceUnit) -> String {
        (meters / unit.metersPerUnit).formatted(.number.precision(.fractionLength(2)))
    }

    /// "28:41", or "1:02:05" past an hour.
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    /// Minutes per unit, e.g. "5:28". `secondsPerMeter` is nil when no distance was covered.
    static func pace(_ secondsPerMeter: Double?, unit: DistanceUnit) -> String {
        guard let secondsPerMeter else { return "–:––" }
        let total = Int((secondsPerMeter * unit.metersPerUnit).rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
