import SwiftUI

/// Lock · Pause/Resume · Finish. Finishing needs a one-second hold with a progress ring.
struct SessionControls: View {
    let isPaused: Bool
    /// Closed Duo: 56/80pt buttons instead of 64/96pt.
    let isCompact: Bool
    let onLock: () -> Void
    let onPauseResume: () -> Void
    let onFinish: () -> Void

    var body: some View {
        let side: CGFloat = isCompact ? 56 : 64
        let main: CGFloat = isCompact ? 80 : 96
        HStack(alignment: .top, spacing: 0) {
            ControlButton(title: "Lock", width: side + 8) {
                Button(action: onLock) {
                    RoundIcon(icon: .lockClosed, iconSize: isCompact ? 22 : 24, diameter: side,
                              background: JejakColor.surfaceTint, foreground: JejakColor.textPrimary)
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(Text("Lock"))
            }
            Spacer(minLength: 8)
            ControlButton(title: isPaused ? "Resume" : "Pause", width: main) {
                Button(action: onPauseResume) {
                    RoundIcon(icon: isPaused ? .play : .pause,
                              iconSize: isCompact ? 36 : 44,
                              diameter: main,
                              background: JejakColor.accent,
                              foreground: JejakColor.accentInk,
                              iconOffset: isPaused ? 3 : 0)
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(Text(isPaused ? "Resume" : "Pause"))
            }
            Spacer(minLength: 8)
            HoldToFinishButton(isPaused: isPaused, diameter: side, iconSize: isCompact ? 26 : 30, onFinish: onFinish)
        }
    }
}

private struct ControlButton<Content: View>: View {
    let title: LocalizedStringKey
    let width: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 6) {
            content
            Text(title)
                .font(JejakFont.p3)
                .foregroundStyle(JejakColor.textSecondary)
                .accessibilityHidden(true)
        }
        .frame(minWidth: width)
    }
}

private struct RoundIcon: View {
    let icon: HeroIcon
    let iconSize: CGFloat
    let diameter: CGFloat
    let background: Color
    let foreground: Color
    var iconOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Circle().fill(background)
            Image(heroicon: icon)
                .resizable().scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(foreground)
                .offset(x: iconOffset)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Stop button that only fires after a one-second press. Paused, it is highlighted and its label says to hold;
/// a short tap while recording shows that hint for a moment.
private struct HoldToFinishButton: View {
    let isPaused: Bool
    let diameter: CGFloat
    let iconSize: CGFloat
    let onFinish: () -> Void

    @State private var progress: CGFloat = 0
    @State private var didFinish = false
    @State private var showsHint = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let highlighted = isPaused || progress > 0
        VStack(spacing: 6) {
            ZStack {
                if highlighted {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(JejakColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                RoundIcon(icon: .stop,
                          iconSize: iconSize,
                          diameter: diameter,
                          background: highlighted ? JejakColor.textPrimary : JejakColor.surfaceTint,
                          foreground: highlighted ? JejakColor.surface : JejakColor.textPrimary)
            }
            .frame(width: diameter + 8, height: diameter + 8)
            .padding(-4)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 1, maximumDistance: 40) {
                didFinish = true
                onFinish()
            } onPressingChanged: { isPressing in
                if isPressing {
                    didFinish = false
                    withAnimation(.linear(duration: 1)) { progress = 1 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
                    if !didFinish { flashHint() }
                }
            }

            Text(isPaused || showsHint ? "Hold to finish" : "Finish")
                .font(isPaused || showsHint ? JejakFont.p3Bold : JejakFont.p3)
                .foregroundStyle(isPaused || showsHint ? JejakColor.textPrimary : JejakColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: diameter + 24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Finish"))
        .accessibilityHint(Text("Hold to finish"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onFinish)
    }

    private func flashHint() {
        guard !isPaused else { return }
        withAnimation(.easeInOut(duration: 0.2)) { showsHint = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) { showsHint = false }
        }
    }
}

/// Replaces the controls while locked; a one-second hold unlocks.
struct HoldToUnlockBar: View {
    let isCompact: Bool
    let onUnlock: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        let knob: CGFloat = isCompact ? 56 : 64
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(JejakColor.surfaceTint)
                Capsule()
                    .fill(JejakColor.accent.opacity(0.25))
                    .frame(width: knob + 8 + (proxy.size.width - knob - 8) * progress)
                Text("Hold to unlock")
                    .font(JejakFont.p1Bold)
                    .foregroundStyle(JejakColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knob)
                    .padding(.trailing, 16)
                ZStack {
                    Circle().fill(JejakColor.accent)
                    Image(heroicon: .lockClosed)
                        .resizable().scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(JejakColor.accentInk)
                }
                .frame(width: knob, height: knob)
                .padding(4)
            }
        }
        .frame(height: knob + 8)
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: 1, maximumDistance: 60) {
            onUnlock()
            progress = 0
        } onPressingChanged: { isPressing in
            withAnimation(isPressing ? .linear(duration: 1) : .easeOut(duration: 0.2)) { progress = isPressing ? 1 : 0 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Hold to unlock"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onUnlock)
    }
}

/// Shown until the first good fix: wait, or start without one.
struct GPSSearchCard: View {
    let onCancel: () -> Void
    let onStartAnyway: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Spinner()
                Text("Finding GPS Signal")
                    .font(JejakFont.h2Display)
                    .foregroundStyle(JejakColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Text("Wait a moment in the open for an accurate route. You can also start now.")
                .font(JejakFont.p2)
                .foregroundStyle(JejakColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(OutlinedButtonStyle())
                Button("Start Anyway", action: onStartAnyway)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JejakColor.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
