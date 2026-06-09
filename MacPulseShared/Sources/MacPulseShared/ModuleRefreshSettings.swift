import Foundation

public enum MonitorModule: String, CaseIterable, Codable, Sendable {
    case cpu
    case memory
    case disk
    case network
    case battery
    case gpu
    case processes
}

public struct ModuleRefreshSettings: Codable, Equatable, Sendable {
    public static let minimumInterval: TimeInterval = 1
    public static let maximumInterval: TimeInterval = 10

    public static let cpuPreferenceKey = "refreshInterval.cpu"
    public static let memoryPreferenceKey = "refreshInterval.memory"
    public static let diskPreferenceKey = "refreshInterval.disk"
    public static let networkPreferenceKey = "refreshInterval.network"
    public static let batteryPreferenceKey = "refreshInterval.battery"
    public static let gpuPreferenceKey = "refreshInterval.gpu"
    public static let processesPreferenceKey = "refreshInterval.processes"

    public var cpu: TimeInterval
    public var memory: TimeInterval
    public var disk: TimeInterval
    public var network: TimeInterval
    public var battery: TimeInterval
    public var gpu: TimeInterval
    public var processes: TimeInterval

    public init(
        cpu: TimeInterval = 2,
        memory: TimeInterval = 5,
        disk: TimeInterval = 10,
        network: TimeInterval = 1,
        battery: TimeInterval = 10,
        gpu: TimeInterval = 2,
        processes: TimeInterval = 2
    ) {
        self.cpu = Self.clamp(cpu)
        self.memory = Self.clamp(memory)
        self.disk = Self.clamp(disk)
        self.network = Self.clamp(network)
        self.battery = Self.clamp(battery)
        self.gpu = Self.clamp(gpu)
        self.processes = Self.clamp(processes)
    }

    public static let `default` = ModuleRefreshSettings()

    public subscript(module: MonitorModule) -> TimeInterval {
        get {
            switch module {
            case .cpu: cpu
            case .memory: memory
            case .disk: disk
            case .network: network
            case .battery: battery
            case .gpu: gpu
            case .processes: processes
            }
        }
        set {
            let value = Self.clamp(newValue)
            switch module {
            case .cpu: cpu = value
            case .memory: memory = value
            case .disk: disk = value
            case .network: network = value
            case .battery: battery = value
            case .gpu: gpu = value
            case .processes: processes = value
            }
        }
    }

    public func widgetInterval(for modules: [MonitorModule]) -> TimeInterval {
        modules.map { self[$0] }.min() ?? Self.minimumInterval
    }

    public var normalized: ModuleRefreshSettings {
        ModuleRefreshSettings(
            cpu: cpu,
            memory: memory,
            disk: disk,
            network: network,
            battery: battery,
            gpu: gpu,
            processes: processes
        )
    }

    private static func clamp(_ interval: TimeInterval) -> TimeInterval {
        min(max(interval, minimumInterval), maximumInterval)
    }
}
