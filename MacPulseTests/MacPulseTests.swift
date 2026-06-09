import Foundation
import Testing
import MacPulseShared
@testable import MacPulse

struct MacPulseTests {

    @Test func appLanguagesExposeExpectedLocales() {
        #expect(AppLanguage.system.locale == .autoupdatingCurrent)
        #expect(AppLanguage.english.locale.identifier == "en")
        #expect(AppLanguage.simplifiedChinese.locale.identifier == "zh-Hans")
    }

    @Test func memoryMonitorReturnsData() async throws {
        let monitor = MemoryMonitor()
        let data = monitor.fetch()
        #expect(data.totalBytes > 0)
        #expect(data.usedBytes > 0)
        #expect(data.totalBytes >= data.usedBytes)
    }

    @Test func processMonitorRanksCPUAndMemoryIndependently() {
        let metrics = [
            ProcessMetric(processID: 1, name: "CPU Heavy", cpuUsage: 0.8, memoryBytes: 100),
            ProcessMetric(processID: 2, name: "Memory Heavy", cpuUsage: 0.2, memoryBytes: 900),
            ProcessMetric(processID: 3, name: "Balanced", cpuUsage: 0.5, memoryBytes: 500),
        ]

        let ranked = ProcessMonitor.ranked(metrics, limit: 2)

        #expect(ranked.topCPU.map(\.name) == ["CPU Heavy", "Balanced"])
        #expect(ranked.topMemory.map(\.name) == ["Memory Heavy", "Balanced"])
    }

    @Test func processMonitorReturnsLiveMemoryConsumers() {
        let data = ProcessMonitor(resultLimit: 3).fetch()

        #expect(!data.topMemory.isEmpty)
        #expect(data.topMemory.count <= 3)
        #expect(data.topMemory.allSatisfy { $0.memoryBytes > 0 && !$0.name.isEmpty })
    }

    @Test func processMonitorCalculatesCPUFromConsecutiveSamples() {
        let monitor = ProcessMonitor(resultLimit: 5)
        _ = monitor.fetch()

        let deadline = Date().addingTimeInterval(0.1)
        var accumulator = 0
        while Date() < deadline {
            accumulator &+= 1
        }

        let data = monitor.fetch()
        #expect(accumulator > 0)
        #expect(!data.topCPU.isEmpty)
        #expect(data.topCPU.allSatisfy { $0.cpuUsage > 0 })
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

    @Test func gpuUtilizationUsesDriverPreferredKeyAndNormalizesPercentage() {
        let statistics: [String: Any] = [
            "Device Utilization %": 37,
            "Renderer Utilization %": 82
        ]

        #expect(GPUMonitor.utilization(from: statistics) == 0.37)
    }

    @Test func gpuUtilizationSupportsAlternateDriverKeyAndClampsValue() {
        let statistics: [String: Any] = ["GPU Activity(%)": NSNumber(value: 145)]

        #expect(GPUMonitor.utilization(from: statistics) == 1)
        #expect(GPUMonitor.utilization(from: [:]) == nil)
    }

    @Test func gpuMonitorReturnsAValidLiveSample() {
        let data = GPUMonitor().fetch()

        #expect((0...1).contains(data.activeUsage))
        #expect(!data.gpuName.isEmpty)
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
            memory: MemoryData(totalBytes: 16_000_000_000, usedBytes: 8_000_000_000),
            processes: ProcessData(
                topCPU: [
                    ProcessMetric(processID: 42, name: "Test App", cpuUsage: 0.25)
                ]
            )
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(SystemSnapshot.self, from: data)
        #expect(decoded.cpu.overallUsage == 0.5)
        #expect(decoded.memory.totalBytes == 16_000_000_000)
        #expect(decoded.processes.topCPU.first?.name == "Test App")
    }

    @Test func systemSnapshotDecodesWithoutProcessData() throws {
        let snapshot = SystemSnapshot()
        let encoded = try JSONEncoder().encode(snapshot)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "processes")

        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(SystemSnapshot.self, from: legacyData)

        #expect(decoded.processes.topCPU.isEmpty)
        #expect(decoded.processes.topMemory.isEmpty)
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
