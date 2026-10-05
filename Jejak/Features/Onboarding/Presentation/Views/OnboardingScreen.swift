import SwiftUI

struct OnboardingScreen: View {
    @State private var viewModel = DIContainer.shared.resolve(OnboardingViewModel.self)
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            switch viewModel.step {
            case .intro:
                IntroPage(viewModel: viewModel)
            case .privacy:
                PrivacyPage(viewModel: viewModel)
            case .location:
                LocationPage(viewModel: viewModel, onFinish: onFinish)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.28), value: viewModel.step)
        .background(JejakColor.surface.ignoresSafeArea())
    }
}

private struct IntroPage: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(step: .intro, skipAction: viewModel.skipTapped) { layout in
            SampleSessionCard(layout: layout)
                .padding(.bottom, layout == .compact ? 12 : 24)
                .padding(.horizontal, layout == .split ? 40 : 0)
        } content: { layout in
            OnboardingHeading(title: "Every Step, Recorded",
                              message: "Record your runs and walks — distance, time and pace, right on your iPhone.",
                              layout: layout)
        } actions: {
            Button("Continue", action: viewModel.nextTapped)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private struct SampleSessionCard: View {
    let layout: ScreenLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Distance")
                .font(JejakFont.p3Semibold)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("5.24")
                    .font(JejakFont.display(layout == .compact ? 56 : 88))
                Text("km")
                    .font(JejakFont.h2)
            }
            HStack(spacing: 24) {
                Text("28:41")
                Text("5:28 /km")
            }
            .font(JejakFont.p1Semibold)
        }
        .monospacedDigit()
        .foregroundStyle(JejakColor.accentInk)
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JejakColor.accent, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var cardPadding: CGFloat {
        switch layout {
        case .regular: 24
        case .compact: 20
        case .split: 28
        }
    }
}

private struct PrivacyPage: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(step: .privacy, skipAction: viewModel.skipTapped) { layout in
            // The closed Duo screen is too short for the badge; the list carries the message.
            if layout != .compact {
                let size: CGFloat = layout == .split ? 160 : 96
                ZStack {
                    Circle().fill(JejakColor.accent)
                    Image(heroicon: .shieldCheck)
                        .resizable().scaledToFit()
                        .frame(width: size / 2, height: size / 2)
                        .foregroundStyle(JejakColor.accentInk)
                }
                .frame(width: size, height: size)
                .padding(.bottom, layout == .split ? 0 : 24)
                .accessibilityHidden(true)
            }
        } content: { layout in
            OnboardingHeading(title: "Your Data Stays Here",
                              message: "Jejak has no server. Every session lives on your device.",
                              layout: layout)

            VStack(spacing: 0) {
                PrivacyRow(icon: .user, text: "No account, no sign-up", layout: layout)
                Divider().padding(.leading, 50)
                PrivacyRow(icon: .signalSlash, text: "Works fully offline", layout: layout)
                Divider().padding(.leading, 50)
                PrivacyRow(icon: .lockClosed, text: "Stored only on this iPhone", layout: layout)
            }
            .background(JejakColor.surfaceTint, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, layout.detailSpacing)
        } actions: {
            Button("Continue", action: viewModel.nextTapped)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private struct PrivacyRow: View {
    let icon: HeroIcon
    let text: LocalizedStringKey
    let layout: ScreenLayout

    var body: some View {
        HStack(spacing: 12) {
            Image(heroicon: icon)
                .resizable().scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(JejakFont.p1Semibold)
            Spacer(minLength: 0)
        }
        .foregroundStyle(JejakColor.textPrimary)
        .padding(.horizontal, 16)
        .frame(minHeight: rowHeight)
    }

    private var rowHeight: CGFloat {
        switch layout {
        case .regular: 56
        case .compact: 44
        case .split: 48
        }
    }
}

private struct LocationPage: View {
    let viewModel: OnboardingViewModel
    let onFinish: () -> Void

    var body: some View {
        OnboardingPage(step: .location) { layout in
            Image(heroicon: .mapPin)
                .resizable().scaledToFit()
                .frame(width: pinSize(layout), height: pinSize(layout))
                .foregroundStyle(JejakColor.accent)
                .padding(.bottom, layout == .split ? 0 : layout == .compact ? 4 : 16)
                .accessibilityHidden(true)
        } content: { layout in
            OnboardingHeading(title: "Allow Location",
                              message: "Location is used to draw your route and measure distance. It never leaves your iPhone.",
                              layout: layout)

            HStack(alignment: .top, spacing: 10) {
                Image(heroicon: .informationCircle)
                    .resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
                Text("Choose “While Using the App” in the next dialog.")
                    .font(JejakFont.p2Semibold)
            }
            .foregroundStyle(JejakColor.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(JejakColor.accentBackground, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, layout.detailSpacing)
        } actions: {
            Button("Allow Location") {
                Task {
                    await viewModel.allowLocationTapped()
                    onFinish()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isRequestingPermission)

            Button("Not Now") {
                viewModel.laterTapped()
                onFinish()
            }
            .buttonStyle(TextActionButtonStyle())
        }
    }

    private func pinSize(_ layout: ScreenLayout) -> CGFloat {
        switch layout {
        case .regular: 120
        case .compact: 80
        case .split: 220
        }
    }
}

private extension ScreenLayout {
    /// Gap above the card that follows the heading.
    var detailSpacing: CGFloat {
        switch self {
        case .regular: 16
        case .compact: 8
        case .split: 12
        }
    }
}

#Preview {
    OnboardingScreen(onFinish: {})
}

#Preview("iPhone Duo · closed", traits: .fixedLayout(width: 400, height: 566)) {
    OnboardingScreen(onFinish: {})
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPhone Duo · open", traits: .fixedLayout(width: 800, height: 566)) {
    OnboardingScreen(onFinish: {})
        .environment(\.horizontalSizeClass, .regular)
}
