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
        OnboardingPage(step: .intro, skipAction: viewModel.skipTapped) {
            SampleSessionCard()
                .padding(.bottom, 24)
            OnboardingHeading(title: "Every Step, Recorded",
                              message: "Record your runs and walks — distance, time and pace, right on your iPhone.")
        } actions: {
            Button("Continue", action: viewModel.nextTapped)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private struct SampleSessionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Distance")
                .font(JejakFont.p3Semibold)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("5.24")
                    .font(JejakFont.display(88))
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
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JejakColor.accent, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct PrivacyPage: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(step: .privacy, skipAction: viewModel.skipTapped) {
            ZStack {
                Circle().fill(JejakColor.accent)
                Image(heroicon: .shieldCheck)
                    .resizable().scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(JejakColor.accentInk)
            }
            .frame(width: 96, height: 96)
            .padding(.bottom, 24)
            .accessibilityHidden(true)

            OnboardingHeading(title: "Your Data Stays Here",
                              message: "Jejak has no server. Every session lives on your device.")

            VStack(spacing: 0) {
                PrivacyRow(icon: .user, text: "No account, no sign-up")
                Divider().padding(.leading, 50)
                PrivacyRow(icon: .signalSlash, text: "Works fully offline")
                Divider().padding(.leading, 50)
                PrivacyRow(icon: .lockClosed, text: "Stored only on this iPhone")
            }
            .background(JejakColor.surfaceTint, in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, 16)
        } actions: {
            Button("Continue", action: viewModel.nextTapped)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private struct PrivacyRow: View {
    let icon: HeroIcon
    let text: LocalizedStringKey

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
        .frame(minHeight: 56)
    }
}

private struct LocationPage: View {
    let viewModel: OnboardingViewModel
    let onFinish: () -> Void

    var body: some View {
        OnboardingPage(step: .location) {
            Image(heroicon: .mapPin)
                .resizable().scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(JejakColor.accent)
                .padding(.bottom, 16)
                .accessibilityHidden(true)

            OnboardingHeading(title: "Allow Location",
                              message: "Location is used to draw your route and measure distance. It never leaves your iPhone.")

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
            .padding(.top, 16)
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
}

#Preview {
    OnboardingScreen(onFinish: {})
}
