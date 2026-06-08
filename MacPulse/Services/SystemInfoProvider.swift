import Foundation
import MacPulseShared

struct SystemInfoProvider: MonitorService {
    private let cachedInfo: SystemInfoData

    init() {
        let model = Self.sysctlString("hw.model") ?? "Unknown"
        let chip = Self.sysctlString("machdep.cpu.brand_string") ?? "Apple Silicon"
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osString = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        cachedInfo = SystemInfoData(
            modelName: Self.marketingModelName() ?? model,
            modelIdentifier: model,
            chipName: chip,
            osVersion: osString,
            uptime: 0
        )
    }

    func fetch() -> SystemInfoData {
        var info = cachedInfo
        info.uptime = ProcessInfo.processInfo.systemUptime
        return info
    }

    private static func sysctlString(_ name: String) -> String? {
        var size: size_t = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    private static func marketingModelName() -> String? {
        // Try to get the marketing name from IOKit registry
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        if let modelData = IORegistryEntryCreateCFProperty(
            service, "model" as CFString, kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? Data {
            return String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }
        return nil
    }
}
