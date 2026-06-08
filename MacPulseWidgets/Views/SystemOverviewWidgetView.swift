import SwiftUI
import WidgetKit
import MacPulseShared

struct SystemOverviewWidgetView: View {
    let entry: SystemOverviewEntry

    @Environment(\.widgetFamily) var family

    private var memoryUsage: Double {
        entry.snapshot.memory.totalBytes > 0
            ? Double(entry.snapshot.memory.usedBytes) / Double(entry.snapshot.memory.totalBytes)
            : 0
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .foregroundStyle(.cyan)
                Text("Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 12) {
                miniGauge("CPU", entry.snapshot.cpu.overallUsage, .blue)
                miniGauge("RAM", memoryUsage, .green)
            }

            if let battery = entry.snapshot.battery {
                HStack {
                    Image(systemName: "battery.100percent")
                        .font(.caption2)
                    Text(String(format: "%.0f%%", battery.chargeLevel * 100))
                        .font(.caption2)
                        .monospacedDigit()
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            miniGauge("CPU", entry.snapshot.cpu.overallUsage, .blue)
            miniGauge("RAM", memoryUsage, .green)

            VStack(alignment: .leading, spacing: 4) {
                if let battery = entry.snapshot.battery {
                    overviewRow("battery.100percent", String(format: "%.0f%%", battery.chargeLevel * 100))
                }
                if let disk = entry.snapshot.disks.first {
                    let free = ByteCountFormatter.string(fromByteCount: Int64(disk.freeBytes), countStyle: .file)
                    overviewRow("internaldrive", "\(free) free")
                }
                overviewRow("arrow.down", formatSpeed(entry.snapshot.network.downloadBytesPerSecond))
                overviewRow("arrow.up", formatSpeed(entry.snapshot.network.uploadBytesPerSecond))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var largeView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .foregroundStyle(.cyan)
                Text("System Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 16) {
                miniGauge("CPU", entry.snapshot.cpu.overallUsage, .blue)
                miniGauge("RAM", memoryUsage, .green)
                if entry.snapshot.gpu.activeUsage > 0 {
                    miniGauge("GPU", entry.snapshot.gpu.activeUsage, .purple)
                }
            }

            Divider()

            VStack(spacing: 6) {
                if let battery = entry.snapshot.battery {
                    detailRow("Battery", String(format: "%.0f%%", battery.chargeLevel * 100), "battery.100percent")
                }
                if let disk = entry.snapshot.disks.first {
                    let used = ByteCountFormatter.string(fromByteCount: Int64(disk.usedBytes), countStyle: .file)
                    let total = ByteCountFormatter.string(fromByteCount: Int64(disk.totalBytes), countStyle: .file)
                    detailRow("Disk", "\(used) / \(total)", "internaldrive")
                }
                detailRow("Download", formatSpeed(entry.snapshot.network.downloadBytesPerSecond), "arrow.down.circle")
                detailRow("Upload", formatSpeed(entry.snapshot.network.uploadBytesPerSecond), "arrow.up.circle")
                if let ip = entry.snapshot.network.publicIP {
                    detailRow("Public IP", ip, "globe")
                }
            }
        }
    }

    private func miniGauge(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0f%%", value * 100))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 50, height: 50)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    private func overviewRow(_ icon: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(value)
                .font(.caption2)
                .monospacedDigit()
        }
    }

    private func detailRow(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 16)
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

    private func formatSpeed(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory) + "/s"
    }
}
