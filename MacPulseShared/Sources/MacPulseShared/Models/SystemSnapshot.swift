import Foundation

public struct SystemSnapshot: Codable, Sendable {
    public var timestamp: Date
    public var cpu: CPUData
    public var memory: MemoryData
    public var disks: [DiskData]
    public var network: NetworkData
    public var battery: BatteryData?
    public var gpu: GPUData
    public var thermal: ThermalData
    public var systemInfo: SystemInfoData
    public var processes: ProcessData
    public var history: MetricHistory

    public init(
        timestamp: Date = Date(),
        cpu: CPUData = .empty,
        memory: MemoryData = .empty,
        disks: [DiskData] = [],
        network: NetworkData = .empty,
        battery: BatteryData? = nil,
        gpu: GPUData = .empty,
        thermal: ThermalData = .empty,
        systemInfo: SystemInfoData = .empty,
        processes: ProcessData = .empty,
        history: MetricHistory = .empty
    ) {
        self.timestamp = timestamp
        self.cpu = cpu
        self.memory = memory
        self.disks = disks
        self.network = network
        self.battery = battery
        self.gpu = gpu
        self.thermal = thermal
        self.systemInfo = systemInfo
        self.processes = processes
        self.history = history
    }

    public static let empty = SystemSnapshot()

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case cpu
        case memory
        case disks
        case network
        case battery
        case gpu
        case thermal
        case systemInfo
        case processes
        case history
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        cpu = try container.decode(CPUData.self, forKey: .cpu)
        memory = try container.decode(MemoryData.self, forKey: .memory)
        disks = try container.decode([DiskData].self, forKey: .disks)
        network = try container.decode(NetworkData.self, forKey: .network)
        battery = try container.decodeIfPresent(BatteryData.self, forKey: .battery)
        gpu = try container.decode(GPUData.self, forKey: .gpu)
        thermal = try container.decode(ThermalData.self, forKey: .thermal)
        systemInfo = try container.decode(SystemInfoData.self, forKey: .systemInfo)
        processes = try container.decodeIfPresent(ProcessData.self, forKey: .processes) ?? .empty
        history = try container.decode(MetricHistory.self, forKey: .history)
    }
}

public struct SystemInfoData: Codable, Sendable {
    public var modelName: String
    public var modelIdentifier: String
    public var chipName: String
    public var osVersion: String
    public var uptime: TimeInterval

    public init(
        modelName: String = "",
        modelIdentifier: String = "",
        chipName: String = "",
        osVersion: String = "",
        uptime: TimeInterval = 0
    ) {
        self.modelName = modelName
        self.modelIdentifier = modelIdentifier
        self.chipName = chipName
        self.osVersion = osVersion
        self.uptime = uptime
    }

    public static let empty = SystemInfoData()
}
