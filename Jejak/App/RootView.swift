import SwiftUI

struct RootView: View {
    @State private var isOnboardingCompleted = DIContainer.shared.resolve(GetOnboardingStatus.self)()
    @State private var screenSize: CGSize = .zero
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if isOnboardingCompleted {
                HomeScreen()
            } else {
                OnboardingScreen { isOnboardingCompleted = true }
            }
        }
        // Measures the whole screen without affecting the content's safe area.
        .background {
            GeometryReader { proxy in
                Color.clear.onChange(of: proxy.size, initial: true) { _, size in screenSize = size }
            }
            .ignoresSafeArea()
        }
        // The closed Duo's status bar covers the start tiles; hidden here so it applies to every screen,
        // including ones pushed on a NavigationStack.
        .statusBarHidden(isFolded)
    }

    private var isFolded: Bool {
        screenSize != .zero && ScreenLayout(horizontalSizeClass: horizontalSizeClass, size: screenSize) == .compact
    }
}

#Preview {
    RootView()
}
