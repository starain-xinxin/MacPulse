import SwiftUI
import MacPulseShared

struct MemoryCardView: View {
    let data: MemoryData
    let history: [Double]
    let topProcesses: [ProcessMetric]

    var body: some View {
        CardContainer(title: "Memory", icon: "memorychip") {
            HStack(spacing: 16) {
                CircularGaugeView(
                    value: usageRatio,
                    label: "RAM",
                    color: memoryColor
                )

                VStack(alignment: .leading, spacing: 6) {
                    MetricRowView(
                        label: "Used",
                        value: "\(Formatters.byteCount(data.usedBytes)) / \(Formatters.byteCount(data.totalBytes))"
                    )
                    MetricRowView(label: "Active", value: Formatters.byteCount(data.activeBytes))
                    MetricRowView(label: "Wired", value: Formatters.byteCount(data.wiredBytes))
                    MetricRowView(label: "Compressed", value: Formatters.byteCount(data.compressedBytes))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            UsageBarView(segments: [
                ("Active", Double(data.activeBytes), .blue),
                ("Wired", Double(data.wiredBytes), .orange),
                ("Compressed", Double(data.compressedBytes), .purple),
                ("Free", Double(data.freeBytes), .gray.opacity(0.3)),
            ])

            HStack {
                MetricRowView(
                    label: "Pressure",
                    localizedValue: pressureText,
                    valueColor: pressureColor
                )
                Spacer()
                if data.swapUsedBytes > 0 {
                    MetricRowView(label: "Swap", value: Formatters.byteCount(data.swapUsedBytes))
                }
            }

            if history.count > 1 {
                SparklineView(data: history, color: memoryColor, maxValue: 1.0)
            }

            TopProcessListView(processes: topProcesses, metric: .memory)
        }
    }

    private var usageRatio: Double {
        data.totalBytes > 0 ? Double(data.usedBytes) / Double(data.totalBytes) : 0
    }

    private var memoryColor: Color {
        switch data.pressure {
        case .critical: return .red
        case .warning: return .orange
        case .nominal: return .green
        }
    }

    private var pressureColor: Color {
        switch data.pressure {
        case .critical: return .red
        case .warning: return .orange
        case .nominal: return .green
        }
    }

    private var pressureText: LocalizedStringKey {
        switch data.pressure {
        case .nominal: return "Nominal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}
