import SwiftUI

/// Full-screen recording view, always dark. Folding or unfolding the Duo only changes the layout;
/// recording, pause and lock state live in the view model and carry over.
struct ActiveSessionScreen: View {
    @State private var viewModel: ActiveSessionViewModel
    /// The app's own appearance, for the summary sheet (this screen forces dark).
    let summaryColorScheme: ColorScheme
    /// Ends the session flow (cancel, save or discard).
    let onClose: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Layout of the whole screen; the summary sheet follows it rather than its own (smaller) size.
    @State private var screenLayout: ScreenLayout = .regular

    @MainActor
    init(activity: ActivityType,
         viewModel: ActiveSessionViewModel? = nil,
         summaryColorScheme: ColorScheme,
         onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel
            ?? DIContainer.shared.resolve(ActiveSessionViewModel.self, argument: activity))
        self.summaryColorScheme = summaryColorScheme
        self.onClose = onClose
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = ScreenLayout(horizontalSizeClass: horizontalSizeClass, size: proxy.size)
            Group {
                if layout == .split {
                    split(proxy)
                } else {
                    column(layout, proxy)
                }
            }
            .overlay { tooShortSheet(layout, proxy) }
            .animation(ScreenLayout.transition(reduceMotion: reduceMotion), value: layout)
            .onChange(of: layout, initial: true) { _, layout in screenLayout = layout }
        }
        .ignoresSafeArea(.container, edges: .horizontal)
        .background(JejakColor.canvas.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLocked)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isShowingTooShort)
        .preferredColorScheme(.dark)
        // As on Home: the closed Duo's status bar would cover the map chips.
        .statusBarHidden(screenLayout == .compact)
        .task { await viewModel.track() }
        .task { await viewModel.runClock() }
        .sensoryFeedback(trigger: viewModel.phase) { old, new in
            switch new {
            case .finished: .success
            case .paused, .recording where old != .searching: .impact(weight: .medium)
            default: nil
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.isLocked)
        .sheet(isPresented: .constant(viewModel.phase == .finished)) {
            SessionSummaryScreen(viewModel: viewModel, layout: screenLayout, onClose: onClose)
                .statusBarHidden(screenLayout == .compact)
                .preferredColorScheme(summaryColorScheme)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
        }
    }

    // MARK: Layouts

    /// iPhone and closed Duo: map on top, metrics, then controls at the bottom.
    private func column(_ layout: ScreenLayout, _ proxy: GeometryProxy) -> some View {
        let isCompact = layout == .compact
        let insets = proxy.safeAreaInsets
        let mapHeight = isCompact ? 200 : min(330, proxy.size.height * 0.39)
        return VStack(spacing: 0) {
            mapArea(chipsTop: chipsTop(layout, insets), fadesIntoCanvas: true, pillBottom: isCompact ? 20 : 24)
                .frame(height: mapHeight)

            metrics(distanceSize: isCompact ? 64 : 88, valueSize: isCompact ? 22 : 24,
                    showsPaceNote: !isCompact, spacing: isCompact ? 12 : 16)
                .padding(.horizontal, 24)
                .padding(.top, isCompact ? 12 : 8)

            Spacer(minLength: 12)

            bottomArea(isCompact: isCompact)
                .padding(.horizontal, viewModel.phase == .searching ? (isCompact ? 24 : 16) : (viewModel.isLocked ? 24 : (isCompact ? 24 : 32)))
                .padding(.bottom, 8)
        }
        .padding(.leading, insets.leading)
        .padding(.trailing, insets.trailing)
    }

    /// Open Duo: the map fills the left panel; metrics and controls sit in the right one.
    private func split(_ proxy: GeometryProxy) -> some View {
        let half = proxy.size.width / 2
        let insets = proxy.safeAreaInsets
        return HStack(spacing: 0) {
            mapArea(chipsTop: chipsTop(.split, insets), fadesIntoCanvas: false, pillBottom: 20)
                .ignoresSafeArea(.container, edges: .bottom)
                .frame(width: half)

            VStack(alignment: .leading, spacing: 16) {
                metrics(distanceSize: 88, valueSize: 24, showsPaceNote: false, spacing: 16)
                Spacer(minLength: 0)
                bottomArea(isCompact: false)
            }
            .padding(.top, ScreenLayout.split.topMargin(safeAreaTop: insets.top) + 8)
            .padding(.bottom, 16)
            .padding(.leading, 32)
            .padding(.trailing, ScreenLayout.splitOuterMargin(safeAreaInset: insets.trailing))
            .frame(width: half)
        }
        .overlay {
            // The hinge.
            Rectangle().fill(JejakColor.border).frame(width: 2).ignoresSafeArea()
        }
    }

    // MARK: Pieces

    /// The map starts below the status bar; on the Duo (status bar often hidden) the chips also keep
    /// clear of the rounded corners.
    private func chipsTop(_ layout: ScreenLayout, _ insets: EdgeInsets) -> CGFloat {
        layout == .regular ? 12 : max(12, 24 - insets.top)
    }

    private func mapArea(chipsTop: CGFloat, fadesIntoCanvas: Bool, pillBottom: CGFloat) -> some View {
        ZStack {
            LiveSessionMap(route: viewModel.route,
                           position: viewModel.position,
                           signal: viewModel.signal,
                           phase: viewModel.phase,
                           tint: viewModel.activity.tint,
                           isLocked: viewModel.isLocked)
                .background(JejakColor.fillInput)

            if viewModel.phase == .searching {
                Color.black.opacity(0.45).allowsHitTesting(false)
            }
            if fadesIntoCanvas {
                LinearGradient(colors: [JejakColor.canvas.opacity(0), JejakColor.canvas], startPoint: .top, endPoint: .bottom)
                    .frame(height: 56)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
            }
            SessionChips(activity: viewModel.activity,
                         signal: viewModel.signal,
                         phase: viewModel.phase,
                         isLocked: viewModel.isLocked)
                .padding(.top, chipsTop)
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity, alignment: .top)
            if viewModel.phase == .paused {
                PausedPill(pausedFor: viewModel.pausedDuration)
                    .padding(.bottom, pillBottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func metrics(distanceSize: CGFloat, valueSize: CGFloat, showsPaceNote: Bool, spacing: CGFloat) -> some View {
        let unit = viewModel.unit
        if viewModel.phase == .searching {
            DistanceMetric(meters: 0, unit: unit, size: distanceSize)
                .opacity(0.4)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            let isDimmed = viewModel.phase == .paused
            VStack(alignment: .leading, spacing: spacing) {
                DistanceMetric(meters: viewModel.distanceMeters, unit: unit, size: distanceSize, isDimmed: isDimmed)
                HStack(alignment: .top, spacing: 12) {
                    MetricTile(title: "Time", value: SessionFormat.duration(viewModel.duration), size: valueSize, isDimmed: isDimmed)
                    MetricTile(title: "Current Pace", value: SessionFormat.pace(viewModel.currentPace, unit: unit),
                               size: valueSize, isDimmed: isDimmed || viewModel.signal == .weak)
                    MetricTile(title: "Avg Pace", value: SessionFormat.pace(viewModel.averagePace, unit: unit),
                               size: valueSize, isDimmed: isDimmed)
                }
                if viewModel.signal == .weak && viewModel.phase == .recording {
                    Text("Route is estimated for now (dotted line). Current pace is hidden until the signal recovers.")
                        .font(JejakFont.p3)
                        .foregroundStyle(JejakColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, -4)
                } else if showsPaceNote && !isDimmed {
                    Text("Pace in minutes /\(unit.symbol)")
                        .font(JejakFont.p3)
                        .foregroundStyle(JejakColor.textSecondary)
                        .padding(.top, -10)
                }
            }
        }
    }

    @ViewBuilder
    private func bottomArea(isCompact: Bool) -> some View {
        if viewModel.phase == .searching {
            GPSSearchCard(onCancel: cancel, onStartAnyway: viewModel.startRecording)
        } else if viewModel.isLocked {
            HoldToUnlockBar(isCompact: isCompact, onUnlock: viewModel.unlock)
        } else {
            SessionControls(isPaused: viewModel.phase == .paused,
                            isCompact: isCompact,
                            onLock: viewModel.lock,
                            onPauseResume: { viewModel.phase == .paused ? viewModel.resume() : viewModel.pause() },
                            onFinish: viewModel.finish)
        }
    }

    /// Sessions under 100 m or a minute: keep recording or throw away. On the open Duo the sheet stays
    /// in the right panel and the map panel is dimmed.
    @ViewBuilder
    private func tooShortSheet(_ layout: ScreenLayout, _ proxy: GeometryProxy) -> some View {
        if viewModel.isShowingTooShort {
            let sheet = ConfirmSheet(title: "Session Too Short",
                                     message: "Sessions under 100 m or 1 minute can't be saved. Keep going or discard?",
                                     cancelTitle: "Keep Going",
                                     confirmTitle: "Discard",
                                     onCancel: viewModel.keepGoing,
                                     onConfirm: cancel)
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

    private func cancel() {
        viewModel.discard()
        onClose()
    }
}

#if DEBUG
private struct PreviewTracking: LocationTrackingService {
    func start() -> AsyncStream<LocationSample> { AsyncStream { _ in } }
    func stop() {}
}

private struct PreviewSettings: SettingsRepository {
    func distanceUnit() -> DistanceUnit { .kilometers }
    func setDistanceUnit(_ unit: DistanceUnit) {}
}

private struct PreviewSessions: SessionRepository {
    func latest() -> SessionSummary? { nil }
    func save(_ session: SessionSummary) {}
    func saveRawTrack(_ track: [RecordedFix], id: UUID) {}
    func rawTrack(id: UUID) -> [RecordedFix] { [] }
    func delete(id: UUID) {}
}

/// A model that has recorded a few minutes along a straight line.
@MainActor
private func previewModel(recording: Bool = true) -> ActiveSessionViewModel {
    let start = Date.now.addingTimeInterval(-1062)
    var time = start
    let model = ActiveSessionViewModel(activity: .run,
                                       getDistanceUnit: GetDistanceUnit(PreviewSettings()),
                                       trackLocation: TrackLocation(PreviewTracking()),
                                       saveSession: SaveSession(PreviewSessions()),
                                       clock: { time })
    guard recording else { return model }
    for step in 0...300 {
        time = start.addingTimeInterval(Double(step) * 3.5)
        model.receive(LocationSample(latitude: -6.2 + Double(step) * 0.00009,
                                     longitude: 106.82 + sin(Double(step) / 40) * 0.002,
                                     horizontalAccuracy: 8, timestamp: time))
    }
    return model
}

#Preview("Recording") {
    ActiveSessionScreen(activity: .run, viewModel: previewModel(), summaryColorScheme: .light, onClose: {})
}

#Preview("Searching") {
    ActiveSessionScreen(activity: .walk, viewModel: previewModel(recording: false), summaryColorScheme: .light, onClose: {})
}

#Preview("iPhone Duo · closed", traits: .fixedLayout(width: 400, height: 566)) {
    ActiveSessionScreen(activity: .run, viewModel: previewModel(), summaryColorScheme: .light, onClose: {})
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPhone Duo · open", traits: .fixedLayout(width: 800, height: 566)) {
    ActiveSessionScreen(activity: .run, viewModel: previewModel(), summaryColorScheme: .light, onClose: {})
        .environment(\.horizontalSizeClass, .regular)
}
#endif
