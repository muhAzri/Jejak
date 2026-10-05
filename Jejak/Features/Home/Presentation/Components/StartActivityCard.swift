import SwiftUI

/// "Start Run" / "Start Walk" card. A wide row on iPhone and in the open Duo's left panel,
/// a tile in a two-column grid on the closed Duo.
struct StartActivityCard: View {
    let activity: ActivityType
    let layout: ScreenLayout
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if layout == .compact {
                    tile
                } else {
                    row
                }
            }
            .foregroundStyle(JejakColor.textPrimary)
            .background(activity.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .opacity(isLocked ? 0.45 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(CardPressStyle())
        .disabled(isLocked)
        .accessibilityLabel(Text(activity.startTitle))
    }

    private var row: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                ActivityChip(activity: activity, background: JejakColor.surface)
                Text(activity.startTitle)
                    .font(JejakFont.display(24, relativeTo: .title))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StartBadge(size: 64, isLocked: isLocked)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 132, maxHeight: layout == .split ? .infinity : nil)
    }

    private var tile: some View {
        VStack(alignment: .leading, spacing: 8) {
            ActivityChip(activity: activity, background: JejakColor.surface)
            Text(activity.startTitle)
                .font(JejakFont.display(20, relativeTo: .title2))
                .frame(maxWidth: .infinity, alignment: .leading)
            StartBadge(size: 48, isLocked: isLocked)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
    }
}

/// Round yellow "go" button, or a muted lock when location is off.
private struct StartBadge: View {
    let size: CGFloat
    let isLocked: Bool

    var body: some View {
        let icon: HeroIcon = isLocked ? .lockClosed : .arrowRight
        let iconSize: CGFloat = isLocked ? (size > 56 ? 24 : 22) : (size > 56 ? 28 : 24)
        ZStack {
            Circle().fill(isLocked ? JejakColor.fillMuted : JejakColor.accent)
            Image(heroicon: icon)
                .resizable().scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(isLocked ? JejakColor.textOnDisabled : JejakColor.accentInk)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Small activity label: colored glyph + name on a rounded chip.
struct ActivityChip: View {
    let activity: ActivityType
    let background: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(heroicon: activity.icon)
                .resizable().scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(activity.tint)
            Text(activity.title)
                .font(JejakFont.p3Bold)
                .foregroundStyle(JejakColor.textPrimary)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.vertical, 2)
        .background(background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ActivityType {
    var title: LocalizedStringKey {
        switch self {
        case .run: "Run"
        case .walk: "Walk"
        }
    }

    var startTitle: LocalizedStringKey {
        switch self {
        case .run: "Start Run"
        case .walk: "Start Walk"
        }
    }

    var icon: HeroIcon {
        switch self {
        case .run: .bolt
        case .walk: .globeAsiaAustralia
        }
    }

    var tint: Color {
        switch self {
        case .run: JejakColor.run
        case .walk: JejakColor.walk
        }
    }
}
