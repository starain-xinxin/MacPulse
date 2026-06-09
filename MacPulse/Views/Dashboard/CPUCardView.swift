import SwiftUI
import MacPulseShared

struct CPUCardView: View {
    let data: CPUData
    let thermal: ThermalData
    let history: [Double]
    let topProcesses: [ProcessMetric]
    var useFahrenheit: Bool = false

    var body: some View {
        CardContainer(title: "CPU", icon: "cpu") {
            HStack(spacing: 16) {
                CircularGaugeView(
                    value: data.overallUsage,
                    label: "CPU",
                    color: cpuColor
                )

                VStack(alignment: .leading, spacing: 6) {
                    MetricRowView(label: "User", value: Formatters.percentage(data.userUsage))
                    MetricRowView(label: "System", value: Formatters.percentage(data.systemUsage))
                    MetricRowView(label: "Idle", value: Formatters.percentage(data.idleUsage))
                    if let temp = thermal.cpuTemperature {
                        MetricRowView(
                            label: "Temp",
                            value: Formatters.temperature(temp, useFahrenheit: useFahrenheit),
                            icon: "thermometer.medium"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !data.coreUsages.isEmpty {
                Divider()
                CoreUsageGrid(coreUsages: data.coreUsages)
            }

            if history.count > 1 {
                SparklineView(data: history, color: cpuColor, maxValue: 1.0)
            }

            TopProcessListView(processes: topProcesses, metric: .cpu)
        }
    }

    private var cpuColor: Color {
        if data.overallUsage > 0.8 { return .red }
        if data.overallUsage > 0.5 { return .orange }
        return .blue
    }
}

struct CoreUsageGrid: View {
    let coreUsages: [CPUData.CoreUsage]

    private let columns = [
        GridItem(.adaptive(minimum: 40, maximum: 60), spacing: 4)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(coreUsages) { core in
                VStack(spacing: 2) {
                    SimpleBarView(value: core.usage, color: coreColor(core.usage), height: 6)
                    Text("\(core.coreIndex)")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func coreColor(_ usage: Double) -> Color {
        if usage > 0.8 { return .red }
        if usage > 0.5 { return .orange }
        return .blue
    }
}
