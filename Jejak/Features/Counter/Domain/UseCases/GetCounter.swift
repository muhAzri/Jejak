struct GetCounter {
    private let repository: CounterRepository
    init(_ repository: CounterRepository) { self.repository = repository }
    func callAsFunction() -> Counter { repository.current() }
}
