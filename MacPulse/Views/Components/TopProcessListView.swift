import SwiftUI
import MacPulseShared

enum ProcessMetricKind {
    case cpu
    case memory

    var title: LocalizedStringKey {
        switch self {
        case .cpu: return "Top CPU"
        case .memory: return "Top Memory"
        }
    }

    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        }
    }

    var color: Color {
        switch self {
        case .cpu: return .blue
        case .memory: return .green
        }
    }

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
            return Formatters.byteCount(process.memoryBytes)
        }
    }
}

struct TopProcessListView: View {
    let processes: [ProcessMetric]
    let metric: ProcessMetricKind
    var limit = 3

    private var visibleProcesses: [ProcessMetric] {
        Array(processes.prefix(limit))
    }

    private var maximumScore: Double {
        visibleProcesses.map(metric.score).max() ?? 0
    }

    var body: some View {
        if !visibleProcesses.isEmpty {
            Divider()

            VStack(alignment: .leading, spacing: 7) {
                Label(metric.title, systemImage: metric.icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ForEach(Array(visibleProcesses.enumerated()), id: \.element.id) { index, process in
                    processRow(process, rank: index + 1)
                }
            }
        }
    }

    private func processRow(_ process: ProcessMetric, rank: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(rank)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(metric.color)
                .frame(width: 18, height: 18)
                .background(metric.color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(process.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)

                SimpleBarView(
                    value: maximumScore > 0 ? metric.score(for: process) / maximumScore : 0,
                    color: metric.color,
                    height: 3
                )
            }

            Text(metric.formattedValue(for: process))
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 54, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
