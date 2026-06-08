import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let color: Color
    var height: CGFloat = 30
    var maxValue: Double? = nil

    private var effectiveMax: Double {
        maxValue ?? (data.max() ?? 1.0)
    }

    var body: some View {
        Canvas { context, size in
            guard data.count > 1 else { return }

            let peak = max(effectiveMax, 0.01)
            let stepX = size.width / CGFloat(data.count - 1)

            var path = Path()
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - (CGFloat(value / peak) * size.height)
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Draw the fill
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()

            context.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.3), color.opacity(0.05)]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 0, y: size.height)
                )
            )

            // Draw the line
            context.stroke(
                path,
                with: .color(color),
                lineWidth: 1.5
            )
        }
        .frame(height: height)
    }
}

struct SparklineUInt64View: View {
    let data: [UInt64]
    let color: Color
    var height: CGFloat = 30

    var body: some View {
        SparklineView(
            data: data.map { Double($0) },
            color: color,
            height: height
        )
    }
}
