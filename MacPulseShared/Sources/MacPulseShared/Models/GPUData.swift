import Foundation

public struct GPUData: Codable, Sendable {
    public var activeUsage: Double
    public var gpuName: String

    public init(activeUsage: Double = 0, gpuName: String = "") {
        self.activeUsage = activeUsage
        self.gpuName = gpuName
    }

    public static let empty = GPUData()
}
