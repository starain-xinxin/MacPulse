import Foundation

public struct DiskData: Codable, Sendable, Identifiable {
    public var id: String { mountPoint }
    public var volumeName: String
    public var mountPoint: String
    public var totalBytes: UInt64
    public var usedBytes: UInt64
    public var freeBytes: UInt64
    public var fileSystemType: String

    public init(
        volumeName: String = "",
        mountPoint: String = "/",
        totalBytes: UInt64 = 0,
        usedBytes: UInt64 = 0,
        freeBytes: UInt64 = 0,
        fileSystemType: String = ""
    ) {
        self.volumeName = volumeName
        self.mountPoint = mountPoint
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.fileSystemType = fileSystemType
    }
}
