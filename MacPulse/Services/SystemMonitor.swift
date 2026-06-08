import Foundation
import MacPulseShared
import WidgetKit

@Observable
@MainActor
final class SystemMonitor {
    var snapshot = SystemSnapshot.empty
    var isRunning = false

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitorService()
    private let batteryMonitor = BatteryMonitor()
    private let gpuMonitor = GPUMonitor()
    private let thermalMonitor = ThermalMonitor()
    private let systemInfoProvider = SystemInfoProvider()
    private let sharedDataManager = SharedDataManager()
    let locationManager = LocationManager()

    private var timer: Timer?
    private var pollCount = 0
    var pollingInterval: TimeInterval = AppConstants.defaultPollingInterval

    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []
    var downloadHistory: [UInt64] = []
    var uploadHistory: [UInt64] = []

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Request location access; it gates Wi-Fi SSID lookup on macOS Sonoma+.
        locationManager.requestAuthorization()

        // Initial fetch
        Task { await poll() }

        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func updatePollingInterval(_ interval: TimeInterval) {
        pollingInterval = interval
        if isRunning {
            stop()
            start()
        }
    }

    private func poll() async {
        // Propagate current location authorization so the network monitor knows
        // whether it is allowed to read the Wi-Fi SSID this cycle.
        networkMonitor.locationAuthorized = locationManager.isAuthorized

        let result = await Task.detached { [cpuMonitor, memoryMonitor, diskMonitor, networkMonitor, batteryMonitor, gpuMonitor, thermalMonitor, systemInfoProvider] in
            let cpu = cpuMonitor.fetch()
            let memory = memoryMonitor.fetch()
            let disks = diskMonitor.fetch()
            let network = networkMonitor.fetch()
            let battery = batteryMonitor.fetch()
            let gpu = gpuMonitor.fetch()
            let thermal = thermalMonitor.fetch()
            let systemInfo = systemInfoProvider.fetch()

            return SystemSnapshot(
                timestamp: Date(),
                cpu: cpu,
                memory: memory,
                disks: disks,
                network: network,
                battery: battery,
                gpu: gpu,
                thermal: thermal,
                systemInfo: systemInfo
            )
        }.value

        snapshot = result
        appendHistory()

        pollCount += 1
        if pollCount % Int(AppConstants.widgetReloadInterval / pollingInterval) == 0 {
            try? sharedDataManager.writeSnapshot(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func appendHistory() {
        cpuHistory.append(snapshot.cpu.overallUsage)
        memoryHistory.append(
            snapshot.memory.totalBytes > 0
                ? Double(snapshot.memory.usedBytes) / Double(snapshot.memory.totalBytes)
                : 0
        )
        downloadHistory.append(snapshot.network.downloadBytesPerSecond)
        uploadHistory.append(snapshot.network.uploadBytesPerSecond)

        let max = AppConstants.sparklineMaxSamples
        if cpuHistory.count > max { cpuHistory.removeFirst(cpuHistory.count - max) }
        if memoryHistory.count > max { memoryHistory.removeFirst(memoryHistory.count - max) }
        if downloadHistory.count > max { downloadHistory.removeFirst(downloadHistory.count - max) }
        if uploadHistory.count > max { uploadHistory.removeFirst(uploadHistory.count - max) }
    }
}
