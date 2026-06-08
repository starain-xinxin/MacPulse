import SwiftUI
import MacPulseShared

/// Thin wrappers over the shared `MiniSparkline` so the dashboard and the
/// widget extension render identical charts from one source of truth.
struct SparklineView: View {
    let data: [Double]
    let color: Color
    var height: CGFloat = 30
    var maxValue: Double? = nil

    var body: some View {
        MiniSparkline(data: data, color: color, height: height, maxValue: maxValue)
    }
}

struct SparklineUInt64View: View {
    let data: [UInt64]
    let color: Color
    var height: CGFloat = 30

    var body: some View {
        MiniSparkline(values: data, color: color, height: height)
    }
}
