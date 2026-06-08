import WidgetKit
import MacPulseShared

struct MemoryWidgetEntry: TimelineEntry {
    let date: Date
    let memoryData: MemoryData

    static let placeholder = MemoryWidgetEntry(
        date: Date(),
        memoryData: MemoryData(
            totalBytes: 16_000_000_000,
            usedBytes: 10_000_000_000,
            freeBytes: 6_000_000_000,
            activeBytes: 5_000_000_000,
            wiredBytes: 3_000_000_000,
            compressedBytes: 2_000_000_000,
            pressure: .nominal
        )
    )
}

struct MemoryWidgetProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> MemoryWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoryWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> MemoryWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return MemoryWidgetEntry(date: snapshot.timestamp, memoryData: snapshot.memory)
        }
        return .placeholder
    }
}
