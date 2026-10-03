import SwiftUI

struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? JejakColor.textPrimary : JejakColor.fillMuted)
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel(Text("Page \(current + 1) of \(count)"))
    }
}
