enum ActivityType: String, CaseIterable, Codable, Identifiable {
    var id: Self { self }

    case run
    case walk
}
