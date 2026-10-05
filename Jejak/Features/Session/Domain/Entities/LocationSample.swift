import Foundation

/// A raw location fix from the device. Every reading is kept, so a session can be reprocessed later.
struct LocationSample: Equatable, Codable {
    let latitude: Double
    let longitude: Double
    /// Radius of uncertainty in meters; negative when the fix is invalid.
    let horizontalAccuracy: Double
    let timestamp: Date
    /// Doppler ground speed in m/s; negative when unknown.
    let speed: Double
    /// Meters per second; negative when unknown.
    let speedAccuracy: Double
    /// Direction of travel in degrees clockwise from north; negative when unknown.
    let course: Double
    /// Degrees; negative when unknown.
    let courseAccuracy: Double
    /// Meters above sea level; only meaningful when `verticalAccuracy` is positive.
    let altitude: Double
    /// Meters; zero or negative when the altitude is invalid.
    let verticalAccuracy: Double

    init(latitude: Double,
         longitude: Double,
         horizontalAccuracy: Double,
         timestamp: Date,
         speed: Double = -1,
         speedAccuracy: Double = -1,
         course: Double = -1,
         courseAccuracy: Double = -1,
         altitude: Double = 0,
         verticalAccuracy: Double = -1) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.course = course
        self.courseAccuracy = courseAccuracy
        self.altitude = altitude
        self.verticalAccuracy = verticalAccuracy
    }
}

/// A raw fix as it was recorded, with the recording stretch it belongs to.
struct RecordedFix: Equatable, Codable {
    let sample: LocationSample
    /// Increments on every resume, so a replay restarts the filter where the live recording did.
    let stretch: Int
}

/// GPS quality as shown in the session's top chip.
enum GPSSignal: Equatable {
    /// No usable fix yet.
    case searching
    case good
    /// Fixes are imprecise or have stopped arriving; the route is estimated and current pace hidden.
    case weak

    /// Accuracy (meters) at or below which a fix counts as good.
    static let goodAccuracy: Double = 20

    init(accuracy: Double) {
        self = accuracy >= 0 && accuracy <= Self.goodAccuracy ? .good : .weak
    }
}
