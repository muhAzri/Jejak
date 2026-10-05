import MapKit
import SwiftUI

/// One polyline of a route: a stretch with the same segment, color and dash.
struct RouteStroke: Identifiable {
    let id: Int
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
    let isDashed: Bool
}

enum RouteColoring {
    /// One color; weak-signal stretches dotted (live map).
    case solid(Color)
    /// Slow → fast on the gray–yellow–red scale (summary map).
    case pace
}

enum RouteStrokes {
    static func make(_ route: [RoutePoint], coloring: RouteColoring) -> [RouteStroke] {
        guard route.count > 1 else { return [] }

        // Style of the edge ending at each point; consecutive edges with the same style join into one stroke.
        let styles: [(color: Color, isDashed: Bool)]
        switch coloring {
        case .solid(let color):
            styles = route.map { (color, $0.isEstimated) }
        case .pace:
            let middle = paceBuckets.count / 2
            let paces = RoutePace.perPoint(route)
            let extremes = RoutePace.extremes(route)
            styles = paces.map { pace in
                // The first stretch of each segment has no pace yet; it takes the middle of the scale.
                guard let pace, let extremes, extremes.slowest > extremes.fastest else { return (paceBuckets[middle], false) }
                let speed = (extremes.slowest - pace) / (extremes.slowest - extremes.fastest)
                return (paceBuckets[Int((speed * Double(paceBuckets.count - 1)).rounded())], false)
            }
        }

        var strokes: [RouteStroke] = []
        var coordinates: [CLLocationCoordinate2D] = []
        var current: (color: Color, isDashed: Bool)?

        func flush() {
            if coordinates.count > 1, let current {
                strokes.append(RouteStroke(id: strokes.count, coordinates: coordinates,
                                           color: current.color, isDashed: current.isDashed))
            }
            coordinates = []
            current = nil
        }

        for index in route.indices.dropFirst() {
            let previous = route[index - 1], point = route[index]
            guard previous.segment == point.segment else {
                flush()
                continue
            }
            let style = styles[index]
            if current == nil || current!.color != style.color || current!.isDashed != style.isDashed {
                flush()
                coordinates = [previous.coordinate]
                current = style
            }
            coordinates.append(point.coordinate)
        }
        flush()
        return strokes
    }

    /// Seven steps from slow gray through yellow to fast red.
    static let paceBuckets: [Color] = (0..<7).map { step in
        let t = Double(step) / 6
        return t < 0.5
            ? mix(0x9A9A9A, 0xFFEE00, t * 2)
            : mix(0xFFEE00, 0xDB0826, (t - 0.5) * 2)
    }

    private static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> Color {
        func channel(_ hex: UInt32, _ shift: UInt32) -> Double { Double((hex >> shift) & 0xFF) / 255 }
        func lerp(_ shift: UInt32) -> Double { channel(a, shift) + (channel(b, shift) - channel(a, shift)) * t }
        return Color(red: lerp(16), green: lerp(8), blue: lerp(0))
    }
}

extension RoutePoint {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

/// The route with a white casing, as on the design's map overlays.
struct RouteStrokesContent: MapContent {
    let strokes: [RouteStroke]
    var lineWidth: CGFloat = 5

    var body: some MapContent {
        ForEach(strokes) { stroke in
            MapPolyline(coordinates: stroke.coordinates)
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round, lineJoin: .round))
        }
        ForEach(strokes) { stroke in
            MapPolyline(coordinates: stroke.coordinates)
                .stroke(stroke.color, style: StrokeStyle(lineWidth: stroke.isDashed ? lineWidth - 1 : lineWidth,
                                                         lineCap: .round,
                                                         lineJoin: .round,
                                                         dash: stroke.isDashed ? [2, 9] : []))
        }
    }
}

/// Start of the route: white dot with a dark ring.
struct RouteStartMarker: View {
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color(light: 0x262626, dark: 0x262626), lineWidth: 2))
    }
}

/// End of the route: dark rounded square with a white border.
struct RouteEndMarker: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(light: 0x262626, dark: 0x262626))
            .frame(width: 14, height: 14)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(.white, lineWidth: 2))
    }
}

/// A finished route, framed to fit, not interactive: the summary map and Home's route preview.
struct StaticRouteMap: View {
    let route: [RoutePoint]
    let coloring: RouteColoring
    var showsMarkers = true
    var lineWidth: CGFloat = 5

    var body: some View {
        let strokes = RouteStrokes.make(route, coloring: coloring)
        Map(initialPosition: .automatic, interactionModes: []) {
            RouteStrokesContent(strokes: strokes, lineWidth: lineWidth)
            if showsMarkers, let first = route.first, let last = route.last {
                Annotation("", coordinate: first.coordinate, anchor: .center) { RouteStartMarker() }
                Annotation("", coordinate: last.coordinate, anchor: .center) { RouteEndMarker() }
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .accessibilityHidden(true)
    }
}

/// "Slow 6:40 ▬ Fast 4:52" legend over the summary map.
struct PaceLegend: View {
    let slowest: Double
    let fastest: Double
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: 8) {
            Text("Slow \(SessionFormat.pace(slowest, unit: unit))")
            Capsule()
                .fill(LinearGradient(colors: [JejakColor.paceSlow, JejakColor.accent, JejakColor.paceFast],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 48, height: 6)
            Text("Fast \(SessionFormat.pace(fastest, unit: unit))")
        }
        .font(JejakFont.p3)
        .monospacedDigit()
        .foregroundStyle(JejakColor.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(JejakColor.surface, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
