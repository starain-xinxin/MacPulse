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
    private let processMonitor = ProcessMonitor()
    private let systemInfoProvider = SystemInfoProvider()
    private let sharedDataManager = SharedDataManager()
    let locationManager = LocationManager()

    private var timer: Timer?
    private var isPolling = false
    private var lastSampleAt: [MonitorModule: Date] = [:]
    var refreshSettings: ModuleRefreshSettings

    init() {
        refreshSettings = Self.loadRefreshSettings()
        try? sharedDataManager.setSharedRefreshSettings(refreshSettings)
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

        let timer = Timer(timeInterval: AppConstants.schedulerInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func updateRefreshInterval(_ interval: TimeInterval, for module: MonitorModule) {
        guard refreshSettings[module] != interval else { return }
        refreshSettings[module] = interval
        UserDefaults.standard.set(refreshSettings[module], forKey: Self.preferenceKey(for: module))
        try? sharedDataManager.setSharedRefreshSettings(refreshSettings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func poll() async {
        guard !isPolling else { return }
        isPolling = true
        defer { isPolling = false }

        // Propagate current location authorization so the network monitor knows
        // whether it is allowed to read the Wi-Fi SSID this cycle.
        networkMonitor.locationAuthorized = locationManager.isAuthorized

        let now = Date()
        let dueModules = Set(MonitorModule.allCases.filter {
            Self.isDue(
                lastRefresh: lastSampleAt[$0],
                interval: refreshSettings[$0],
                now: now
            )
        })
        guard !dueModules.isEmpty else { return }

        let currentSnapshot = snapshot
        let result = await Task.detached { [cpuMonitor, memoryMonitor, diskMonitor, networkMonitor, batteryMonitor, gpuMonitor, thermalMonitor, processMonitor, systemInfoProvider] in
            var updated = currentSnapshot
            updated.timestamp = now

            if dueModules.contains(.cpu) {
                updated.cpu = cpuMonitor.fetch()
            }
            if dueModules.contains(.memory) {
                updated.memory = memoryMonitor.fetch()
            }
            if dueModules.contains(.disk) {
                updated.disks = diskMonitor.fetch()
                updated.systemInfo = systemInfoProvider.fetch()
            }
            if dueModules.contains(.network) {
                updated.network = networkMonitor.fetch()
            }
            if dueModules.contains(.battery) {
                updated.battery = batteryMonitor.fetch()
            }
            if dueModules.contains(.gpu) {
                updated.gpu = gpuMonitor.fetch()
            }
            if dueModules.contains(.cpu) || dueModules.contains(.gpu) {
                updated.thermal = thermalMonitor.fetch()
            }
            if dueModules.contains(.processes) {
                updated.processes = processMonitor.fetch()
            }

            return updated
        }.value

        for module in dueModules {
            lastSampleAt[module] = now
        }
        snapshot = result
        appendHistory(for: dueModules)

        // Attach recent history so widgets can render the same sparklines as
        // the dashboard.
        snapshot.history = MetricHistory(
            cpu: cpuHistory,
            memory: memoryHistory,
            gpu: gpuHistory,
            download: downloadHistory,
            upload: uploadHistory
        )

        try? sharedDataManager.writeSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func appendHistory(for modules: Set<MonitorModule>) {
        if modules.contains(.cpu) {
            cpuHistory.append(snapshot.cpu.overallUsage)
        }
        if modules.contains(.memory) {
            memoryHistory.append(
                snapshot.memory.totalBytes > 0
                    ? Double(snapshot.memory.usedBytes) / Double(snapshot.memory.totalBytes)
                    : 0
            )
        }
        if modules.contains(.gpu) {
            gpuHistory.append(snapshot.gpu.activeUsage)
        }
        if modules.contains(.network) {
            downloadHistory.append(snapshot.network.downloadBytesPerSecond)
            uploadHistory.append(snapshot.network.uploadBytesPerSecond)
        }

        let max = AppConstants.sparklineMaxSamples
        if cpuHistory.count > max { cpuHistory.removeFirst(cpuHistory.count - max) }
        if memoryHistory.count > max { memoryHistory.removeFirst(memoryHistory.count - max) }
        if gpuHistory.count > max { gpuHistory.removeFirst(gpuHistory.count - max) }
        if downloadHistory.count > max { downloadHistory.removeFirst(downloadHistory.count - max) }
        if uploadHistory.count > max { uploadHistory.removeFirst(uploadHistory.count - max) }
    }

    nonisolated static func isDue(
        lastRefresh: Date?,
        interval: TimeInterval,
        now: Date
    ) -> Bool {
        guard let lastRefresh else { return true }
        return now.timeIntervalSince(lastRefresh) >= interval
    }

    private static func loadRefreshSettings(
        defaults: UserDefaults = .standard
    ) -> ModuleRefreshSettings {
        let fallback = ModuleRefreshSettings.default
        return ModuleRefreshSettings(
            cpu: storedInterval(
                key: ModuleRefreshSettings.cpuPreferenceKey,
                fallback: fallback.cpu,
                defaults: defaults
            ),
            memory: storedInterval(
                key: ModuleRefreshSettings.memoryPreferenceKey,
                fallback: fallback.memory,
                defaults: defaults
            ),
            disk: storedInterval(
                key: ModuleRefreshSettings.diskPreferenceKey,
                fallback: fallback.disk,
                defaults: defaults
            ),
            network: storedInterval(
                key: ModuleRefreshSettings.networkPreferenceKey,
                fallback: fallback.network,
                defaults: defaults
            ),
            battery: storedInterval(
                key: ModuleRefreshSettings.batteryPreferenceKey,
                fallback: fallback.battery,
                defaults: defaults
            ),
            gpu: storedInterval(
                key: ModuleRefreshSettings.gpuPreferenceKey,
                fallback: fallback.gpu,
                defaults: defaults
            ),
            processes: storedInterval(
                key: ModuleRefreshSettings.processesPreferenceKey,
                fallback: fallback.processes,
                defaults: defaults
            )
        )
    }

    private static func storedInterval(
        key: String,
        fallback: TimeInterval,
        defaults: UserDefaults
    ) -> TimeInterval {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.double(forKey: key)
    }

    private static func preferenceKey(for module: MonitorModule) -> String {
        switch module {
        case .cpu: ModuleRefreshSettings.cpuPreferenceKey
        case .memory: ModuleRefreshSettings.memoryPreferenceKey
        case .disk: ModuleRefreshSettings.diskPreferenceKey
        case .network: ModuleRefreshSettings.networkPreferenceKey
        case .battery: ModuleRefreshSettings.batteryPreferenceKey
        case .gpu: ModuleRefreshSettings.gpuPreferenceKey
        case .processes: ModuleRefreshSettings.processesPreferenceKey
        }
    }
}
