import SwiftUI

/// Shown over the finished session; it can't be swiped away, the user has to save or discard.
struct SessionSummaryScreen: View {
    let viewModel: ActiveSessionViewModel
    /// The presenting screen's layout: a sheet is smaller than the screen and would misread its own shape.
    let layout: ScreenLayout
    let onClose: () -> Void

    @State private var isConfirmingDiscard = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            Group {
                switch layout {
                case .regular: regular
                case .compact: compact
                case .split: split(proxy)
                }
            }
            .overlay { discardSheet(layout, proxy) }
            .animation(ScreenLayout.transition(reduceMotion: reduceMotion), value: layout)
            .animation(.easeInOut(duration: 0.2), value: isConfirmingDiscard)
        }
        .background(JejakColor.surface.ignoresSafeArea())
    }

    // MARK: Layouts

    private var regular: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header(titleSize: 32)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    map.frame(height: 220)
                    metrics(distanceSize: 64, valueSize: 24, spacing: 12)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 8) {
                saveButton
                discardButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private var compact: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(titleSize: 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
            map.frame(minHeight: 110, maxHeight: 150)
            metrics(distanceSize: 48, valueSize: 20, spacing: 8)
                .padding(.top, 12)
            Spacer(minLength: 12)
            HStack(spacing: 12) {
                discardButton
                saveButton
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Map on the left; title, metrics and decisions on the right, near the right thumb.
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
                header(titleSize: 32)
                metrics(distanceSize: 64, valueSize: 22, spacing: 16)
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    discardButton
                    saveButton
                }
            }
            .padding(.top, 16)
            .padding(.leading, 24)
            .padding(.trailing, ScreenLayout.splitOuterMargin(safeAreaInset: proxy.safeAreaInsets.trailing))
            .padding(.bottom, 24)
            .frame(width: half)
        }
    }

    // MARK: Pieces

    private func header(titleSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ActivityChip(activity: viewModel.activity, background: viewModel.activity.tint.opacity(0.12))
            Text(viewModel.activity.completedTitle)
                .font(JejakFont.display(titleSize, relativeTo: .largeTitle))
                .foregroundStyle(JejakColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let start = viewModel.startDate, let end = viewModel.endDate {
                Text(verbatim: "\(start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())) · \(start.formatted(.dateTime.hour().minute()))–\(end.formatted(.dateTime.hour().minute()))")
                    .font(JejakFont.p2)
                    .foregroundStyle(JejakColor.textSecondary)
            }
        }
    }

    private var map: some View {
        let extremes = RoutePace.extremes(viewModel.route)
        return StaticRouteMap(route: viewModel.route,
                              coloring: extremes == nil ? .solid(viewModel.activity.tint) : .pace)
            .background(JejakColor.fillInput)
            .overlay(alignment: .bottomLeading) {
                if let extremes {
                    PaceLegend(slowest: extremes.slowest, fastest: extremes.fastest, unit: viewModel.unit)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metrics(distanceSize: CGFloat, valueSize: CGFloat, spacing: CGFloat) -> some View {
        let unit = viewModel.unit
        return VStack(alignment: .leading, spacing: spacing) {
            DistanceMetric(meters: viewModel.distanceMeters, unit: unit, size: distanceSize)
            HStack(alignment: .top, spacing: 12) {
                MetricTile(title: "Time", value: SessionFormat.duration(viewModel.duration), size: valueSize)
                MetricTile(title: "Avg Pace", value: SessionFormat.pace(viewModel.averagePace, unit: unit), size: valueSize)
                MetricTile(title: "Best Pace", value: SessionFormat.pace(RoutePace.extremes(viewModel.route)?.fastest, unit: unit),
                           size: valueSize)
            }
        }
    }

    private var saveButton: some View {
        Button("Save") {
            viewModel.save()
            onClose()
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private var discardButton: some View {
        Button("Discard") { isConfirmingDiscard = true }
            .buttonStyle(.destructive)
    }

    @ViewBuilder
    private func discardSheet(_ layout: ScreenLayout, _ proxy: GeometryProxy) -> some View {
        if isConfirmingDiscard {
            let sheet = ConfirmSheet(title: "Discard This Session?",
                                     message: "The route and all metrics will be permanently deleted.",
                                     cancelTitle: "Cancel",
                                     confirmTitle: "Discard",
                                     onCancel: { isConfirmingDiscard = false },
                                     onConfirm: {
                                         viewModel.discard()
                                         onClose()
                                     })
            Group {
                if layout == .split {
                    HStack(spacing: 0) {
                        JejakColor.scrim.ignoresSafeArea()
                        sheet.padding(.trailing, proxy.safeAreaInsets.trailing)
                    }
                } else {
                    sheet
                }
            }
            .transition(.opacity)
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
