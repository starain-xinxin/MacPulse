import SwiftUI
import MacPulseShared

struct NetworkCardView: View {
    let data: NetworkData
    let downloadHistory: [UInt64]
    let uploadHistory: [UInt64]

    var body: some View {
        CardContainer(title: "Network", icon: "network") {
            HStack {
                Label(
                    data.isConnected ? interfaceName : LocalizedStringKey("Disconnected"),
                    systemImage: data.isConnected ? interfaceIcon : "wifi.slash"
                )
                .font(.caption)
                .foregroundStyle(data.isConnected ? Color.primary : Color.red)

                Spacer()

                if !data.activeInterfaceName.isEmpty {
                    Text(data.activeInterfaceName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                    Text(Formatters.bytesPerSecond(data.downloadBytesPerSecond))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Text("Total: \(Formatters.byteCount(data.totalDownloadBytes))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label("Upload", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text(Formatters.bytesPerSecond(data.uploadBytesPerSecond))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Text("Total: \(Formatters.byteCount(data.totalUploadBytes))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            if downloadHistory.count > 1 || uploadHistory.count > 1 {
                NetworkSparkline(download: downloadHistory, upload: uploadHistory, height: 25)
            }

            Divider()

            if let ssid = data.ssid, !ssid.isEmpty {
                MetricRowView(label: "Wi-Fi", value: ssid, icon: "wifi")
            }
            if let ipv4 = data.localIPv4 {
                MetricRowView(label: "Local IP", value: ipv4, icon: "pc")
            }
            if let publicIP = data.publicIP {
                MetricRowView(label: "Public IP", value: publicIP, icon: "globe")
            }
            if let location = data.ipLocation {
                MetricRowView(label: "Location", value: location, icon: "location")
            }
        }
    }

    private var interfaceIcon: String {
        switch data.interfaceType {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .other: return "network"
        }
    }

    private var interfaceName: LocalizedStringKey {
        switch data.interfaceType {
        case .wifi: return "Wi-Fi"
        case .ethernet: return "Ethernet"
        case .cellular: return "Cellular"
        case .other: return "Other"
        }
    }
}
