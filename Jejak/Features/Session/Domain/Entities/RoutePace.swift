import Foundation

/// Pace along a route, in seconds per meter. Only measured within a segment, so pauses never count.
enum RoutePace {
    /// Current pace: the last 30 seconds of the latest segment. Nil while standing still.
    static func recent(_ route: [RoutePoint], window: TimeInterval = 30, minDistance: Double = 15) -> Double? {
        guard let last = route.last else { return nil }
        var distance = 0.0
        var first = last
        for point in route.reversed().dropFirst() {
            guard point.segment == last.segment,
                  last.timestamp.timeIntervalSince(point.timestamp) <= window else { break }
            distance += Geo.distance(point, first)
            first = point
        }
        let elapsed = last.timestamp.timeIntervalSince(first.timestamp)
        guard distance >= minDistance, elapsed > 0 else { return nil }
        return elapsed / distance
    }

    /// Pace at each point, over the stretch of `span` meters ending there. Nil until a segment has covered `span`.
    static func perPoint(_ route: [RoutePoint], span: Double = 200) -> [Double?] {
        guard !route.isEmpty else { return [] }
        // Distance from the segment start to each point.
        var cumulative = [0.0]
        for index in route.indices.dropFirst() {
            let sameSegment = route[index].segment == route[index - 1].segment
            cumulative.append(sameSegment ? cumulative[index - 1] + Geo.distance(route[index - 1], route[index]) : 0)
        }

        var paces: [Double?] = []
        var start = 0
        for end in route.indices {
            if route[end].segment != route[start].segment { start = end }
            // Move the window start forward while it still spans at least `span`.
            while start < end, cumulative[end] - cumulative[start + 1] >= span { start += 1 }
            let distance = cumulative[end] - cumulative[start]
            let elapsed = route[end].timestamp.timeIntervalSince(route[start].timestamp)
            paces.append(distance >= span && elapsed > 0 ? elapsed / distance : nil)
        }
        return paces
    }

    /// Fastest and slowest stretch of the route; nil when no stretch was long enough.
    static func extremes(_ route: [RoutePoint], span: Double = 200) -> (fastest: Double, slowest: Double)? {
        let paces = perPoint(route, span: span).compactMap { $0 }
        guard let fastest = paces.min(), let slowest = paces.max() else { return nil }
        return (fastest, slowest)
    }
}
