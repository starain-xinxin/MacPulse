import SwiftUI
import WidgetKit
import MacPulseShared

struct MemoryWidgetView: View {
    let entry: MemoryWidgetEntry

    @Environment(\.widgetFamily) var family

    private var usageRatio: Double {
        entry.memoryData.totalBytes > 0
            ? Double(entry.memoryData.usedBytes) / Double(entry.memoryData.totalBytes)
            : 0
    }

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
                Image(systemName: "memorychip")
                    .foregroundStyle(.green)
                Text("Memory")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(usageRatio))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(formatBytes(entry.memoryData.usedBytes))
                        .font(.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("/ \(formatBytes(entry.memoryData.totalBytes))")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)

            Text(entry.memoryData.pressure.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(pressureColor)

            if entry.history.count > 1 {
                MiniSparkline(data: entry.history, color: .green, height: 18, maxValue: 1.0)
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            smallView

            VStack(alignment: .leading, spacing: 4) {
                metricRow("Active", formatBytes(entry.memoryData.activeBytes))
                metricRow("Wired", formatBytes(entry.memoryData.wiredBytes))
                metricRow("Compressed", formatBytes(entry.memoryData.compressedBytes))
                metricRow("Free", formatBytes(entry.memoryData.freeBytes))
                if entry.memoryData.swapUsedBytes > 0 {
                    metricRow("Swap", formatBytes(entry.memoryData.swapUsedBytes))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
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

    private var pressureColor: Color {
        switch entry.memoryData.pressure {
        case .critical: return .red
        case .warning: return .orange
        case .nominal: return .green
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}
