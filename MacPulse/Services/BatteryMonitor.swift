import Foundation
import IOKit.ps
import MacPulseShared

struct BatteryMonitor: MonitorService {
    nonisolated func fetch() -> BatteryData? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sourceList = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let source = sourceList.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?
                .takeUnretainedValue() as? [String: Any]
        else { return nil }

        let currentCap = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
        let powerSource = desc[kIOPSPowerSourceStateKey as String] as? String
        let isPluggedIn = powerSource == kIOPSACPowerValue as String

        let timeToEmpty = desc[kIOPSTimeToEmptyKey as String] as? Int
        let timeToFull = desc[kIOPSTimeToFullChargeKey as String] as? Int

        let chargeLevel = maxCap > 0 ? Double(currentCap) / Double(maxCap) : 0

        // Get detailed battery info from IOKit registry
        let details = fetchBatteryDetails()

        return BatteryData(
            chargeLevel: chargeLevel,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            cycleCount: details?.cycleCount ?? 0,
            healthPercentage: details.map {
                $0.designCapacity > 0 ? Double($0.maxCapacity) / Double($0.designCapacity) : 1.0
            } ?? 1.0,
            maxCapacity: details?.maxCapacity ?? maxCap,
            designCapacity: details?.designCapacity ?? maxCap,
            temperature: details?.temperature,
            timeToEmpty: timeToEmpty.flatMap { $0 > 0 ? TimeInterval($0 * 60) : nil },
            timeToFull: timeToFull.flatMap { $0 > 0 ? TimeInterval($0 * 60) : nil }
        )
    }

    private func fetchBatteryDetails() -> (cycleCount: Int, designCapacity: Int, maxCapacity: Int, temperature: Double)? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else { return nil }

        let cycleCount = dict["CycleCount"] as? Int ?? 0
        let designCap = dict["DesignCapacity"] as? Int ?? 0
        let maxCap = dict["MaxCapacity"] as? Int ?? 0
        let tempRaw = dict["Temperature"] as? Int ?? 0
        let temperature = Double(tempRaw) / 100.0

        return (cycleCount, designCap, maxCap, temperature)
    }
}
