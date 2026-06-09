import SwiftUI
import WidgetKit
import MacPulseShared

struct BatteryWidgetView: View {
    let entry: BatteryWidgetEntry

    @Environment(\.widgetFamily) var family
    @Environment(\.locale) private var locale

    var body: some View {
        if let battery = entry.batteryData {
            switch family {
            case .systemSmall:
                smallView(battery)
            case .systemMedium:
                mediumView(battery)
            default:
                smallView(battery)
            }
        } else {
            Text("No Battery")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func smallView(_ data: BatteryData) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: data.isCharging ? "battery.100percent.bolt" : "battery.100percent")
                    .foregroundStyle(.green)
                Text("Battery")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(batteryColor(data).opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(data.chargeLevel))
                    .stroke(batteryColor(data), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0f%%", data.chargeLevel * 100))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .frame(width: 70, height: 70)

            Text(data.isCharging ? LocalizedStringKey("Charging") : LocalizedStringKey("On Battery"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func mediumView(_ data: BatteryData) -> some View {
        HStack(spacing: 16) {
            smallView(data)

            VStack(alignment: .leading, spacing: 4) {
                metricRow("Health", String(format: "%.0f%%", data.healthPercentage * 100))
                metricRow("Cycles", "\(data.cycleCount)")
                if let temp = data.temperature {
                    metricRow("Temp", String(format: "%.1f\u{00B0}C", temp))
                }
                if data.isCharging, let ttf = data.timeToFull {
                    metricRow("Full in", formatDuration(ttf))
                } else if let tte = data.timeToEmpty {
                    metricRow("Remaining", formatDuration(tte))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption2).fontWeight(.medium).monospacedDigit()
        }
    }

    private func batteryColor(_ data: BatteryData) -> Color {
        if data.chargeLevel > 0.5 { return .green }
        if data.chargeLevel > 0.2 { return .orange }
        return .red
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        if h > 0 {
            return String(
                format: String(localized: "%lldh %lldm", locale: locale),
                Int64(h),
                Int64(m)
            )
        }
        return String(
            format: String(localized: "%lldm", locale: locale),
            Int64(m)
        )
    }
}
