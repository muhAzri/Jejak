import Foundation

/// Estimates position and velocity from noisy fixes with a constant-velocity Kalman filter.
/// Works in meters on a plane tangent at the first fix, which is accurate over any session's span.
struct TrackFilter: Equatable {
    /// Squared Mahalanobis distance from the prediction above which a fix is an outlier (χ², 2 dof, 99.9%).
    static let outlierGate: Double = 13.8
    static let metersPerDegree = 6_371_000.0 * .pi / 180

    private let originLatitude: Double
    private let originLongitude: Double
    private let metersPerDegreeLongitude: Double
    private let profile: MotionProfile
    private var east: Axis
    private var north: Axis
    private(set) var timestamp: Date

    init(_ sample: LocationSample, profile: MotionProfile) {
        originLatitude = sample.latitude
        originLongitude = sample.longitude
        metersPerDegreeLongitude = Self.metersPerDegree * cos(sample.latitude * .pi / 180)
        self.profile = profile
        timestamp = sample.timestamp
        // Position is as good as the fix; velocity could be anything the activity allows.
        let axis = Axis(position: 0, velocity: 0,
                        positionVariance: Self.variance(sample.horizontalAccuracy),
                        covariance: 0,
                        velocityVariance: profile.maxSpeed * profile.maxSpeed)
        east = axis
        north = axis
        if let velocity = Self.velocity(of: sample) { correctVelocity(velocity) }
    }

    var latitude: Double { originLatitude + north.position / Self.metersPerDegree }
    var longitude: Double { originLongitude + east.position / metersPerDegreeLongitude }
    /// Estimated ground speed in m/s.
    var speed: Double { hypot(east.velocity, north.velocity) }
    /// One standard deviation of the estimated position, in meters.
    var positionAccuracy: Double { sqrt((east.positionVariance + north.positionVariance) / 2) }

    /// Folds the fix into the estimate. Returns false, leaving the estimate untouched, when the fix
    /// is an outlier: out of order, a jump faster than the activity allows, or a change in motion
    /// the track so far can't explain.
    mutating func update(with sample: LocationSample) -> Bool {
        let elapsed = sample.timestamp.timeIntervalSince(timestamp)
        guard elapsed > 0 else { return false }
        let x = (sample.longitude - originLongitude) * metersPerDegreeLongitude
        let y = (sample.latitude - originLatitude) * Self.metersPerDegree
        let r = Self.variance(sample.horizontalAccuracy)

        // Even granting the fix its whole error radius, it moved faster than anyone could.
        let jump = hypot(x - east.position, y - north.position) - max(0, sample.horizontalAccuracy)
        guard jump / elapsed <= profile.maxSpeed else { return false }

        var next = self
        let q = profile.accelerationNoise * profile.accelerationNoise
        next.east.predict(elapsed, q)
        next.north.predict(elapsed, q)
        guard next.east.normalizedInnovation(x, r) + next.north.normalizedInnovation(y, r) <= Self.outlierGate else {
            return false
        }
        next.east.correctPosition(x, r)
        next.north.correctPosition(y, r)
        if let velocity = Self.velocity(of: sample) { next.correctVelocity(velocity) }
        next.timestamp = sample.timestamp
        self = next
        return true
    }

    private mutating func correctVelocity(_ velocity: (east: Double, north: Double, variance: Double)) {
        east.correctVelocity(velocity.east, velocity.variance)
        north.correctVelocity(velocity.north, velocity.variance)
    }

    private static func variance(_ accuracy: Double) -> Double {
        let meters = max(accuracy, 1)
        return meters * meters
    }

    /// The Doppler velocity, when the device reported one. Without a course the direction is unknown,
    /// so each component is anywhere within ±speed around zero.
    private static func velocity(of sample: LocationSample) -> (east: Double, north: Double, variance: Double)? {
        guard sample.speed >= 0, sample.speedAccuracy >= 0 else { return nil }
        let speedVariance = max(sample.speedAccuracy * sample.speedAccuracy, 0.01)
        guard sample.course >= 0, sample.courseAccuracy >= 0 else {
            return (0, 0, speedVariance + sample.speed * sample.speed)
        }
        let course = sample.course * .pi / 180
        let sideways = sample.speed * sample.courseAccuracy * .pi / 180
        return (sample.speed * sin(course), sample.speed * cos(course), speedVariance + sideways * sideways)
    }

    /// One axis of the state: position and velocity with their 2×2 covariance.
    private struct Axis: Equatable {
        var position: Double
        var velocity: Double
        var positionVariance: Double
        var covariance: Double
        var velocityVariance: Double

        /// Moves the estimate forward assuming constant velocity, perturbed by white-noise acceleration of variance `q`.
        mutating func predict(_ dt: Double, _ q: Double) {
            position += velocity * dt
            positionVariance += 2 * dt * covariance + dt * dt * velocityVariance + q * pow(dt, 4) / 4
            covariance += dt * velocityVariance + q * pow(dt, 3) / 2
            velocityVariance += q * dt * dt
        }

        func normalizedInnovation(_ measured: Double, _ variance: Double) -> Double {
            let innovation = measured - position
            return innovation * innovation / (positionVariance + variance)
        }

        mutating func correctPosition(_ measured: Double, _ variance: Double) {
            let s = positionVariance + variance
            let positionGain = positionVariance / s
            let velocityGain = covariance / s
            let innovation = measured - position
            position += positionGain * innovation
            velocity += velocityGain * innovation
            velocityVariance -= velocityGain * covariance
            covariance *= 1 - positionGain
            positionVariance *= 1 - positionGain
        }

        mutating func correctVelocity(_ measured: Double, _ variance: Double) {
            let s = velocityVariance + variance
            let positionGain = covariance / s
            let velocityGain = velocityVariance / s
            let innovation = measured - velocity
            position += positionGain * innovation
            velocity += velocityGain * innovation
            positionVariance -= positionGain * covariance
            covariance *= 1 - velocityGain
            velocityVariance *= 1 - velocityGain
        }
    }
}
