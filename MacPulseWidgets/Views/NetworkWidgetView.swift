import SwiftUI
import WidgetKit
import MacPulseShared

struct NetworkWidgetView: View {
    let entry: NetworkWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    // MARK: Shared pieces

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: entry.networkData.isConnected ? "network" : "wifi.slash")
                .foregroundStyle(.cyan)
            Text("Network")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
            Text(entry.networkData.isConnected ? entry.networkData.interfaceType.displayName : "Offline")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func speedBadge(_ icon: String, _ color: Color, _ label: String, _ bytes: UInt64) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.callout)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(formatSpeed(bytes))
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }

    /// Both series on one shared-scale axis so up/down are directly comparable.
    private func chart(height: CGFloat) -> some View {
        let sharedMax = Double(max(
            entry.downloadHistory.max() ?? 0,
            entry.uploadHistory.max() ?? 0,
            1
        ))
        return ZStack {
            MiniSparkline(values: entry.downloadHistory, color: .blue, height: height)
                .environment(\.sparklineMax, sharedMax)
            MiniSparkline(values: entry.uploadHistory, color: .green.opacity(0.85), height: height)
                .environment(\.sparklineMax, sharedMax)
        }
    }

    private var hasHistory: Bool {
        entry.downloadHistory.count > 1 || entry.uploadHistory.count > 1
    }

    // MARK: Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            HStack(spacing: 18) {
                speedBadge("arrow.down.circle.fill", .blue, "Download", entry.networkData.downloadBytesPerSecond)
                speedBadge("arrow.up.circle.fill", .green, "Upload", entry.networkData.uploadBytesPerSecond)
                Spacer()
            }
            if hasHistory { chart(height: 30) }
            detailGrid(columns: 2)
        }
    }

    // MARK: Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            HStack(spacing: 24) {
                speedBadge("arrow.down.circle.fill", .blue, "Download", entry.networkData.downloadBytesPerSecond)
                speedBadge("arrow.up.circle.fill", .green, "Upload", entry.networkData.uploadBytesPerSecond)
                Spacer()
            }
            if hasHistory { chart(height: 70) }
            Divider()
            VStack(alignment: .leading, spacing: 7) {
                detailRow("wifi", "Wi-Fi", entry.networkData.ssid ?? "—")
                detailRow("pc", "Local", entry.networkData.localIPv4 ?? "—")
                detailRow("globe", "Public", entry.networkData.publicIP ?? "—")
                detailRow("location.fill", "Location", entry.networkData.ipLocation ?? "—")
                detailRow("cable.connector", "Interface", interfaceDescription)
            }
        }
    }

    // MARK: Detail rows

    private var interfaceDescription: String {
        let name = entry.networkData.activeInterfaceName
        let type = entry.networkData.interfaceType.displayName
        return name.isEmpty ? type : "\(type) (\(name))"
    }

    private func detailGrid(columns: Int) -> some View {
        let items: [(String, String, String)] = [
            ("wifi", "Wi-Fi", entry.networkData.ssid ?? "—"),
            ("pc", "Local", entry.networkData.localIPv4 ?? "—"),
            ("globe", "Public", entry.networkData.publicIP ?? "—"),
            ("location.fill", "Location", entry.networkData.ipLocation ?? "—"),
            ("cable.connector", "Interface", interfaceDescription)
        ]
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: columns),
            alignment: .leading,
            spacing: 3
        ) {
            ForEach(items, id: \.1) { item in
                detailRow(item.0, item.1, item.2)
            }
        }
    }

    private func detailRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.cyan)
                .frame(width: 13)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func formatSpeed(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory) + "/s"
    }
}
