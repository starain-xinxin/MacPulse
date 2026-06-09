import SwiftUI
import MacPulseShared

struct GPUCardView: View {
    let data: GPUData
    let thermal: ThermalData
    var useFahrenheit: Bool = false

    var body: some View {
        CardContainer(title: "GPU", icon: "gpu") {
            HStack(spacing: 16) {
                CircularGaugeView(
                    value: data.activeUsage,
                    label: "GPU",
                    color: gpuColor
                )

                VStack(alignment: .leading, spacing: 6) {
                    MetricRowView(label: "Name", value: data.gpuName)
                    MetricRowView(label: "Usage", value: Formatters.percentage(data.activeUsage))
                    if let temp = thermal.gpuTemperature {
                        MetricRowView(
                            label: "Temp",
                            value: Formatters.temperature(temp, useFahrenheit: useFahrenheit),
                            icon: "thermometer.medium"
                        )
                    }
                    MetricRowView(
                        label: "Thermal",
                        localizedValue: thermalPressureText,
                        valueColor: thermalColor
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var gpuColor: Color {
        if data.activeUsage > 0.8 { return .red }
        if data.activeUsage > 0.5 { return .orange }
        return .purple
    }

    private var thermalColor: Color {
        switch thermal.thermalPressure {
        case .critical: return .red
        case .serious: return .orange
        case .fair: return .yellow
        case .nominal: return .green
        }
    }

    private var thermalPressureText: LocalizedStringKey {
        switch thermal.thermalPressure {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        }
    }
}
