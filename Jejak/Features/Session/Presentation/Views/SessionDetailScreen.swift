import SwiftUI

/// A saved session, opened from Home's "Last Session": the summary's route and metrics, read-only.
struct SessionDetailScreen: View {
    let session: SessionSummary
    let unit: DistanceUnit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Measured edge to edge horizontally so the open Duo's panels split on the hinge; the top safe area
        // is kept so the back button clears the status bar.
        GeometryReader { proxy in
            let layout = ScreenLayout(horizontalSizeClass: horizontalSizeClass, size: proxy.size)
            let insets = proxy.safeAreaInsets
            Group {
                switch layout {
                case .regular: regular.padding(.leading, insets.leading).padding(.trailing, insets.trailing)
                case .compact: compact.padding(.leading, insets.leading).padding(.trailing, insets.trailing)
                case .split: split(proxy)
                }
            }
            .padding(.top, layout.topMargin(safeAreaTop: insets.top))
            .animation(ScreenLayout.transition(reduceMotion: reduceMotion), value: layout)
        }
        .ignoresSafeArea(.container, edges: .horizontal)
        .background(JejakColor.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Layouts

    private var regular: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                backButton(size: 44)
                    .padding(.top, 6)
                SessionHeading(activity: session.activity, startDate: session.startDate, endDate: session.endDate,
                               titleSize: 32)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                map.frame(height: 220)
                metrics(distanceSize: 64, valueSize: 24, spacing: 12)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var compact: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                backButton(size: 44)
                SessionHeading(activity: session.activity, startDate: session.startDate, endDate: session.endDate,
                               titleSize: 24)
            }
            .padding(.bottom, 8)
            map.frame(minHeight: 110, maxHeight: .infinity)
            metrics(distanceSize: 48, valueSize: 20, spacing: 8)
                .padding(.top, 12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Route on the left; back, title and metrics on the right, like the summary.
    private func split(_ proxy: GeometryProxy) -> some View {
        let half = proxy.size.width / 2
        return HStack(spacing: 0) {
            map
                .padding(.leading, max(16, proxy.safeAreaInsets.leading))
                .padding(.trailing, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .frame(width: half)
            VStack(alignment: .leading, spacing: 16) {
                backButton(size: 52)
                SessionHeading(activity: session.activity, startDate: session.startDate, endDate: session.endDate,
                               titleSize: 32)
                metrics(distanceSize: 64, valueSize: 22, spacing: 16)
                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .padding(.leading, 24)
            .padding(.trailing, ScreenLayout.splitOuterMargin(safeAreaInset: proxy.safeAreaInsets.trailing))
            .padding(.bottom, 24)
            .frame(width: half)
        }
    }

    // MARK: Pieces

    /// Same filled circle as Settings' back button.
    private func backButton(size: CGFloat) -> some View {
        Button { dismiss() } label: {
            Image(heroicon: .chevronLeft)
                .resizable().scaledToFit()
                .frame(width: size > 44 ? 26 : 22, height: size > 44 ? 26 : 22)
                .foregroundStyle(JejakColor.textPrimary)
                .frame(width: size, height: size)
                .background(JejakColor.surfaceTint, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Back"))
    }

    private var map: some View {
        SessionRouteMap(route: session.route, activity: session.activity, unit: unit)
    }

    private func metrics(distanceSize: CGFloat, valueSize: CGFloat, spacing: CGFloat) -> some View {
        SessionMetrics(distanceMeters: session.distanceMeters, duration: session.duration, averagePace: session.pace,
                       route: session.route, unit: unit,
                       distanceSize: distanceSize, valueSize: valueSize, spacing: spacing)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SessionDetailScreen(
            session: SessionSummary(activity: .run, startDate: .now.addingTimeInterval(-3_600),
                                    distanceMeters: 5_240, duration: 28 * 60 + 41),
            unit: .kilometers
        )
    }
}
#endif
