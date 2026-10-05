import SwiftUI

/// Full-width row with a trailing radio (design-system `ListRowRadio`).
struct RadioRow: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(JejakFont.p1)
                    .foregroundStyle(JejakColor.textPrimary)
                Spacer(minLength: 0)
                RadioIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct RadioIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? JejakColor.strong : JejakColor.textSecondary, lineWidth: 2)
            if isSelected {
                Circle()
                    .fill(JejakColor.strong)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 20, height: 20)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
