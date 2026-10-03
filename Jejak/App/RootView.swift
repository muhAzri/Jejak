import SwiftUI

struct RootView: View {
    @State private var isOnboardingCompleted = DIContainer.shared.resolve(GetOnboardingStatus.self)()

    var body: some View {
        if isOnboardingCompleted {
            CounterScreen()
        } else {
            OnboardingScreen { isOnboardingCompleted = true }
        }
    }
}

#Preview {
    RootView()
}
