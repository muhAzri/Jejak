import SwiftUI

/// Big distance readout: label, number, unit.
struct DistanceMetric: View {
    let meters: Double
    let unit: DistanceUnit
    let size: CGFloat
    var isDimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Distance")
                .font(JejakFont.p3Semibold)
                .foregroundStyle(JejakColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: SessionFormat.distance(meters, unit: unit))
                    .font(JejakFont.display(size, relativeTo: .largeTitle))
                    .foregroundStyle(isDimmed ? JejakColor.textSecondary : JejakColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                Text(verbatim: unit.symbol)
                    .font(JejakFont.h2)
                    .foregroundStyle(JejakColor.textSecondary)
            }
        }
        .monospacedDigit()
        .accessibilityElement(children: .combine)
    }
}

/// Small labeled value in the three-column metric row.
struct MetricTile: View {
    let title: LocalizedStringKey
    let value: String
    let size: CGFloat
    var isDimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(JejakFont.p3Semibold)
                .foregroundStyle(JejakColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(verbatim: value)
                .font(JejakFont.display(size, relativeTo: .title))
                .foregroundStyle(isDimmed ? JejakColor.textSecondary : JejakColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
