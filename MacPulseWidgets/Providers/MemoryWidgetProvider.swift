import WidgetKit
import MacPulseShared

struct MemoryWidgetEntry: TimelineEntry {
    let date: Date
    let memoryData: MemoryData
    let history: [Double]

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
        ),
        history: [0.55, 0.58, 0.6, 0.62, 0.59, 0.63, 0.61, 0.64, 0.62, 0.63]
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
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }

    private func makeEntry() -> MemoryWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return MemoryWidgetEntry(date: snapshot.timestamp, memoryData: snapshot.memory, history: snapshot.history.memory)
        }
        return .placeholder
    }
}
