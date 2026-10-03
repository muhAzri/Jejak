import CoreText
import SwiftUI

/// Typography scale from the F0 design. Display = Mochiy Pop One, body = Plus Jakarta Sans.
enum JejakFont {
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("MochiyPopOne-Regular", size: size, relativeTo: style)
    }

    static let h2 = body("Bold", 16, .headline)
    static let p1 = body("Regular", 14, .body)
    static let p1Semibold = body("SemiBold", 14, .body)
    static let p2Semibold = body("SemiBold", 13, .callout)
    static let p3Semibold = body("SemiBold", 12, .caption)

    private static func body(_ weight: String, _ size: CGFloat, _ style: Font.TextStyle) -> Font {
        .custom("PlusJakartaSans-\(weight)", size: size, relativeTo: style)
    }

    /// Registers bundled .ttf files at runtime; avoids a hand-written Info.plist for UIAppFonts.
    static func registerBundledFonts() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }
}
