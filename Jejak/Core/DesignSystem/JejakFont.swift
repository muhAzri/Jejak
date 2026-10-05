import CoreText
import SwiftUI

/// Typography scale from the F0 design. Display = Mochiy Pop One, body = Plus Jakarta Sans.
enum JejakFont {
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("MochiyPopOne-Regular", size: size, relativeTo: style)
    }

    /// h1 · page title (display face).
    static let h1 = display(18, relativeTo: .title3)
    /// h2 · sheet and modal titles (display face).
    static let h2Display = display(16, relativeTo: .headline)
    static let h2 = body("Bold", 16, .headline)
    static let p1 = body("Regular", 14, .body)
    static let p1Semibold = body("SemiBold", 14, .body)
    static let p1Bold = body("Bold", 14, .body)
    static let p2 = body("Regular", 13, .callout)
    static let p2Semibold = body("SemiBold", 13, .callout)
    static let p2Bold = body("Bold", 13, .callout)
    static let p3 = body("Regular", 12, .caption)
    static let p3Semibold = body("SemiBold", 12, .caption)
    static let p3Bold = body("Bold", 12, .caption)

    private static func body(_ weight: String, _ size: CGFloat, _ style: Font.TextStyle) -> Font {
        .custom("PlusJakartaSans-\(weight)", size: size, relativeTo: style)
    }

    /// Registers bundled .ttf files at runtime; avoids a hand-written Info.plist for UIAppFonts.
    static func registerBundledFonts() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }
}
