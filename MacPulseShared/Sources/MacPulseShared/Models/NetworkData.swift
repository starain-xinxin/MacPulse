import Foundation

public struct NetworkData: Codable, Sendable {
    public var activeInterfaceName: String
    public var interfaceType: InterfaceType
    public var ssid: String?
    public var localIPv4: String?
    public var localIPv6: String?
    public var publicIP: String?
    public var ipLocation: String?
    public var uploadBytesPerSecond: UInt64
    public var downloadBytesPerSecond: UInt64
    public var totalUploadBytes: UInt64
    public var totalDownloadBytes: UInt64
    public var isConnected: Bool

    public enum InterfaceType: String, Codable, Sendable {
        case wifi, ethernet, cellular, other

        public var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .ethernet: return "Ethernet"
            case .cellular: return "Cellular"
            case .other: return "Other"
            }
        }
    }

    public init(
        activeInterfaceName: String = "",
        interfaceType: InterfaceType = .other,
        ssid: String? = nil,
        localIPv4: String? = nil,
        localIPv6: String? = nil,
        publicIP: String? = nil,
        ipLocation: String? = nil,
        uploadBytesPerSecond: UInt64 = 0,
        downloadBytesPerSecond: UInt64 = 0,
        totalUploadBytes: UInt64 = 0,
        totalDownloadBytes: UInt64 = 0,
        isConnected: Bool = false
    ) {
        self.activeInterfaceName = activeInterfaceName
        self.interfaceType = interfaceType
        self.ssid = ssid
        self.localIPv4 = localIPv4
        self.localIPv6 = localIPv6
        self.publicIP = publicIP
        self.ipLocation = ipLocation
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.totalUploadBytes = totalUploadBytes
        self.totalDownloadBytes = totalDownloadBytes
        self.isConnected = isConnected
    }

    public static let empty = NetworkData()
}
