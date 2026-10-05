import SwiftUI
import UIKit

struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @MainActor
    init(viewModel: SettingsViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? DIContainer.shared.resolve(SettingsViewModel.self))
    }

    var body: some View {
        // Measured edge to edge horizontally so the open Duo's columns split on the hinge; the horizontal
        // safe area is padded explicitly. The top safe area is kept so the header clears the status bar.
        GeometryReader { proxy in
            let layout = ScreenLayout(horizontalSizeClass: horizontalSizeClass, size: proxy.size)
            let insets = proxy.safeAreaInsets
            VStack(spacing: 0) {
                header(layout)
                    .padding(.top, layout.topMargin(safeAreaTop: insets.top))
                    .padding(.leading, insets.leading)
                    .padding(.trailing, insets.trailing)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(JejakColor.border).frame(height: 1)
                    }

                Group {
                    if layout == .split {
                        // Each column is exactly half the screen; rows sit 32pt from the fold on both sides.
                        HStack(alignment: .top, spacing: 0) {
                            ScrollView {
                                VStack(spacing: 0) {
                                    unitsSection(layout)
                                    SectionDivider().padding(.leading, 16)
                                    generalSection(layout)
                                }
                                .padding(.trailing, 16)
                            }
                            .padding(.leading, insets.leading)
                            .frame(width: proxy.size.width / 2)

                            ScrollView {
                                aboutSection(layout)
                                    .padding(.leading, 16)
                            }
                            .padding(.trailing, insets.trailing)
                            .frame(width: proxy.size.width / 2)
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                unitsSection(layout)
                                SectionDivider()
                                generalSection(layout)
                                if layout != .compact { SectionDivider() }
                                aboutSection(layout)
                            }
                        }
                        .padding(.leading, insets.leading)
                        .padding(.trailing, insets.trailing)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .animation(ScreenLayout.transition(reduceMotion: reduceMotion), value: layout)
        }
        .ignoresSafeArea(.container, edges: .horizontal)
        .background(JejakColor.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.observePermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refresh() }
        }
    }

    /// Back is a filled circle like Home's settings button. On the open Duo the screen is held wide and
    /// the top-left corner is far from the thumb, so the button and title grow.
    private func header(_ layout: ScreenLayout) -> some View {
        let isSplit = layout == .split
        let buttonSize: CGFloat = isSplit ? 52 : 44
        return HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(heroicon: .chevronLeft)
                    .resizable().scaledToFit()
                    .frame(width: isSplit ? 26 : 22, height: isSplit ? 26 : 22)
                    .foregroundStyle(JejakColor.textPrimary)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(JejakColor.surfaceTint, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Back"))

            Text("Settings")
                .font(isSplit ? JejakFont.display(24, relativeTo: .title) : JejakFont.h1)
                .foregroundStyle(JejakColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isSplit ? 10 : 6)
    }

    private func unitsSection(_ layout: ScreenLayout) -> some View {
        VStack(spacing: 0) {
            SectionTitle("Distance Units", layout: layout)
            RadioRow(title: "Kilometers (km)", isSelected: viewModel.unit == .kilometers) {
                viewModel.select(.kilometers)
            }
            RadioRow(title: "Miles (mi)", isSelected: viewModel.unit == .miles) {
                viewModel.select(.miles)
            }
        }
        .padding(.bottom, layout == .regular ? 8 : 4)
    }

    /// Language and location are owned by iOS, so both rows open the app's page in Settings
    /// (location asks in-app first if it never has).
    private func generalSection(_ layout: ScreenLayout) -> some View {
        VStack(spacing: 0) {
            SectionTitle("General", layout: layout)
            SettingsRow(icon: .language, title: "Language", value: Text(viewModel.languageName),
                        layout: layout, action: openSystemSettings)
            SettingsRow(icon: .mapPin, title: "Location Access", value: Text(viewModel.locationPermission.settingsLabel),
                        layout: layout, action: locationRowTapped)
        }
        .padding(.bottom, layout == .regular ? 8 : 4)
    }

    private func aboutSection(_ layout: ScreenLayout) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // The closed Duo screen folds Version into General to keep everything on one screen.
            if layout != .compact {
                SectionTitle("About", layout: layout)
            }
            SettingsRow(icon: .informationCircle, title: "Version", value: Text(verbatim: viewModel.version),
                        layout: layout, action: nil)
            Text("All data is stored on this iPhone. Deleting the app deletes every session.")
                .font(JejakFont.p3)
                .foregroundStyle(JejakColor.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    private func locationRowTapped() {
        if viewModel.locationRowRequestsPermission {
            Task { await viewModel.requestPermission() }
        } else {
            openSystemSettings()
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private struct SectionTitle: View {
    let title: LocalizedStringKey
    let layout: ScreenLayout

    init(_ title: LocalizedStringKey, layout: ScreenLayout) {
        self.title = title
        self.layout = layout
    }

    var body: some View {
        Text(title)
            .font(JejakFont.h2)
            .foregroundStyle(JejakColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, layout == .regular ? 16 : 12)
            .padding(.bottom, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(JejakColor.fillInput)
            .frame(height: 5)
    }
}

private struct SettingsRow: View {
    let icon: HeroIcon
    let title: LocalizedStringKey
    let value: Text
    let layout: ScreenLayout
    let action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { content(showsChevron: true) }
                .buttonStyle(.plain)
        } else {
            content(showsChevron: false)
                .accessibilityElement(children: .combine)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(heroicon: icon)
                .resizable().scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(JejakFont.p1)
                .frame(maxWidth: .infinity, alignment: .leading)
            value
                .font(JejakFont.p2)
                .foregroundStyle(JejakColor.textSecondary)
            if showsChevron {
                Image(heroicon: .chevronRight)
                    .resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(JejakColor.textPrimary)
        .padding(.horizontal, 16)
        .frame(minHeight: layout == .regular ? 56 : 52)
        .contentShape(Rectangle())
    }
}

private extension LocationPermission {
    var settingsLabel: LocalizedStringKey {
        switch self {
        case .whenInUse: "While Using"
        case .always: "Always"
        case .allowedOnce: "Once"
        case .denied: "Off"
        case .notDetermined: "Not Set"
        }
    }
}

#if DEBUG
private final class PreviewSettings: SettingsRepository {
    private var unit = DistanceUnit.kilometers
    func distanceUnit() -> DistanceUnit { unit }
    func setDistanceUnit(_ unit: DistanceUnit) { self.unit = unit }
}

private struct PreviewPermission: LocationPermissionService {
    func current() -> LocationPermission { .whenInUse }
    func requestWhenInUse() async -> LocationPermission { .whenInUse }
    func updates() -> AsyncStream<LocationPermission> { AsyncStream { $0.yield(.whenInUse) } }
}

@MainActor
private func previewModel() -> SettingsViewModel {
    let settings = PreviewSettings()
    return SettingsViewModel(getDistanceUnit: GetDistanceUnit(settings),
                             setDistanceUnit: SetDistanceUnit(settings),
                             getLocationPermission: GetLocationPermission(PreviewPermission()),
                             observeLocationPermission: ObserveLocationPermission(PreviewPermission()),
                             requestLocationPermission: RequestLocationPermission(PreviewPermission()))
}

#Preview {
    SettingsScreen(viewModel: previewModel())
}

#Preview("Dark") {
    SettingsScreen(viewModel: previewModel())
        .preferredColorScheme(.dark)
}

#Preview("iPhone Duo · closed", traits: .fixedLayout(width: 400, height: 566)) {
    SettingsScreen(viewModel: previewModel())
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPhone Duo · open", traits: .fixedLayout(width: 800, height: 566)) {
    SettingsScreen(viewModel: previewModel())
        .environment(\.horizontalSizeClass, .regular)
}
#endif
