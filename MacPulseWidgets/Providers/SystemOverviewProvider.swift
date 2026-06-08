import WidgetKit
import MacPulseShared

struct SystemOverviewEntry: TimelineEntry {
    let date: Date
    let snapshot: SystemSnapshot

    static let placeholder = SystemOverviewEntry(
        date: Date(),
        snapshot: SystemSnapshot(
            cpu: CPUData(overallUsage: 0.35, coreCount: 8, logicalCoreCount: 8),
            memory: MemoryData(totalBytes: 16_000_000_000, usedBytes: 10_000_000_000, freeBytes: 6_000_000_000),
            disks: [DiskData(volumeName: "Macintosh HD", totalBytes: 500_000_000_000, usedBytes: 245_000_000_000, freeBytes: 255_000_000_000)],
            battery: BatteryData(chargeLevel: 0.87)
        )
    )
}

struct SystemOverviewProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> SystemOverviewEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemOverviewEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SystemOverviewEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> SystemOverviewEntry {
        if let snapshot = sharedData.readSnapshot() {
            return SystemOverviewEntry(date: snapshot.timestamp, snapshot: snapshot)
        }
        return .placeholder
    }
}
