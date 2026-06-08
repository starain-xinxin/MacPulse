import WidgetKit
import MacPulseShared

struct CPUWidgetEntry: TimelineEntry {
    let date: Date
    let cpuData: CPUData
    let thermalData: ThermalData
    let history: [Double]

    static let placeholder = CPUWidgetEntry(
        date: Date(),
        cpuData: CPUData(overallUsage: 0.35, userUsage: 0.25, systemUsage: 0.10, idleUsage: 0.65, coreCount: 8, logicalCoreCount: 8),
        thermalData: .empty,
        history: [0.2, 0.35, 0.28, 0.5, 0.42, 0.6, 0.38, 0.45, 0.33, 0.5]
    )
}

struct CPUWidgetProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> CPUWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CPUWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CPUWidgetEntry>) -> Void) {
        // .atEnd: re-request as soon as this entry is rendered. While the app
        // runs it drives frequent reloads (not budget-charged); after a quit
        // the OS background budget paces this.
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }

    private func makeEntry() -> CPUWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return CPUWidgetEntry(date: snapshot.timestamp, cpuData: snapshot.cpu, thermalData: snapshot.thermal, history: snapshot.history.cpu)
        }
        return .placeholder
    }
}
