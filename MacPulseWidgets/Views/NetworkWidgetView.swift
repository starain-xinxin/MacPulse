import SwiftUI
import WidgetKit
import MacPulseShared

struct NetworkWidgetView: View {
    let entry: NetworkWidgetEntry

    @Environment(\.widgetFamily) var family
    @Environment(\.locale) private var locale

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
            Group {
                if entry.networkData.isConnected {
                    Text(interfaceNameKey)
                } else {
                    Text("Offline")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func metricBadge(
        _ icon: String,
        _ color: Color,
        _ label: LocalizedStringKey,
        _ value: String,
        monospaced: Bool = true
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.callout)
                .frame(width: 15)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                metricValue(value, monospaced: monospaced)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metricValue(_ value: String, monospaced: Bool) -> some View {
        if monospaced {
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(.middle)
        } else {
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func speedBadge(
        _ icon: String,
        _ color: Color,
        _ label: LocalizedStringKey,
        _ bytes: UInt64
    ) -> some View {
        metricBadge(icon, color, label, formatSpeed(bytes))
    }

    private var wifiBadge: some View {
        metricBadge(
            "wifi",
            .cyan,
            "Wi-Fi",
            entry.networkData.ssid ?? (
                entry.networkData.isConnected
                    ? "—"
                    : String(localized: "Offline", locale: locale)
            ),
            monospaced: false
        )
    }

    /// Each series uses the shared network sparkline scaling, which adapts to
    /// recent traffic instead of letting one stale spike flatten the chart.
    private func chart(height: CGFloat) -> some View {
        NetworkSparkline(download: entry.downloadHistory, upload: entry.uploadHistory, height: height)
    }

    private var hasHistory: Bool {
        entry.downloadHistory.count > 1 || entry.uploadHistory.count > 1
    }

    // MARK: Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            HStack(spacing: 10) {
                speedBadge("arrow.down.circle.fill", .blue, "Download", entry.networkData.downloadBytesPerSecond)
                speedBadge("arrow.up.circle.fill", .green, "Upload", entry.networkData.uploadBytesPerSecond)
                wifiBadge
            }
            if hasHistory { chart(height: 30) }
            detailGrid(columns: 2)
        }
    }

    // MARK: Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            HStack(spacing: 14) {
                speedBadge("arrow.down.circle.fill", .blue, "Download", entry.networkData.downloadBytesPerSecond)
                speedBadge("arrow.up.circle.fill", .green, "Upload", entry.networkData.uploadBytesPerSecond)
                wifiBadge
            }
            if hasHistory { chart(height: 70) }
            Divider()
            VStack(alignment: .leading, spacing: 7) {
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
        let type = localizedInterfaceName
        return name.isEmpty ? type : "\(type) (\(name))"
    }

    private func detailGrid(columns: Int) -> some View {
        let items: [(String, LocalizedStringKey, String)] = [
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
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                detailRow(item.0, item.1, item.2)
            }
        }
    }

    private func detailRow(
        _ icon: String,
        _ label: LocalizedStringKey,
        _ value: String
    ) -> some View {
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

    private var interfaceNameKey: LocalizedStringKey {
        switch entry.networkData.interfaceType {
        case .wifi: return "Wi-Fi"
        case .ethernet: return "Ethernet"
        case .cellular: return "Cellular"
        case .other: return "Other"
        }
    }

    private var localizedInterfaceName: String {
        switch entry.networkData.interfaceType {
        case .wifi: return String(localized: "Wi-Fi", locale: locale)
        case .ethernet: return String(localized: "Ethernet", locale: locale)
        case .cellular: return String(localized: "Cellular", locale: locale)
        case .other: return String(localized: "Other", locale: locale)
        }
    }
}
