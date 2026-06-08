import WidgetKit
import MacPulseShared

struct NetworkWidgetEntry: TimelineEntry {
    let date: Date
    let networkData: NetworkData
    let downloadHistory: [UInt64]
    let uploadHistory: [UInt64]

    static let placeholder = NetworkWidgetEntry(
        date: Date(),
        networkData: NetworkData(
            activeInterfaceName: "en0",
            interfaceType: .wifi,
            ssid: "Home Wi-Fi",
            localIPv4: "192.168.1.42",
            publicIP: "203.0.113.1",
            ipLocation: "San Francisco, CA",
            uploadBytesPerSecond: 340_000,
            downloadBytesPerSecond: 2_400_000,
            isConnected: true
        ),
        downloadHistory: [400_000, 1_200_000, 900_000, 2_400_000, 1_800_000, 2_100_000, 1_500_000, 2_400_000],
        uploadHistory: [120_000, 200_000, 180_000, 340_000, 260_000, 300_000, 220_000, 340_000]
    )
}

struct NetworkWidgetProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> NetworkWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NetworkWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NetworkWidgetEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }

    private func makeEntry() -> NetworkWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return NetworkWidgetEntry(
                date: snapshot.timestamp,
                networkData: snapshot.network,
                downloadHistory: snapshot.history.download,
                uploadHistory: snapshot.history.upload
            )
        }
        return .placeholder
    }
}
