import SwiftUI

struct CounterScreen: View {
    @State private var viewModel = DIContainer.shared.resolve(CounterViewModel.self)

    var body: some View {
        VStack(spacing: 16) {
            Text("\(viewModel.counter.value)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
            Button("Increment", action: viewModel.incrementTapped)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { viewModel.load() }
    }
}

#Preview {
    CounterScreen()
}
