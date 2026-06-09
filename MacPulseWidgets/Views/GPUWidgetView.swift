import SwiftUI
import WidgetKit
import MacPulseShared

struct GPUWidgetView: View {
    let entry: GPUEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            title

            HStack(spacing: 16) {
                // GPU usage ring
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(gpuColor.opacity(0.15), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(entry.gpu.activeUsage, 1.0)))
                            .stroke(gpuColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 1) {
                            Image(systemName: "display")
                                .font(.system(size: 13))
                                .foregroundStyle(gpuColor)
                            Text(String(format: "%.0f%%", entry.gpu.activeUsage * 100))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                    }
                    .frame(width: 72, height: 72)
                    Text("GPU")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // GPU info
                VStack(alignment: .leading, spacing: 6) {
                    infoRow("display", "Name", entry.gpu.gpuName)
                    infoRow("chart.bar.fill", "Usage", String(format: "%.0f%%", entry.gpu.activeUsage * 100))

                    if let temp = entry.thermal.gpuTemperature {
                        infoRow("thermometer.medium", "Temp", String(format: "%.1f°C", temp))
                    }

                    infoRow("flame.fill", "Thermal", thermalPressureText, thermalColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var title: some View {
        HStack(spacing: 5) {
            Image(systemName: "display")
                .foregroundStyle(.purple)
            Text("GPU")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
        }
    }

    private func infoRow(_ icon: String, _ label: String, _ value: String, _ color: Color = .primary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private var gpuColor: Color {
        if entry.gpu.activeUsage > 0.8 { return .red }
        if entry.gpu.activeUsage > 0.5 { return .orange }
        return .purple
    }

    private var thermalColor: Color {
        switch entry.thermal.thermalPressure {
        case .critical: return .red
        case .serious: return .orange
        case .fair: return .yellow
        case .nominal: return .green
        }
    }

    private var thermalPressureText: String {
        switch entry.thermal.thermalPressure {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        }
    }
}
