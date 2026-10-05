import Foundation

/// A raw location fix from the device.
struct LocationSample: Equatable {
    let latitude: Double
    let longitude: Double
    /// Radius of uncertainty in meters; negative when the fix is invalid.
    let horizontalAccuracy: Double
    let timestamp: Date
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
