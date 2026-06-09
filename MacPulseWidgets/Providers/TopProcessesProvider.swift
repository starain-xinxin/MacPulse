import WidgetKit
import MacPulseShared

struct TopProcessesEntry: TimelineEntry {
    let date: Date
    let processes: ProcessData

    static let placeholder = TopProcessesEntry(
        date: Date(),
        processes: ProcessData(
            topCPU: [
                ProcessMetric(processID: 101, name: "Xcode", cpuUsage: 0.624, memoryBytes: 2_400_000_000),
                ProcessMetric(processID: 102, name: "Safari", cpuUsage: 0.318, memoryBytes: 1_850_000_000),
                ProcessMetric(processID: 103, name: "WindowServer", cpuUsage: 0.142, memoryBytes: 820_000_000),
            ],
            topMemory: [
                ProcessMetric(processID: 102, name: "Safari", cpuUsage: 0.318, memoryBytes: 1_850_000_000),
                ProcessMetric(processID: 101, name: "Xcode", cpuUsage: 0.624, memoryBytes: 1_420_000_000),
                ProcessMetric(processID: 104, name: "Finder", cpuUsage: 0.028, memoryBytes: 640_000_000),
            ]
        )
    )
}

struct TopProcessesProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> TopProcessesEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TopProcessesEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopProcessesEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }

    private func makeEntry() -> TopProcessesEntry {
        guard let snapshot = sharedData.readSnapshot() else { return .placeholder }
        return TopProcessesEntry(
            date: snapshot.timestamp,
            processes: snapshot.processes
        )
    }
}
