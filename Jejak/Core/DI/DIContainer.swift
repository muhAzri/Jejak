import Swinject

@MainActor
final class DIContainer {
    static let shared = DIContainer()

    let container: Container
    private let assembler: Assembler

    private init() {
        container = Container()
        assembler = Assembler(
            [
                OnboardingAssembly(),
                SettingsAssembly(),
                HomeAssembly(),
                CounterAssembly(),
                // add one Assembly per feature
            ],
            container: container
        )
    }

    func resolve<T>(_ type: T.Type) -> T {
        guard let instance = container.resolve(type) else {
            fatalError("\(type) is not registered")
        }
        return instance
    }
}
