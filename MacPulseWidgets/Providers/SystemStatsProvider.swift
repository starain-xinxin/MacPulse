import WidgetKit
import MacPulseShared

struct SystemStatsEntry: TimelineEntry {
    let date: Date
    let cpu: CPUData
    let memory: MemoryData
    let systemDisk: DiskData?

    static let placeholder = SystemStatsEntry(
        date: Date(),
        cpu: CPUData(overallUsage: 0.35, userUsage: 0.25, systemUsage: 0.10, idleUsage: 0.65, coreCount: 8, logicalCoreCount: 8),
        memory: MemoryData(
            totalBytes: 16_000_000_000,
            usedBytes: 10_000_000_000,
            freeBytes: 6_000_000_000,
            activeBytes: 5_000_000_000,
            wiredBytes: 3_000_000_000,
            compressedBytes: 2_000_000_000,
            pressure: .nominal
        ),
        systemDisk: DiskData(volumeName: "Macintosh HD", mountPoint: "/", totalBytes: 500_000_000_000, usedBytes: 245_000_000_000, freeBytes: 255_000_000_000)
    )
}

struct SystemStatsProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> SystemStatsEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemStatsEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SystemStatsEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }

    private func makeEntry() -> SystemStatsEntry {
        guard let snapshot = sharedData.readSnapshot() else { return .placeholder }
        // Prefer the root volume for "system disk"; fall back to the first.
        let disk = snapshot.disks.first { $0.mountPoint == "/" } ?? snapshot.disks.first
        return SystemStatsEntry(
            date: snapshot.timestamp,
            cpu: snapshot.cpu,
            memory: snapshot.memory,
            systemDisk: disk
        )
    }
}
