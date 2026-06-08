import Foundation
import IOKit
import MacPulseShared

final class ThermalMonitor: @unchecked Sendable {
    private var subscription: CFDictionary?
    private var previousSample: CFDictionary?

    init() {
        setupSubscription()
    }

    private func setupSubscription() {
        guard let channels = IOReportCopyChannelsInGroup(
            "Energy Model" as CFString, nil, 0, 0, 0
        ) else { return }

        subscription = IOReportCreateSubscription(
            nil,
            channels as! CFMutableDictionary,
            nil,
            0,
            nil
        )
    }
}

extension ThermalMonitor: MonitorService {
    func fetch() -> ThermalData {
        let thermalState = ProcessInfo.processInfo.thermalState
        let pressure: ThermalData.ThermalPressureLevel = switch thermalState {
        case .nominal: .nominal
        case .fair: .fair
        case .serious: .serious
        case .critical: .critical
        @unknown default: .nominal
        }

        let cpuTemp = fetchTemperatureFromBattery()

        return ThermalData(
            cpuTemperature: cpuTemp,
            gpuTemperature: nil,
            thermalPressure: pressure
        )
    }

    private func fetchTemperatureFromBattery() -> Double? {
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

        if let temp = dict["Temperature"] as? Int {
            return Double(temp) / 100.0
        }
        return nil
    }
}
