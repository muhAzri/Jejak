enum DistanceUnit: String, CaseIterable {
    case kilometers = "km"
    case miles = "mi"

    var metersPerUnit: Double {
        switch self {
        case .kilometers: 1_000
        case .miles: 1_609.344
        }
    }

    /// Short unit label shown next to distances.
    var symbol: String { rawValue }
}
