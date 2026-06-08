import Foundation
import Network
import MacPulseShared
import CoreLocation

final class NetworkMonitorService: @unchecked Sendable {
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.macpulse.network")

    private var currentInterfaceName: String = ""
    private var currentInterfaceType: NetworkData.InterfaceType = .other
    private var isConnected = false

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

    private func shouldRefreshPublicIP() -> Bool {
        guard let last = lastPublicIPFetch else { return true }
        return Date().timeIntervalSince(last) > AppConstants.publicIPRefreshInterval
    }

    private func fetchPublicIPAndLocation() {
        lastPublicIPFetch = Date()

        // Fetch public IP and location from ip-api.com (no key needed)
        guard let url = URL(string: "http://ip-api.com/json/?fields=query,city,regionName,country") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.cachedPublicIP = json["query"] as? String
                let city = json["city"] as? String ?? ""
                let region = json["regionName"] as? String ?? ""
                let country = json["country"] as? String ?? ""
                let parts = [city, region, country].filter { !$0.isEmpty }
                self.cachedIPLocation = parts.joined(separator: ", ")
            }
        }
        task.resume()
    }
}
