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

    @Test func networkSparklineIgnoresStalePeakWhenScalingRecentTraffic() {
        let stalePeak = [4_660_901.0]
        let oldLowTraffic = Array(repeating: 10_000.0, count: 39)
        let recentTraffic = Array(repeating: 20_000.0, count: 19) + [1_000_000.0]
        let samples = stalePeak + oldLowTraffic + recentTraffic

        let zeroBased = SparklineNormalizer.normalizedHeights(data: samples, scale: .zeroBased)
        let adaptive = SparklineNormalizer.normalizedHeights(
            data: samples,
            scale: .adaptiveRange(recentSampleCount: 20)
        )

        #expect((zeroBased.last ?? 0) < 0.25)
        #expect((adaptive.last ?? 0) > 0.95)
    }

    @Test func networkSparklineConvertsUInt64SamplesNumerically() {
        let samples: [UInt64] = [0, 900_000, 40_000, 1_500_000]
        let converted = SparklineNormalizer.doubleValues(from: samples)

        #expect(converted == [0, 900_000, 40_000, 1_500_000])
        #expect(converted.max() == 1_500_000)
    }

    @Test func networkSparklineShowsVariationOnHighBaselineTraffic() {
        let samples = [1_000_000.0, 1_120_000.0, 940_000.0, 1_060_000.0, 900_000.0]
        let adaptive = SparklineNormalizer.normalizedHeights(
            data: samples,
            scale: .adaptiveRange(recentSampleCount: 5)
        )

        let range = (adaptive.max() ?? 0) - (adaptive.min() ?? 0)
        #expect(range > 0.75)
    }
}
