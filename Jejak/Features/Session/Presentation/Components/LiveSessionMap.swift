import MapKit
import SwiftUI

/// The live map: follows the runner, draws the route so far and the current position.
struct LiveSessionMap: View {
    let route: [RoutePoint]
    let position: LocationSample?
    let signal: GPSSignal
    let phase: SessionPhase
    let tint: Color
    let isLocked: Bool

    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        let isPaused = phase == .paused
        Map(position: $camera, interactionModes: isLocked ? [] : [.zoom]) {
            RouteStrokesContent(strokes: RouteStrokes.make(route, coloring: .solid(isPaused ? JejakColor.paceSlow : tint)))
            if let first = route.first {
                Annotation("", coordinate: first.coordinate, anchor: .center) { RouteStartMarker() }
            }
            if let position, !isPaused, phase != .searching {
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude),
                           anchor: .center) {
                    PositionDot(isWeak: signal != .good)
                }
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .accessibilityHidden(true)
    }
}

/// Yellow dot with a soft halo; gray with a wide accuracy ring when the signal is weak.
private struct PositionDot: View {
    let isWeak: Bool

    var body: some View {
        ZStack {
            if isWeak {
                Circle()
                    .fill(JejakColor.accent.opacity(0.12))
                    .overlay(Circle().strokeBorder(JejakColor.accent.opacity(0.5), lineWidth: 1))
                    .frame(width: 68, height: 68)
            } else {
                Circle()
                    .fill(JejakColor.accent.opacity(0.25))
                    .frame(width: 42, height: 42)
            }
            Circle()
                .fill(Color(light: 0x262626, dark: 0x262626))
                .frame(width: 28, height: 28)
            Circle()
                .fill(isWeak ? JejakColor.paceSlow : JejakColor.accent)
                .frame(width: 22, height: 22)
        }
    }
}
