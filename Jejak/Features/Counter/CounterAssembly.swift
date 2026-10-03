import Swinject

final class CounterAssembly: Assembly {
    func assemble(container: Container) {
        // Repository
        container.register(CounterRepository.self) { _ in
            CounterRepositoryImpl()
        }.inObjectScope(.container)

        // Use cases
        container.register(GetCounter.self) { r in
            GetCounter(r.resolve(CounterRepository.self)!)
        }.inObjectScope(.container)

        container.register(IncrementCounter.self) { r in
            IncrementCounter(r.resolve(CounterRepository.self)!)
        }.inObjectScope(.container)

        // ViewModel: new instance per resolve
        container.register(CounterViewModel.self) { r in
            MainActor.assumeIsolated {
                CounterViewModel(
                    getCounter: r.resolve(GetCounter.self)!,
                    incrementCounter: r.resolve(IncrementCounter.self)!
                )
            }
        }
    }
}
