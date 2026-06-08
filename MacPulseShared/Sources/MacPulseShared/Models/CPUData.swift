import Foundation

public struct CPUData: Codable, Sendable {
    public var overallUsage: Double
    public var userUsage: Double
    public var systemUsage: Double
    public var idleUsage: Double
    public var coreUsages: [CoreUsage]
    public var coreCount: Int
    public var logicalCoreCount: Int

    public struct CoreUsage: Codable, Sendable, Identifiable {
        public var id: Int { coreIndex }
        public var coreIndex: Int
        public var usage: Double

        public init(coreIndex: Int, usage: Double) {
            self.coreIndex = coreIndex
            self.usage = usage
        }
    }

    public init(
        overallUsage: Double = 0,
        userUsage: Double = 0,
        systemUsage: Double = 0,
        idleUsage: Double = 1,
        coreUsages: [CoreUsage] = [],
        coreCount: Int = 0,
        logicalCoreCount: Int = 0
    ) {
        self.overallUsage = overallUsage
        self.userUsage = userUsage
        self.systemUsage = systemUsage
        self.idleUsage = idleUsage
        self.coreUsages = coreUsages
        self.coreCount = coreCount
        self.logicalCoreCount = logicalCoreCount
    }

    public static let empty = CPUData()
}
