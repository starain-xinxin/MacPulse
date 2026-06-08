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

    public init(
        timestamp: Date = Date(),
        cpu: CPUData = .empty,
        memory: MemoryData = .empty,
        disks: [DiskData] = [],
        network: NetworkData = .empty,
        battery: BatteryData? = nil,
        gpu: GPUData = .empty,
        thermal: ThermalData = .empty,
        systemInfo: SystemInfoData = .empty
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
    }

    public static let empty = SystemSnapshot()
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
