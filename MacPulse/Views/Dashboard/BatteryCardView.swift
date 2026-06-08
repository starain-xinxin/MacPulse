import SwiftUI
import MacPulseShared

struct BatteryCardView: View {
    let data: BatteryData
    var useFahrenheit: Bool = false

    var body: some View {
        CardContainer(title: "Battery", icon: batteryIcon) {
            HStack(spacing: 16) {
                CircularGaugeView(
                    value: data.chargeLevel,
                    label: "BAT",
                    color: batteryColor
                )

                VStack(alignment: .leading, spacing: 6) {
                    MetricRowView(
                        label: "Status",
                        value: statusText,
                        valueColor: data.isCharging ? .green : .primary
                    )
                    MetricRowView(
                        label: "Health",
                        value: Formatters.percentage(data.healthPercentage),
                        valueColor: healthColor
                    )
                    MetricRowView(label: "Cycles", value: "\(data.cycleCount)")
                    if let temp = data.temperature {
                        MetricRowView(
                            label: "Temp",
                            value: Formatters.temperature(temp, useFahrenheit: useFahrenheit),
                            icon: "thermometer.medium"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let remaining = remainingText {
                Divider()
                HStack {
                    Image(systemName: data.isCharging ? "bolt.fill" : "clock")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(remaining)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusText: String {
        if data.isCharging { return "Charging" }
        if data.isPluggedIn { return "Plugged In" }
        return "On Battery"
    }

    private var remainingText: String? {
        if data.isCharging, let time = Formatters.timeRemaining(data.timeToFull) {
            return "\(time) until full"
        }
        if !data.isCharging, let time = Formatters.timeRemaining(data.timeToEmpty) {
            return "\(time) remaining"
        }
        return nil
    }

    private var batteryIcon: String {
        if data.isCharging { return "battery.100percent.bolt" }
        if data.chargeLevel > 0.75 { return "battery.100percent" }
        if data.chargeLevel > 0.5 { return "battery.75percent" }
        if data.chargeLevel > 0.25 { return "battery.50percent" }
        return "battery.25percent"
    }

    private var batteryColor: Color {
        if data.chargeLevel > 0.5 { return .green }
        if data.chargeLevel > 0.2 { return .orange }
        return .red
    }

    private var healthColor: Color {
        if data.healthPercentage > 0.8 { return .green }
        if data.healthPercentage > 0.6 { return .orange }
        return .red
    }
}
