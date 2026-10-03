import SwiftUI

/// Shared page layout: optional top-trailing action, centered content, bottom actions.
struct OnboardingPage<Content: View, Actions: View>: View {
    let step: OnboardingStep
    var skipAction: (() -> Void)?
    @ViewBuilder var content: Content
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if let skipAction {
                    Button("Skip", action: skipAction)
                        .buttonStyle(TextActionButtonStyle())
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            VStack(spacing: 8) {
                PageIndicator(count: OnboardingStep.allCases.count, current: step.rawValue)
                    .padding(.bottom, 12)
                actions
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }
}

struct OnboardingHeading: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(JejakFont.display(32, relativeTo: .largeTitle))
            .foregroundStyle(JejakColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
        Text(message)
            .font(JejakFont.p1)
            .foregroundStyle(JejakColor.textSecondary)
    }
}
