import SwiftUI

/// Layout per screen shape, from the iPhone Duo design.
enum ScreenLayout {
    /// Standard iPhone: single column.
    case regular
    /// Duo closed (outer screen, ~466×678pt): single column with tighter sizing.
    case compact
    /// Duo open (inner screen): context in the left panel, content and decisions in the right panel.
    case split

    init(horizontalSizeClass: UserInterfaceSizeClass?, size: CGSize) {
        if horizontalSizeClass == .regular && size.width > size.height {
            self = .split
        } else if size.height < 600 || size.width / size.height > 0.62 {
            // The closed Duo is much squarer than any iPhone (~0.69 vs 0.46–0.58 width/height),
            // whether measured edge to edge or inside the safe area.
            self = .compact
        } else {
            self = .regular
        }
    }

    /// Extra space between the top safe area (status bar) and the first line of content. Screens keep the
    /// top safe area, so iPhone needs none; the Duo screens can report little or no top safe area
    /// (status bar hidden), so they keep content at least 32pt from the edge to clear the rounded corners.
    func topMargin(safeAreaTop: CGFloat) -> CGFloat {
        self == .regular ? 0 : max(8, 32 - safeAreaTop)
    }

    /// Outer edge margin of the open Duo's panels (the fold side keeps 24pt).
    static func splitOuterMargin(safeAreaInset: CGFloat) -> CGFloat { max(32, safeAreaInset) }

    /// Motion for switching layouts when the Duo folds or unfolds.
    static func transition(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .timingCurve(0.2, 0, 0, 1, duration: 0.5)
    }
}
