import SwiftUI
import WidgetKit
import MacPulseShared

struct NetworkWidgetView: View {
    let entry: NetworkWidgetEntry

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

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: entry.networkData.isConnected ? "network" : "wifi.slash")
                .foregroundStyle(.cyan)
            Text("Network")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
        }
    }

    private var speeds: some View {
        VStack(spacing: 6) {
            speedRow("arrow.down.circle.fill", .blue, entry.networkData.downloadBytesPerSecond)
            speedRow("arrow.up.circle.fill", .green, entry.networkData.uploadBytesPerSecond)
        }
    }

    private var chart: some View {
        ZStack {
            MiniSparkline(values: entry.downloadHistory, color: .blue, height: 26)
            MiniSparkline(values: entry.uploadHistory, color: .green.opacity(0.8), height: 26)
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            speeds
            if entry.downloadHistory.count > 1 || entry.uploadHistory.count > 1 {
                chart
            } else {
                Spacer()
            }
            Text(entry.networkData.isConnected ? entry.networkData.interfaceType.rawValue.capitalized : "Offline")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    speeds
                    if entry.downloadHistory.count > 1 || entry.uploadHistory.count > 1 {
                        chart
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    if let ssid = entry.networkData.ssid, !ssid.isEmpty {
                        metricRow("Wi-Fi", ssid)
                    }
                    if let ip = entry.networkData.localIPv4 {
                        metricRow("Local", ip)
                    }
                    if let ip = entry.networkData.publicIP {
                        metricRow("Public", ip)
                    }
                    if let loc = entry.networkData.ipLocation {
                        metricRow("Location", loc)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func speedRow(_ icon: String, _ color: Color, _ bytes: UInt64) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption2)
            Spacer()
            Text(formatSpeed(bytes))
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }

    private func formatSpeed(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory) + "/s"
    }
}
