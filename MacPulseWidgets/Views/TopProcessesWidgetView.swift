import SwiftUI
import WidgetKit
import MacPulseShared

struct TopProcessesWidgetView: View {
    let entry: TopProcessesEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: "list.number")
                    .foregroundStyle(.blue)
                Text("Top Processes")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(alignment: .top, spacing: 10) {
                processColumn(
                    title: "CPU",
                    icon: "cpu",
                    color: .blue,
                    processes: entry.processes.topCPU,
                    metric: .cpu
                )

                Divider()

                processColumn(
                    title: "RAM",
                    icon: "memorychip",
                    color: .green,
                    processes: entry.processes.topMemory,
                    metric: .memory
                )
            }
        }
    }

    private func processColumn(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        processes: [ProcessMetric],
        metric: WidgetProcessMetric
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)

            if processes.isEmpty {
                Text("No process data")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
            } else {
                let visibleProcesses = Array(processes.prefix(3))
                let maximum = visibleProcesses.map(metric.score).max() ?? 0

                ForEach(Array(visibleProcesses.enumerated()), id: \.element.id) { index, process in
                    processRow(
                        process,
                        rank: index + 1,
                        metric: metric,
                        color: color,
                        maximum: maximum
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func processRow(
        _ process: ProcessMetric,
        rank: Int,
        metric: WidgetProcessMetric,
        color: Color,
        maximum: Double
    ) -> some View {
        HStack(spacing: 5) {
            Text("\(rank)")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 15, height: 15)
                .background(color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                relativeBar(
                    value: maximum > 0 ? metric.score(for: process) / maximum : 0,
                    color: color
                )
            }

            Text(metric.formattedValue(for: process))
                .font(.system(size: 9, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func relativeBar(value: Double, color: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 3)
    }
}

private enum WidgetProcessMetric {
    case cpu
    case memory

    func score(for process: ProcessMetric) -> Double {
        switch self {
        case .cpu: return process.cpuUsage
        case .memory: return Double(process.memoryBytes)
        }
    }

    func formattedValue(for process: ProcessMetric) -> String {
        switch self {
        case .cpu:
            return String(format: "%.1f%%", process.cpuUsage * 100)
        case .memory:
            return ByteCountFormatter.string(
                fromByteCount: Int64(process.memoryBytes),
                countStyle: .memory
            )
        }
    }
}
