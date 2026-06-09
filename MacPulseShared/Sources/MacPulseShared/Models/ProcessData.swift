import Foundation

public struct ProcessData: Codable, Sendable {
    public var topCPU: [ProcessMetric]
    public var topMemory: [ProcessMetric]

    public init(
        topCPU: [ProcessMetric] = [],
        topMemory: [ProcessMetric] = []
    ) {
        self.topCPU = topCPU
        self.topMemory = topMemory
    }

    public static let empty = ProcessData()
}

public struct ProcessMetric: Codable, Sendable, Identifiable {
    public var id: Int32 { processID }
    public var processID: Int32
    public var name: String
    public var cpuUsage: Double
    public var memoryBytes: UInt64

    public init(
        processID: Int32,
        name: String,
        cpuUsage: Double = 0,
        memoryBytes: UInt64 = 0
    ) {
        self.processID = processID
        self.name = name
        self.cpuUsage = cpuUsage
        self.memoryBytes = memoryBytes
    }
}
