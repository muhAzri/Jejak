import SwiftUI

/// Heroicons v2 solid, stored as template SVGs in Assets.xcassets/Heroicons.
/// 24px variants unless noted; the design uses the 20px set for small inline glyphs.
enum HeroIcon: String {
    case shieldCheck = "shield-check"
    case user
    case signalSlash = "signal-slash"
    case lockClosed = "lock-closed"
    case informationCircle = "information-circle"
    case mapPin = "map-pin"
    case cog = "cog-6-tooth"
    case flag
    case exclamationTriangle = "exclamation-triangle"
    case xMark = "x-mark"
    case chevronLeft = "chevron-left"
    case language
    // 20px
    case arrowRight = "arrow-right"
    case bolt
    case chevronRight = "chevron-right"
    case globeAsiaAustralia = "globe-asia-australia"
}

extension Image {
    init(heroicon: HeroIcon) {
        self.init("Heroicons/\(heroicon.rawValue)")
    }
}
