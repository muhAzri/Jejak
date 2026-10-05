import SwiftUI

/// Location is off: explains why the start cards are locked and links to iOS Settings.
/// `.split` fills the open Duo's right panel; other layouts show a banner above the cards.
struct LocationDeniedNotice: View {
    let layout: ScreenLayout
    let openSettings: () -> Void

    var body: some View {
        if layout == .split {
            panel
        } else {
            banner
        }
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(heroicon: .exclamationTriangle)
                    .resizable().scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(JejakColor.danger)
                    .accessibilityHidden(true)
                Text("Location Access Off")
                    .font(JejakFont.p1Bold)
            }
            message
            settingsButton
        }
        .foregroundStyle(JejakColor.textPrimary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JejakColor.dangerBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(heroicon: .mapPin)
                .resizable().scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(JejakColor.danger)
                .accessibilityHidden(true)
            Text("Location Access Off")
                .font(JejakFont.h1)
                .accessibilityAddTraits(.isHeader)
            message
            settingsButton
        }
        .foregroundStyle(JejakColor.textPrimary)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(JejakColor.dangerBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var message: some View {
        Text("Without location, Jejak can't record your route or distance. Turn it on in iOS Settings.")
            .font(JejakFont.p2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var settingsButton: some View {
        Button("Open Settings", action: openSettings)
            .buttonStyle(SecondaryButtonStyle())
    }
}

/// Location was granted with "Allow Once": suggests switching to "While Using the App".
struct LocationAllowedOnceNotice: View {
    let openSettings: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(heroicon: .informationCircle)
                .resizable().scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Location Allowed Once")
                    .font(JejakFont.p1Bold)
                Text("You'll be asked again every session. Choose “While Using the App” to skip this.")
                    .font(JejakFont.p2)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: openSettings) {
                    Text("Change in Settings")
                        .font(JejakFont.p2Bold)
                        .underline()
                        .frame(minHeight: 32)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: dismiss) {
                Image(heroicon: .xMark)
                    .resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(JejakColor.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Keeps the glyph where the design puts it while giving it a 44pt target.
            .padding(-12)
            .accessibilityLabel(Text("Dismiss"))
        }
        .foregroundStyle(JejakColor.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JejakColor.accentBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Location was never asked (onboarding's "Not Now"): offers the system dialog from Home.
struct LocationNotRequestedNotice: View {
    let isRequesting: Bool
    let allow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(heroicon: .mapPin)
                    .resizable().scaledToFit()
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
                Text("Location Not Allowed Yet")
                    .font(JejakFont.p1Bold)
            }
            Text("Jejak needs location to draw your route and measure distance.")
                .font(JejakFont.p2)
                .fixedSize(horizontal: false, vertical: true)
            Button("Allow Location", action: allow)
                .buttonStyle(SecondaryButtonStyle())
                .disabled(isRequesting)
        }
        .foregroundStyle(JejakColor.textPrimary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JejakColor.accentBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
