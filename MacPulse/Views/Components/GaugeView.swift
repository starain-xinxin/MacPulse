import SwiftUI

struct CircularGaugeView: View {
    let value: Double
    let label: LocalizedStringKey
    let color: Color
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(value, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: value)

            VStack(spacing: 2) {
                Text(Formatters.percentageInt(value))
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: size * 0.11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}
