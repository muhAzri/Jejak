protocol CounterRepository {
    func current() -> Counter
    func increment() -> Counter
}
