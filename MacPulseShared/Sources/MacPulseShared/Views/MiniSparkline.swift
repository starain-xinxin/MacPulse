import SwiftUI

public enum SparklineScale: Sendable {
    case zeroBased
    case adaptiveRange(recentSampleCount: Int = 30, minimumRelativeSpan: Double = 0.10)
}

public enum SparklineNormalizer {
    public static func doubleValues(from values: [UInt64]) -> [Double] {
        values.map { Double($0) }
    }

    public static func normalizedHeights(
        data: [Double],
        maxValue: Double? = nil,
        scale: SparklineScale = .zeroBased
    ) -> [Double] {
        switch scale {
        case .zeroBased:
            let peak = max(maxValue ?? (data.max() ?? 1.0), 0.01)
            return data.map { clamp($0 / peak) }
        case let .adaptiveRange(recentSampleCount, minimumRelativeSpan):
            return adaptiveRangeHeights(
                data,
                recentSampleCount: recentSampleCount,
                minimumRelativeSpan: minimumRelativeSpan
            )
        }
    }

    private static func adaptiveRangeHeights(
        _ data: [Double],
        recentSampleCount: Int,
        minimumRelativeSpan: Double
    ) -> [Double] {
        guard !data.isEmpty else { return [] }

        let sampleCount = max(1, recentSampleCount)
        let recent = Array(data.suffix(sampleCount))
        let rawLow = max(recent.min() ?? 0, 0)
        let rawHigh = max(recent.max() ?? 1, 0.01)
        let rawSpan = rawHigh - rawLow
        let minimumSpan = max(rawHigh * max(minimumRelativeSpan, 0), 1)

        let low: Double
        let high: Double
        if rawSpan < minimumSpan {
            let midpoint = (rawLow + rawHigh) / 2
            low = max(0, midpoint - (minimumSpan / 2))
            high = low + minimumSpan
        } else {
            low = rawLow
            high = rawHigh
        }

        let span = max(high - low, 0.01)
        return data.map { clamp(($0 - low) / span) }
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

/// A compact line+gradient-fill sparkline shared by the dashboard and the
/// widget extension so both render identical charts. Mirrors the original
/// dashboard `SparklineView` look.
public struct MiniSparkline: View {
    private let data: [Double]
    private let color: Color
    private let height: CGFloat
    private let lineWidth: CGFloat
    private let maxValue: Double?
    private let scale: SparklineScale

    public init(
        data: [Double],
        color: Color,
        height: CGFloat = 30,
        lineWidth: CGFloat = 1.5,
        maxValue: Double? = nil,
        scale: SparklineScale = .zeroBased
    ) {
        self.data = data
        self.color = color
        self.height = height
        self.lineWidth = lineWidth
        self.maxValue = maxValue
        self.scale = scale
    }

    public var body: some View {
        Canvas { context, size in
            let heights = SparklineNormalizer.normalizedHeights(
                data: data,
                maxValue: maxValue,
                scale: scale
            )

            guard heights.count > 1 else { return }

            let stepX = size.width / CGFloat(heights.count - 1)

            var path = Path()
            for (index, ratio) in heights.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - (CGFloat(ratio) * size.height)
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
        lineWidth: CGFloat = 1.5,
        scale: SparklineScale = .adaptiveRange()
    ) {
        self.init(
            data: SparklineNormalizer.doubleValues(from: values),
            color: color,
            height: height,
            lineWidth: lineWidth,
            scale: scale
        )
    }
}

public struct NetworkSparkline: View {
    private let download: [UInt64]
    private let upload: [UInt64]
    private let height: CGFloat
    private let lineWidth: CGFloat
    private let recentSampleCount: Int

    public init(
        download: [UInt64],
        upload: [UInt64],
        height: CGFloat = 30,
        lineWidth: CGFloat = 1.5,
        recentSampleCount: Int = 30
    ) {
        self.download = download
        self.upload = upload
        self.height = height
        self.lineWidth = lineWidth
        self.recentSampleCount = recentSampleCount
    }

    public var body: some View {
        HStack(spacing: 12) {
            MiniSparkline(
                values: download,
                color: .blue,
                height: height,
                lineWidth: lineWidth,
                scale: .adaptiveRange(recentSampleCount: recentSampleCount)
            )
            .frame(maxWidth: .infinity)

            MiniSparkline(
                values: upload,
                color: .green.opacity(0.85),
                height: height,
                lineWidth: lineWidth,
                scale: .adaptiveRange(recentSampleCount: recentSampleCount)
            )
            .frame(maxWidth: .infinity)
        }
    }
}
