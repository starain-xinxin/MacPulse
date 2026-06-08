import SwiftUI

/// A compact line+gradient-fill sparkline shared by the dashboard and the
/// widget extension so both render identical charts. Mirrors the original
/// dashboard `SparklineView` look.
public struct MiniSparkline: View {
    private let data: [Double]
    private let color: Color
    private let height: CGFloat
    private let lineWidth: CGFloat
    private let maxValue: Double?

    public init(
        data: [Double],
        color: Color,
        height: CGFloat = 30,
        lineWidth: CGFloat = 1.5,
        maxValue: Double? = nil
    ) {
        self.data = data
        self.color = color
        self.height = height
        self.lineWidth = lineWidth
        self.maxValue = maxValue
    }

    private var effectiveMax: Double {
        maxValue ?? (data.max() ?? 1.0)
    }

    public var body: some View {
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

            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
        .frame(height: height)
    }
}

public extension MiniSparkline {
    /// Convenience initializer for `UInt64` series (e.g. bytes/sec).
    init(
        values: [UInt64],
        color: Color,
        height: CGFloat = 30,
        lineWidth: CGFloat = 1.5
    ) {
        self.init(
            data: values.map(Double.init),
            color: color,
            height: height,
            lineWidth: lineWidth
        )
    }
}
