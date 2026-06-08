import Foundation

public struct ThermalData: Codable, Sendable {
    public var cpuTemperature: Double?
    public var gpuTemperature: Double?
    public var thermalPressure: ThermalPressureLevel

    public enum ThermalPressureLevel: String, Codable, Sendable {
        case nominal, fair, serious, critical
    }

    public init(
        cpuTemperature: Double? = nil,
        gpuTemperature: Double? = nil,
        thermalPressure: ThermalPressureLevel = .nominal
    ) {
        self.cpuTemperature = cpuTemperature
        self.gpuTemperature = gpuTemperature
        self.thermalPressure = thermalPressure
    }

    public static let empty = ThermalData()
}
