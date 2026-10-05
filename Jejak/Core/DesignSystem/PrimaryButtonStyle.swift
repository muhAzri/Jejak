import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(JejakFont.h2)
            .foregroundStyle(JejakColor.accentInk)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(JejakColor.accent, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TextActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(JejakFont.p1Semibold)
            .foregroundStyle(JejakColor.textSecondary)
            .frame(minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Outlined capsule button (design-system `Button variant="secondary" size="sm"`).
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(JejakFont.p1Bold)
            .foregroundStyle(JejakColor.textPrimary)
            .padding(.horizontal, 24)
            .frame(minHeight: 40)
            .background(configuration.isPressed ? JejakColor.fillInput : .clear, in: Capsule())
            .overlay(Capsule().strokeBorder(JejakColor.strong, lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
