import SwiftUI

/// Shown under "Last Session" before anything has been saved.
struct EmptyLastSessionCard: View {
    /// Closed and open Duo let the card take the remaining height.
    let fillsHeight: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(JejakColor.accent)
                Image(heroicon: .flag)
                    .resizable().scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(JejakColor.accentInk)
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            Text("No Sessions Yet")
                .font(JejakFont.h1)
                .foregroundStyle(JejakColor.textPrimary)
            Text("Your first session will show up here once saved.")
                .font(JejakFont.p2)
                .foregroundStyle(JejakColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, fillsHeight ? 16 : 28)
        .frame(maxWidth: .infinity, maxHeight: fillsHeight ? .infinity : nil)
        .background(JejakColor.surfaceTint, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

/// Summary row for the most recent session.
struct LastSessionRow: View {
    let session: SessionSummary
    let unit: DistanceUnit
    let layout: ScreenLayout

    var body: some View {
        HStack(spacing: 12) {
            // The open Duo shows the route large above the row instead of a thumbnail.
            if layout != .split {
                RoutePreview(session: session)
                    .frame(width: layout == .regular ? 72 : 64, height: layout == .regular ? 72 : 64)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    ActivityChip(activity: session.activity, background: session.activity.tint.opacity(0.12))
                    SessionDateText(date: session.startDate)
                        .font(JejakFont.p3)
                        .foregroundStyle(JejakColor.textSecondary)
                }
                if layout == .regular {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(verbatim: distance)
                            .font(JejakFont.display(20, relativeTo: .title2))
                        Text(verbatim: unit.symbol)
                            .font(JejakFont.p2)
                            .foregroundStyle(JejakColor.textSecondary)
                    }
                    Text(verbatim: details)
                        .font(JejakFont.p2)
                        .foregroundStyle(JejakColor.textSecondary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(verbatim: "\(distance) \(unit.symbol)")
                            .font(JejakFont.display(20, relativeTo: .title2))
                        Text(verbatim: details)
                            .font(JejakFont.p2)
                            .foregroundStyle(JejakColor.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(heroicon: .chevronRight)
                .resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
        }
        .foregroundStyle(JejakColor.textPrimary)
        .monospacedDigit()
        .padding(12)
        .background(JejakColor.surfaceTint, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var distance: String { SessionFormat.distance(session.distanceMeters, unit: unit) }

    private var details: String {
        "\(SessionFormat.duration(session.duration)) · \(SessionFormat.pace(session.pace, unit: unit)) /\(unit.symbol)"
    }
}

/// "Today · 06.12", "Yesterday · 6:12 AM", or the date for older sessions.
private struct SessionDateText: View {
    let date: Date

    var body: some View {
        let calendar = Calendar.current
        let time = date.formatted(.dateTime.hour().minute())
        if calendar.isDateInToday(date) {
            Text("Today · \(time)")
        } else if calendar.isDateInYesterday(date) {
            Text("Yesterday · \(time)")
        } else {
            Text(verbatim: "\(date.formatted(.dateTime.day().month(.abbreviated))) · \(time)")
        }
    }
}

/// The session's route on a small, static map; a plain tile when it has no route.
struct RoutePreview: View {
    let session: SessionSummary
    var cornerRadius: CGFloat = 8

    var body: some View {
        ZStack {
            JejakColor.fillInput
            if session.route.count > 1 {
                StaticRouteMap(route: session.route,
                               coloring: .solid(session.activity.tint),
                               showsMarkers: false,
                               lineWidth: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }
}
