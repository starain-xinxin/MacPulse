import Foundation
import Testing
import MacPulseShared
@testable import MacPulse

struct MacPulseTests {

    @Test func memoryMonitorReturnsData() async throws {
        let monitor = MemoryMonitor()
        let data = monitor.fetch()
        #expect(data.totalBytes > 0)
        #expect(data.usedBytes > 0)
        #expect(data.totalBytes >= data.usedBytes)
    }

    @Test func cpuMonitorReturnsData() async throws {
        let monitor = CPUMonitor()
        // First call initializes previous ticks
        _ = monitor.fetch()
        // Need a small delay for delta calculation
        try await Task.sleep(for: .milliseconds(100))
        let data = monitor.fetch()
        #expect(data.logicalCoreCount > 0)
        #expect(data.coreCount > 0)
    }

    @Test func diskMonitorReturnsData() async throws {
        let monitor = DiskMonitor()
        let disks = monitor.fetch()
        #expect(!disks.isEmpty)
        #expect(disks[0].totalBytes > 0)
    }

    @Test func systemInfoProviderReturnsData() async throws {
        let provider = SystemInfoProvider()
        let info = provider.fetch()
        #expect(!info.modelIdentifier.isEmpty)
        #expect(!info.osVersion.isEmpty)
        #expect(info.uptime > 0)
    }

    @Test func systemSnapshotCodable() async throws {
        let snapshot = SystemSnapshot(
            cpu: CPUData(overallUsage: 0.5, coreCount: 8, logicalCoreCount: 8),
            memory: MemoryData(totalBytes: 16_000_000_000, usedBytes: 8_000_000_000)
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(SystemSnapshot.self, from: data)
        #expect(decoded.cpu.overallUsage == 0.5)
        #expect(decoded.memory.totalBytes == 16_000_000_000)
    }
}
