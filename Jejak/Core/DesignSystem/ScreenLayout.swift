import SwiftUI

/// Layout per screen shape, from the iPhone Duo design.
enum ScreenLayout {
    /// Standard iPhone: single column.
    case regular
    /// Duo closed (outer screen, ~566pt tall): single column with tighter sizing.
    case compact
    /// Duo open (inner screen): context in the left panel, content and decisions in the right panel.
    case split

    init(horizontalSizeClass: UserInterfaceSizeClass?, size: CGSize) {
        if horizontalSizeClass == .regular && size.width > size.height {
            self = .split
        } else if size.height < 600 {
            self = .compact
        } else {
            self = .regular
        }
    }

    /// Space above the first line of content. The Duo screens can report little or no top safe area
    /// (status bar hidden), so they keep a floor that clears the rounded corners.
    func topMargin(safeAreaTop: CGFloat) -> CGFloat {
        self == .regular ? safeAreaTop : max(safeAreaTop + 8, 32)
    }

    /// Outer edge margin of the open Duo's panels (the fold side keeps 24pt).
    static func splitOuterMargin(safeAreaInset: CGFloat) -> CGFloat { max(32, safeAreaInset) }

    /// Motion for switching layouts when the Duo folds or unfolds.
    static func transition(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .timingCurve(0.2, 0, 0, 1, duration: 0.5)
    }
}
