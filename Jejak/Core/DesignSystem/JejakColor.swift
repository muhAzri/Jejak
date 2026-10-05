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
    /// Page background behind surfaces; the (always dark) session screen uses it edge to edge.
    static let canvas = Color(light: 0xEFEFEF, dark: 0x0B0B0B)
    static let textPrimary = Color(light: 0x262626, dark: 0xF2F2F2)
    static let textSecondary = Color(light: 0x838383, dark: 0x9A9A9A)
    static let fillMuted = Color(light: 0xCCCCCC, dark: 0x3A3A3A)
    static let fillInput = Color(light: 0xF6F6F6, dark: 0x242424)
    static let textOnDisabled = Color(light: 0xFFFFFF, dark: 0x7A7A7A)
    /// Primary text in light, near-white in dark; used for strong borders, radio fill and outlined buttons.
    static let strong = Color(light: 0x262626, dark: 0xF2F2F2)
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
    static let danger = Color(light: 0xE5484D, dark: 0xF0676B)
    static let textOnDanger = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
    static let scrim = Color(uiColor: UIColor { traits in
        UIColor(white: 0, alpha: traits.userInterfaceStyle == .dark ? 0.64 : 0.5)
    })
    static let dangerBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 229 / 255, green: 72 / 255, blue: 77 / 255, alpha: 0.16)
            : UIColor(red: 252 / 255, green: 239 / 255, blue: 239 / 255, alpha: 1)
    })

    /// Activity colors: Run = orange, Walk = teal. Card backgrounds use them at 12%.
    static let run = Color(light: 0xF2552C, dark: 0xF2552C)
    static let walk = Color(light: 0x0E9A8B, dark: 0x0E9A8B)

    /// Route pace scale on the summary map: slow → fast.
    static let paceSlow = Color(light: 0x9A9A9A, dark: 0x9A9A9A)
    static let paceFast = Color(light: 0xDB0826, dark: 0xDB0826)

    static let accentBackground = Color(uiColor: UIColor { traits in
        UIColor(red: 1, green: 237 / 255, blue: 0, alpha: traits.userInterfaceStyle == .dark ? 0.12 : 0.1)
    })
}
