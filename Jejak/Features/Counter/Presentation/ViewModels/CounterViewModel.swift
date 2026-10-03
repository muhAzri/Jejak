import Observation

@MainActor
@Observable
final class CounterViewModel {
    private(set) var counter = Counter()

    private let getCounter: GetCounter
    private let incrementCounter: IncrementCounter

    init(getCounter: GetCounter, incrementCounter: IncrementCounter) {
        self.getCounter = getCounter
        self.incrementCounter = incrementCounter
    }

    func load() { counter = getCounter() }
    func incrementTapped() { counter = incrementCounter() }
}
