final class CounterRepositoryImpl: CounterRepository {
    private var counter = Counter()

    func current() -> Counter { counter }

    func increment() -> Counter {
        counter.value += 1
        return counter
    }
}
