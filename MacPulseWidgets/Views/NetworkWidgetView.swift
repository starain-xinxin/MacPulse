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

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.cyan)
                Text("Network")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption2)
                    Spacer()
                    Text(formatSpeed(entry.networkData.downloadBytesPerSecond))
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption2)
                    Spacer()
                    Text(formatSpeed(entry.networkData.uploadBytesPerSecond))
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }

            Spacer()

            Text(entry.networkData.isConnected ? entry.networkData.interfaceType.rawValue.capitalized : "Offline")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            smallView

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
                metricRow("Interface", entry.networkData.activeInterfaceName)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
