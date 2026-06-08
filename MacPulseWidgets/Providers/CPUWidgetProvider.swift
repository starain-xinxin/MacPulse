import WidgetKit
import MacPulseShared

struct CPUWidgetEntry: TimelineEntry {
    let date: Date
    let cpuData: CPUData
    let thermalData: ThermalData

    static let placeholder = CPUWidgetEntry(
        date: Date(),
        cpuData: CPUData(overallUsage: 0.35, userUsage: 0.25, systemUsage: 0.10, idleUsage: 0.65, coreCount: 8, logicalCoreCount: 8),
        thermalData: .empty
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
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> CPUWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return CPUWidgetEntry(date: snapshot.timestamp, cpuData: snapshot.cpu, thermalData: snapshot.thermal)
        }
        return .placeholder
    }
}
