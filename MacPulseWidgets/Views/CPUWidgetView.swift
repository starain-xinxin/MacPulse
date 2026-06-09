import SwiftUI
import WidgetKit
import MacPulseShared

struct CPUWidgetView: View {
    let entry: CPUWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.blue)
                Text("CPU")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(entry.cpuData.overallUsage))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(formatPercent(entry.cpuData.overallUsage))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .frame(width: 70, height: 70)

            if entry.history.count > 1 {
                MiniSparkline(data: entry.history, color: .blue, height: 18, maxValue: 1.0)
            } else if let temp = entry.thermalData.cpuTemperature {
                Text(String(format: "%.0f\u{00B0}C", temp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            smallView

            VStack(alignment: .leading, spacing: 4) {
                metricRow("User", formatPercent(entry.cpuData.userUsage))
                metricRow("System", formatPercent(entry.cpuData.systemUsage))
                metricRow("Idle", formatPercent(entry.cpuData.idleUsage))
                metricRow("Cores", "\(entry.cpuData.logicalCoreCount)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}
