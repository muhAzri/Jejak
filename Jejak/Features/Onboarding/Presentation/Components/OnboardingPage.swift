import SwiftUI

extension ScreenLayout {
    var titleSize: CGFloat { self == .compact ? 24 : 32 }
}

/// Shared page layout: optional top-trailing action, centered content, bottom actions.
/// In `.split` the visual moves to the left panel; everything else stays on the right, clear of the fold.
struct OnboardingPage<Visual: View, Content: View, Actions: View>: View {
    let step: OnboardingStep
    var skipAction: (() -> Void)?
    @ViewBuilder var visual: (ScreenLayout) -> Visual
    @ViewBuilder var content: (ScreenLayout) -> Content
    @ViewBuilder var actions: Actions

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let layout = ScreenLayout(horizontalSizeClass: horizontalSizeClass, size: proxy.size)
            Group {
                if layout == .split {
                    split(panelWidth: proxy.size.width / 2)
                } else {
                    stacked(layout)
                }
            }
            .animation(ScreenLayout.transition(reduceMotion: reduceMotion), value: layout)
        }
    }

    private func stacked(_ layout: ScreenLayout) -> some View {
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
    let layout: ScreenLayout

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
