import Foundation

public struct MemoryData: Codable, Sendable {
    public var totalBytes: UInt64
    public var usedBytes: UInt64
    public var freeBytes: UInt64
    public var activeBytes: UInt64
    public var inactiveBytes: UInt64
    public var wiredBytes: UInt64
    public var compressedBytes: UInt64
    public var pressure: MemoryPressure
    public var swapUsedBytes: UInt64
    public var swapTotalBytes: UInt64

    public enum MemoryPressure: String, Codable, Sendable {
        case nominal, warning, critical
    }

    public init(
        totalBytes: UInt64 = 0,
        usedBytes: UInt64 = 0,
        freeBytes: UInt64 = 0,
        activeBytes: UInt64 = 0,
        inactiveBytes: UInt64 = 0,
        wiredBytes: UInt64 = 0,
        compressedBytes: UInt64 = 0,
        pressure: MemoryPressure = .nominal,
        swapUsedBytes: UInt64 = 0,
        swapTotalBytes: UInt64 = 0
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.pressure = pressure
        self.swapUsedBytes = swapUsedBytes
        self.swapTotalBytes = swapTotalBytes
    }

    public static let empty = MemoryData()
}
