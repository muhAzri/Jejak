import SwiftUI

/// Heroicons v2 solid (24px), stored as template SVGs in Assets.xcassets/Heroicons.
enum HeroIcon: String {
    case shieldCheck = "shield-check"
    case user
    case signalSlash = "signal-slash"
    case lockClosed = "lock-closed"
    case informationCircle = "information-circle"
    case mapPin = "map-pin"
}

extension Image {
    init(heroicon: HeroIcon) {
        self.init("Heroicons/\(heroicon.rawValue)")
    }
}
