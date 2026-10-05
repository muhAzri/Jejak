import SwiftUI

/// Onboarding layout per screen shape, from the iPhone Duo design.
enum OnboardingLayout {
    /// Standard iPhone: single column.
    case regular
    /// Duo closed (outer screen, ~566pt tall): single column with tighter sizing.
    case compact
    /// Duo open (inner screen): visual in the left panel, text and actions in the right panel.
    case split

    init(horizontalSizeClass: UserInterfaceSizeClass?, size: CGSize) {
        if horizontalSizeClass == .regular && size.width > size.height {
            self = .split
        } else if size.height < 600 {
            self = .compact
        } else {
            self = .regular
        }
    }

    var titleSize: CGFloat { self == .compact ? 24 : 32 }
}

/// Shared page layout: optional top-trailing action, centered content, bottom actions.
/// In `.split` the visual moves to the left panel; everything else stays on the right, clear of the fold.
struct OnboardingPage<Visual: View, Content: View, Actions: View>: View {
    let step: OnboardingStep
    var skipAction: (() -> Void)?
    @ViewBuilder var visual: (OnboardingLayout) -> Visual
    @ViewBuilder var content: (OnboardingLayout) -> Content
    @ViewBuilder var actions: Actions

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let layout = OnboardingLayout(horizontalSizeClass: horizontalSizeClass, size: proxy.size)
            Group {
                if layout == .split {
                    split(panelWidth: proxy.size.width / 2)
                } else {
                    stacked(layout)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .timingCurve(0.2, 0, 0, 1, duration: 0.5),
                       value: layout)
        }
    }

    private func stacked(_ layout: OnboardingLayout) -> some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                visual(layout)
                content(layout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            footer
                .padding(.horizontal, 24)
        }
    }

    private func split(panelWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            visual(.split)
                .frame(width: panelWidth)
                .frame(maxHeight: .infinity)
                .padding(.bottom, 24)

            VStack(spacing: 0) {
                topBar

                VStack(alignment: .leading, spacing: 8) {
                    content(.split)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                footer
            }
            .padding(.leading, 40)
            .padding(.trailing, 32)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            if let skipAction {
                Button("Skip", action: skipAction)
                    .buttonStyle(TextActionButtonStyle())
            }
        }
        .frame(minHeight: 44)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            PageIndicator(count: OnboardingStep.allCases.count, current: step.rawValue)
                .padding(.bottom, 8)
            actions
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct OnboardingHeading: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let layout: OnboardingLayout

    var body: some View {
        Text(title)
            .font(JejakFont.display(layout.titleSize, relativeTo: .largeTitle))
            .foregroundStyle(JejakColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
        Text(message)
            .font(JejakFont.p1)
            .foregroundStyle(JejakColor.textSecondary)
    }
}
