import SwiftUI
import UIKit

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum JejakColor {
    static let surface = Color(light: 0xFFFFFF, dark: 0x161616)
    static let textPrimary = Color(light: 0x262626, dark: 0xF2F2F2)
    static let textSecondary = Color(light: 0x838383, dark: 0x9A9A9A)
    static let fillMuted = Color(light: 0xCCCCCC, dark: 0x3A3A3A)
    static let surfaceTint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.06)
            : UIColor(white: 0, alpha: 0.05)
    })
    static let border = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.08)
            : UIColor(white: 0, alpha: 0.05)
    })
    static let accent = Color(light: 0xFFEE00, dark: 0xFFEE00)
    static let accentInk = Color(light: 0x262626, dark: 0x262626)
    static let accentBackground = Color(uiColor: UIColor { traits in
        UIColor(red: 1, green: 237 / 255, blue: 0, alpha: traits.userInterfaceStyle == .dark ? 0.12 : 0.1)
    })
}
