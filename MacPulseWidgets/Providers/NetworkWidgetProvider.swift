import WidgetKit
import MacPulseShared

struct NetworkWidgetEntry: TimelineEntry {
    let date: Date
    let networkData: NetworkData

    static let placeholder = NetworkWidgetEntry(
        date: Date(),
        networkData: NetworkData(
            activeInterfaceName: "en0",
            interfaceType: .wifi,
            localIPv4: "192.168.1.42",
            publicIP: "203.0.113.1",
            ipLocation: "San Francisco, CA",
            uploadBytesPerSecond: 340_000,
            downloadBytesPerSecond: 2_400_000,
            isConnected: true
        )
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
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> NetworkWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return NetworkWidgetEntry(date: snapshot.timestamp, networkData: snapshot.network)
        }
        return .placeholder
    }
}
