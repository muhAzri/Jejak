import SwiftUI
import UIKit

struct HomeScreen: View {
    @State private var viewModel: HomeViewModel
    @State private var isShowingSettings = false
    let onStartSession: (ActivityType) -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @MainActor
    init(viewModel: HomeViewModel? = nil,
         onStartSession: @escaping (ActivityType) -> Void) {
        _viewModel = State(initialValue: viewModel ?? DIContainer.shared.resolve(HomeViewModel.self))
        self.onStartSession = onStartSession
    }

    var body: some View {
        NavigationStack {
            // Measured edge to edge so the open Duo's panels split on the hinge; each layout pads
            // the horizontal and top safe area itself.
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
                .animation(.easeInOut(duration: 0.2), value: viewModel.notice)
            }
            .ignoresSafeArea(.container, edges: [.horizontal, .top])
            .background(JejakColor.surface.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsScreen()
            }
        }
        .onAppear(perform: viewModel.refresh)
        .task { await viewModel.observePermission() }
        .onChange(of: isShowingSettings) { _, isShowing in
            if !isShowing { viewModel.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refresh() }
        }
    }

    // MARK: Layouts

    /// iPhone: one scrolling column.
    private var regular: some View {
        ScrollView {
            VStack(spacing: 0) {
                header(titleSize: 32)
                    .padding(.top, 4)
                    .padding(.bottom, 20)

                notice(.regular)
                    .padding(.bottom, 12)

                VStack(spacing: 12) {
                    startCard(.run, layout: .regular)
                    startCard(.walk, layout: .regular)
                }

                if showsLastSession {
                    VStack(alignment: .leading, spacing: 12) {
                        lastSessionTitle
                        lastSession(.regular)
                    }
                    .padding(.top, 28)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    /// Duo closed: start tiles side by side; the last session takes the remaining height.
    private var compact: some View {
        VStack(spacing: 12) {
            header(titleSize: 28)
            notice(.compact)

            HStack(alignment: .top, spacing: 12) {
                startCard(.run, layout: .compact)
                startCard(.walk, layout: .compact)
            }
            .fixedSize(horizontal: false, vertical: true)

            if showsLastSession {
                VStack(alignment: .leading, spacing: 8) {
                    lastSessionTitle
                    lastSession(.compact)
                }
                .padding(.top, 4)
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    /// Duo open: start actions on the left, last session or the location problem on the right.
    /// Each panel is exactly half the screen; outer edges keep 32pt (or the safe-area inset), the fold side 24pt.
    private func split(_ proxy: GeometryProxy) -> some View {
        let half = proxy.size.width / 2
        let insets = proxy.safeAreaInsets
        return HStack(spacing: 0) {
            fittingPanel { stretches in
                VStack(spacing: 12) {
                    header(titleSize: 32)
                    // Without room to stretch, the cards keep their iPhone height and the panel scrolls.
                    startCard(.run, layout: stretches ? .split : .regular)
                    startCard(.walk, layout: stretches ? .split : .regular)
                }
                .padding(.bottom, 16)
                .frame(maxHeight: stretches ? .infinity : nil, alignment: .top)
            }
            .padding(.leading, ScreenLayout.splitOuterMargin(safeAreaInset: insets.leading))
            .padding(.trailing, 24)
            .frame(width: half)

            fittingPanel { stretches in
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.notice == .locationDenied {
                        LocationDeniedNotice(layout: .split, openSettings: openSystemSettings)
                    } else {
                        notice(.split)
                        lastSessionTitle
                        lastSession(.split, fillsHeight: stretches)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: stretches ? .infinity : nil, alignment: .topLeading)
            }
            .padding(.leading, 24)
            .padding(.trailing, ScreenLayout.splitOuterMargin(safeAreaInset: insets.trailing))
            .frame(width: half)
        }
    }

    /// Stretches the panel to the screen height when its content fits, otherwise lets it scroll
    /// so nothing is clipped (long notices, Indonesian copy, larger text sizes).
    private func fittingPanel<Content: View>(@ViewBuilder _ content: @escaping (_ stretches: Bool) -> Content) -> some View {
        ViewThatFits(in: .vertical) {
            content(true)
            ScrollView { content(false) }
                .scrollIndicators(.hidden)
        }
    }

    // MARK: Pieces

    private func header(titleSize: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(JejakFont.p2Semibold)
                    .foregroundStyle(JejakColor.textSecondary)
                Text(verbatim: "Jejak")
                    .font(JejakFont.display(titleSize, relativeTo: .largeTitle))
                    .foregroundStyle(JejakColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            Button { isShowingSettings = true } label: {
                Image(heroicon: .cog)
                    .resizable().scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(JejakColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(JejakColor.surfaceTint, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Settings"))
        }
    }

    @ViewBuilder
    private func notice(_ layout: ScreenLayout) -> some View {
        switch viewModel.notice {
        case .none:
            EmptyView()
        case .locationNotRequested:
            LocationNotRequestedNotice(isRequesting: viewModel.isRequestingPermission) {
                Task { await viewModel.requestPermission() }
            }
        case .locationDenied:
            LocationDeniedNotice(layout: layout, openSettings: openSystemSettings)
        case .locationAllowedOnce:
            LocationAllowedOnceNotice(openSettings: openSystemSettings, dismiss: viewModel.dismissOnceNotice)
        }
    }

    private func startCard(_ activity: ActivityType, layout: ScreenLayout) -> some View {
        StartActivityCard(activity: activity, layout: layout, isLocked: !viewModel.canStart) {
            Task {
                if await viewModel.prepareToStart() { onStartSession(activity) }
            }
        }
        .disabled(viewModel.isRequestingPermission)
    }

    private var lastSessionTitle: some View {
        Text("Last Session")
            .font(JejakFont.h2)
            .foregroundStyle(JejakColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    /// `fillsHeight`: the open Duo's route map and the closed Duo's empty card take the remaining height.
    @ViewBuilder
    private func lastSession(_ layout: ScreenLayout, fillsHeight: Bool = true) -> some View {
        if let session = viewModel.lastSession {
            if layout == .split {
                RoutePreview()
                    .frame(minHeight: 160, maxHeight: fillsHeight ? .infinity : 160)
            }
            LastSessionRow(session: session, unit: viewModel.unit, layout: layout)
        } else {
            EmptyLastSessionCard(fillsHeight: layout != .regular && fillsHeight)
        }
    }

    /// With a denied or allowed-once notice, the single-column layouts stay focused on the fix and drop
    /// "Last Session". The open Duo has room for both (see `split`), unless location is off.
    private var showsLastSession: Bool {
        viewModel.notice == .none || viewModel.notice == .locationNotRequested
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#if DEBUG
private struct PreviewSessions: SessionRepository {
    let session: SessionSummary?
    func latest() -> SessionSummary? { session }
}

private struct PreviewSettings: SettingsRepository {
    func distanceUnit() -> DistanceUnit { .kilometers }
    func setDistanceUnit(_ unit: DistanceUnit) {}
}

private struct PreviewPermission: LocationPermissionService {
    let permission: LocationPermission
    func current() -> LocationPermission { permission }
    func requestWhenInUse() async -> LocationPermission { permission }
    func updates() -> AsyncStream<LocationPermission> { AsyncStream { $0.yield(permission) } }
}

@MainActor
private func previewModel(_ permission: LocationPermission = .whenInUse, hasSession: Bool = false) -> HomeViewModel {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
    let session = SessionSummary(
        activity: .run,
        startDate: Calendar.current.date(bySettingHour: 6, minute: 12, second: 0, of: yesterday)!,
        distanceMeters: 5_240,
        duration: 28 * 60 + 41
    )
    let service = PreviewPermission(permission: permission)
    return HomeViewModel(
        getLastSession: GetLastSession(PreviewSessions(session: hasSession ? session : nil)),
        getDistanceUnit: GetDistanceUnit(PreviewSettings()),
        getLocationPermission: GetLocationPermission(service),
        observeLocationPermission: ObserveLocationPermission(service),
        requestLocationPermission: RequestLocationPermission(service)
    )
}

#Preview("Empty") {
    HomeScreen(viewModel: previewModel(), onStartSession: { _ in })
}

#Preview("Last session") {
    HomeScreen(viewModel: previewModel(hasSession: true), onStartSession: { _ in })
}

#Preview("Location not requested") {
    HomeScreen(viewModel: previewModel(.notDetermined), onStartSession: { _ in })
}

#Preview("Location denied") {
    HomeScreen(viewModel: previewModel(.denied), onStartSession: { _ in })
}

#Preview("Allowed once · dark") {
    HomeScreen(viewModel: previewModel(.allowedOnce, hasSession: true), onStartSession: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("iPhone Duo · closed", traits: .fixedLayout(width: 400, height: 566)) {
    HomeScreen(viewModel: previewModel(hasSession: true), onStartSession: { _ in })
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPhone Duo · open", traits: .fixedLayout(width: 800, height: 566)) {
    HomeScreen(viewModel: previewModel(.allowedOnce, hasSession: true), onStartSession: { _ in })
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("iPhone Duo · open · denied", traits: .fixedLayout(width: 800, height: 566)) {
    HomeScreen(viewModel: previewModel(.denied), onStartSession: { _ in })
        .environment(\.horizontalSizeClass, .regular)
}
#endif
