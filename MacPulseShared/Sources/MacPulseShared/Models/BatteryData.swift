import Foundation

public struct BatteryData: Codable, Sendable {
    public var chargeLevel: Double
    public var isCharging: Bool
    public var isPluggedIn: Bool
    public var cycleCount: Int
    public var healthPercentage: Double
    public var maxCapacity: Int
    public var designCapacity: Int
    public var temperature: Double?
    public var timeToEmpty: TimeInterval?
    public var timeToFull: TimeInterval?

    public init(
        chargeLevel: Double = 0,
        isCharging: Bool = false,
        isPluggedIn: Bool = false,
        cycleCount: Int = 0,
        healthPercentage: Double = 1.0,
        maxCapacity: Int = 0,
        designCapacity: Int = 0,
        temperature: Double? = nil,
        timeToEmpty: TimeInterval? = nil,
        timeToFull: TimeInterval? = nil
    ) {
        self.chargeLevel = chargeLevel
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.cycleCount = cycleCount
        self.healthPercentage = healthPercentage
        self.maxCapacity = maxCapacity
        self.designCapacity = designCapacity
        self.temperature = temperature
        self.timeToEmpty = timeToEmpty
        self.timeToFull = timeToFull
    }

    public static let empty = BatteryData()
}
