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
    var pollingInterval: TimeInterval

    init() {
        // Honor the saved polling interval. The shared (App Group) value is the
        // source of truth so the app and widgets agree; fall back to the local
        // default if neither is set.
        if let shared = sharedDataManager.sharedPollingInterval {
            pollingInterval = shared
        } else {
            let saved = UserDefaults.standard.double(forKey: "pollingInterval")
            pollingInterval = saved > 0 ? saved : AppConstants.defaultPollingInterval
        }
    }

    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []
    var gpuHistory: [Double] = []
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
        guard interval != pollingInterval else { return }
        pollingInterval = interval
        // Persist to the shared store so widgets reflect the same rate.
        sharedDataManager.setSharedPollingInterval(interval)
        if isRunning {
            stop()
            start()
        }
    }

    /// Adopt a polling interval chosen from a widget's configuration (written to
    /// the App Group) if it differs from the current one.
    private func reconcileSharedInterval() {
        guard let shared = sharedDataManager.sharedPollingInterval, shared != pollingInterval else { return }
        updatePollingInterval(shared)
    }

    private func poll() async {
        // Pick up a rate change made from a widget's edit UI.
        reconcileSharedInterval()

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

        // Attach recent history so widgets can render the same sparklines as
        // the dashboard.
        snapshot.history = MetricHistory(
            cpu: cpuHistory,
            memory: memoryHistory,
            gpu: gpuHistory,
            download: downloadHistory,
            upload: uploadHistory
        )

        // Write to the App Group and reload widgets on EVERY poll. The app is
        // the active/foreground process, so these reloads are not charged
        // against WidgetKit's background budget — this is what lets desktop
        // widgets update at second-level cadence while MacPulse runs. After a
        // full quit, the OS background budget (minutes) takes over.
        try? sharedDataManager.writeSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        pollCount += 1
    }

    private func appendHistory() {
        cpuHistory.append(snapshot.cpu.overallUsage)
        memoryHistory.append(
            snapshot.memory.totalBytes > 0
                ? Double(snapshot.memory.usedBytes) / Double(snapshot.memory.totalBytes)
                : 0
        )
        gpuHistory.append(snapshot.gpu.activeUsage)
        downloadHistory.append(snapshot.network.downloadBytesPerSecond)
        uploadHistory.append(snapshot.network.uploadBytesPerSecond)

        let max = AppConstants.sparklineMaxSamples
        if cpuHistory.count > max { cpuHistory.removeFirst(cpuHistory.count - max) }
        if memoryHistory.count > max { memoryHistory.removeFirst(memoryHistory.count - max) }
        if gpuHistory.count > max { gpuHistory.removeFirst(gpuHistory.count - max) }
        if downloadHistory.count > max { downloadHistory.removeFirst(downloadHistory.count - max) }
        if uploadHistory.count > max { uploadHistory.removeFirst(uploadHistory.count - max) }
    }
}
