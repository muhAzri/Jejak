import SwiftUI

/// Chips over the top of the session map: activity on the left, GPS or lock state on the right.
struct SessionChips: View {
    let activity: ActivityType
    let signal: GPSSignal
    let phase: SessionPhase
    let isLocked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ActivityChip(activity: activity, background: JejakColor.surface)
            Spacer(minLength: 0)
            if isLocked {
                StatusChip(icon: .lockClosed, iconSize: 14, title: "Locked")
            } else if phase != .paused {
                switch signal {
                case .searching:
                    StatusChip(icon: .signalSlash, iconColor: JejakColor.textSecondary, title: "GPS")
                case .good:
                    StatusChip(icon: .signal, title: "GPS")
                case .weak:
                    StatusChip(icon: .exclamationTriangle, title: "Weak signal", isWarning: true)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: signal)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }
}

private struct StatusChip: View {
    let icon: HeroIcon
    var iconSize: CGFloat = 16
    var iconColor: Color?
    let title: LocalizedStringKey
    var isWarning = false

    var body: some View {
        HStack(spacing: 6) {
            Image(heroicon: icon)
                .resizable().scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(iconColor ?? (isWarning ? JejakColor.accentInk : JejakColor.textPrimary))
                .accessibilityHidden(true)
            Text(title)
                .font(JejakFont.p3Bold)
        }
        .foregroundStyle(isWarning ? JejakColor.accentInk : JejakColor.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isWarning ? JejakColor.accent : JejakColor.surface, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// "Paused · 0:42" pill at the bottom of the map.
struct PausedPill: View {
    let pausedFor: TimeInterval

    var body: some View {
        HStack(spacing: 8) {
            Image(heroicon: .pause)
                .resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Text("Paused · \(SessionFormat.duration(pausedFor))")
                .font(JejakFont.p1Bold)
                .monospacedDigit()
        }
        .foregroundStyle(JejakColor.accentInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(JejakColor.accent, in: Capsule())
        .fixedSize()
    }
}
