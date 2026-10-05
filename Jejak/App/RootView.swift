import SwiftUI

struct RootView: View {
    @State private var isOnboardingCompleted = DIContainer.shared.resolve(GetOnboardingStatus.self)()

    var body: some View {
        if isOnboardingCompleted {
            // TODO: open Active Session. Until it exists, Start only runs the location check.
            HomeScreen(onStartSession: { _ in })
        } else {
            OnboardingScreen { isOnboardingCompleted = true }
        }
    }
}

#Preview {
    RootView()
}
