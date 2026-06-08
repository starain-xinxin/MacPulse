import Foundation
import Network
import MacPulseShared
import CoreWLAN

final class NetworkMonitorService: @unchecked Sendable {
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.macpulse.network")
    private let wifiClient = CWWiFiClient.shared()

    private var currentInterfaceName: String = ""
    private var currentInterfaceType: NetworkData.InterfaceType = .other
    private var isConnected = false

    /// Set by the app once CoreLocation authorization is granted. On macOS
    /// Sonoma+ the SSID is only readable while the app holds location access.
    var locationAuthorized = false

    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var previousTimestamp: Date?

    private var cachedPublicIP: String?
    private var cachedIPLocation: String?
    private var lastPublicIPFetch: Date?

    init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.isConnected = (path.status == .satisfied)

            if path.usesInterfaceType(.wifi) {
                self.currentInterfaceType = .wifi
            } else if path.usesInterfaceType(.wiredEthernet) {
                self.currentInterfaceType = .ethernet
            } else if path.usesInterfaceType(.cellular) {
                self.currentInterfaceType = .cellular
            } else {
                self.currentInterfaceType = .other
            }

            // Find active interface name
            if let iface = path.availableInterfaces.first {
                self.currentInterfaceName = iface.name
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    deinit {
        pathMonitor.cancel()
    }
}

extension NetworkMonitorService: MonitorService {
    func fetch() -> NetworkData {
        let (bytesIn, bytesOut) = fetchNetworkBytes()
        let now = Date()

        var downloadSpeed: UInt64 = 0
        var uploadSpeed: UInt64 = 0

        if let prevTime = previousTimestamp, previousBytesIn > 0 {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0 {
                if bytesIn >= previousBytesIn {
                    downloadSpeed = UInt64(Double(bytesIn - previousBytesIn) / elapsed)
                }
                if bytesOut >= previousBytesOut {
                    uploadSpeed = UInt64(Double(bytesOut - previousBytesOut) / elapsed)
                }
            }
        }

        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
        previousTimestamp = now

        // Fetch public IP periodically
        if cachedPublicIP == nil || shouldRefreshPublicIP() {
            fetchPublicIPAndLocation()
        }

        let localIPs = fetchLocalIPs()

        return NetworkData(
            activeInterfaceName: currentInterfaceName,
            interfaceType: currentInterfaceType,
            ssid: fetchSSID(),
            localIPv4: localIPs.ipv4,
            localIPv6: localIPs.ipv6,
            publicIP: cachedPublicIP,
            ipLocation: cachedIPLocation,
            uploadBytesPerSecond: uploadSpeed,
            downloadBytesPerSecond: downloadSpeed,
            totalUploadBytes: bytesOut,
            totalDownloadBytes: bytesIn,
            isConnected: isConnected
        )
    }

    private func fetchNetworkBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0

        var current: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = current {
            let name = String(cString: addr.pointee.ifa_name)

            // Sum all physical interfaces (en*, lo0 excluded)
            if Int32(addr.pointee.ifa_addr.pointee.sa_family) == AF_LINK,
               name.hasPrefix("en") || name.hasPrefix("utun") || name.hasPrefix("pdp_ip")
            {
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    bytesIn += UInt64(networkData.pointee.ifi_ibytes)
                    bytesOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            current = addr.pointee.ifa_next
        }
        return (bytesIn, bytesOut)
    }

    private func fetchLocalIPs() -> (ipv4: String?, ipv6: String?) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (nil, nil) }
        defer { freeifaddrs(ifaddr) }

        var ipv4: String?
        var ipv6: String?
        let targetInterface = currentInterfaceName.isEmpty ? "en0" : currentInterfaceName

        var current: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = current {
            let name = String(cString: addr.pointee.ifa_name)
            let family = Int32(addr.pointee.ifa_addr.pointee.sa_family)

            if name == targetInterface {
                if family == AF_INET {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        addr.pointee.ifa_addr,
                        socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, 0, NI_NUMERICHOST
                    )
                    ipv4 = String(cString: hostname)
                } else if family == AF_INET6 {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        addr.pointee.ifa_addr,
                        socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, 0, NI_NUMERICHOST
                    )
                    let v6 = String(cString: hostname)
                    // Prefer non-link-local address
                    if ipv6 == nil || !v6.hasPrefix("fe80") {
                        ipv6 = v6
                    }
                }
            }
            current = addr.pointee.ifa_next
        }
        return (ipv4, ipv6)
    }

    /// Returns the current Wi-Fi SSID, or nil when not on Wi-Fi or when the
    /// system withholds it. On macOS Sonoma+ the SSID is only populated while
    /// the app holds CoreLocation authorization, so we skip the lookup
    /// entirely when unauthorized to avoid a misleading nil.
    private func fetchSSID() -> String? {
        guard currentInterfaceType == .wifi, locationAuthorized else { return nil }
        guard let interface = wifiClient.interface() else { return nil }
        return interface.ssid()
    }

    private func shouldRefreshPublicIP() -> Bool {
        guard let last = lastPublicIPFetch else { return true }
        return Date().timeIntervalSince(last) > AppConstants.publicIPRefreshInterval
    }

    private func fetchPublicIPAndLocation() {
        lastPublicIPFetch = Date()

        // Use an HTTPS endpoint: the app is sandboxed and App Transport
        // Security blocks cleartext HTTP, which previously caused this request
        // to fail silently. ipwho.is requires no API key and returns geo data.
        guard let url = URL(string: "https://ipwho.is/?fields=ip,city,region,country,success") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            // ipwho.is signals failures via "success": false rather than HTTP status.
            if let success = json["success"] as? Bool, success == false { return }

            self.cachedPublicIP = json["ip"] as? String
            let city = json["city"] as? String ?? ""
            let region = json["region"] as? String ?? ""
            let country = json["country"] as? String ?? ""
            let parts = [city, region, country].filter { !$0.isEmpty }
            self.cachedIPLocation = parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
        task.resume()
    }
}
