import SwiftUI

/// Bottom confirmation card over a scrim (design-system `ConfirmSheet`). Not dismissible by tapping the scrim:
/// the user has to choose one of the two actions.
struct ConfirmSheet: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let cancelTitle: LocalizedStringKey
    let confirmTitle: LocalizedStringKey
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(JejakFont.h2Display)
                    .foregroundStyle(JejakColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(JejakFont.p1)
                    .foregroundStyle(JejakColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)

            Rectangle().fill(JejakColor.border).frame(height: 1)

            HStack(spacing: 12) {
                Button(cancelTitle, action: onCancel)
                    .buttonStyle(OutlinedButtonStyle())
                Button(confirmTitle, action: onConfirm)
                    .buttonStyle(DangerButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
        .padding(.bottom, 8)
        .background(JejakColor.surface, in: UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(JejakColor.scrim.ignoresSafeArea())
        .accessibilityAddTraits(.isModal)
    }
}

/// Indeterminate ring (design-system `Spinner`).
struct Spinner: View {
    var size: CGFloat = 24
    var lineWidth: CGFloat = 4
    var color: Color = JejakColor.accent
    @State private var isRotating = false

    var body: some View {
        ZStack {
            Circle().stroke(JejakColor.fillInput, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(isRotating ? 360 : 0))
        }
        .padding(lineWidth / 2)
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { isRotating = true }
        }
        .accessibilityHidden(true)
    }
}
