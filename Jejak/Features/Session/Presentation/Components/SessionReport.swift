import SwiftUI

/// Activity chip, "Run Complete" and the start–end time; shared by the summary and a saved session's detail.
struct SessionHeading: View {
    let activity: ActivityType
    let startDate: Date?
    let endDate: Date?
    let titleSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActivityChip(activity: activity, background: activity.tint.opacity(0.12))
            Text(activity.completedTitle)
                .font(JejakFont.display(titleSize, relativeTo: .largeTitle))
                .foregroundStyle(JejakColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let startDate, let endDate {
                Text(verbatim: "\(startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())) · \(startDate.formatted(.dateTime.hour().minute()))–\(endDate.formatted(.dateTime.hour().minute()))")
                    .font(JejakFont.p2)
                    .foregroundStyle(JejakColor.textSecondary)
            }
        }
    }
}

/// The route colored by pace, with its legend; a solid line when pace can't be told apart.
struct SessionRouteMap: View {
    let route: [RoutePoint]
    let activity: ActivityType
    let unit: DistanceUnit

    var body: some View {
        let extremes = RoutePace.extremes(route)
        StaticRouteMap(route: route, coloring: extremes == nil ? .solid(activity.tint) : .pace)
            .background(JejakColor.fillInput)
            .overlay(alignment: .bottomLeading) {
                if let extremes {
                    PaceLegend(slowest: extremes.slowest, fastest: extremes.fastest, unit: unit)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Distance, then time, average pace and best pace.
struct SessionMetrics: View {
    let distanceMeters: Double
    let duration: TimeInterval
    let averagePace: Double?
    let route: [RoutePoint]
    let unit: DistanceUnit
    let distanceSize: CGFloat
    let valueSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            DistanceMetric(meters: distanceMeters, unit: unit, size: distanceSize)
            HStack(alignment: .top, spacing: 12) {
                MetricTile(title: "Time", value: SessionFormat.duration(duration), size: valueSize)
                MetricTile(title: "Avg Pace", value: SessionFormat.pace(averagePace, unit: unit), size: valueSize)
                MetricTile(title: "Best Pace", value: SessionFormat.pace(RoutePace.extremes(route)?.fastest, unit: unit),
                           size: valueSize)
            }
        }
    }
}

extension ActivityType {
    var completedTitle: LocalizedStringKey {
        switch self {
        case .run: "Run Complete"
        case .walk: "Walk Complete"
        }
    }
}
