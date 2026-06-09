import Foundation
import IOKit
import MacPulseShared

final class GPUMonitor: @unchecked Sendable {
    private var subscription: CFDictionary?
    private var channels: CFMutableDictionary?
    private var previousSample: CFDictionary?
    private var gpuName: String = ""

    init() {
        setupSubscription()
        fetchGPUName()
    }

    private func setupSubscription() {
        guard let channels = IOReportCopyChannelsInGroup(
            "GPU Stats" as CFString, nil, 0, 0, 0
        ) else { return }

        guard let mutableChannels = CFDictionaryCreateMutableCopy(
            kCFAllocatorDefault,
            0,
            channels
        ) else { return }

        self.channels = mutableChannels
        subscription = IOReportCreateSubscription(
            nil,
            mutableChannels,
            nil,
            0,
            nil
        )
    }

    private func fetchGPUName() {
        if let chip = sysctlString("machdep.cpu.brand_string") {
            gpuName = chip.hasPrefix("Apple ") ? "\(chip) GPU" : "Apple \(chip) GPU"
            return
        }
        gpuName = "Apple GPU"
    }

    private func sysctlString(_ name: String) -> String? {
        var size: size_t = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    private func fetchAcceleratorUsage() -> Double? {
        guard let matching = IOServiceMatching("IOAccelerator") else { return nil }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var usages: [Double] = []
        var service = IOIteratorNext(iterator)

        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            guard let value = IORegistryEntryCreateCFProperty(
                service,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue(),
                  let statistics = value as? [String: Any],
                  let usage = Self.utilization(from: statistics)
            else { continue }

            usages.append(usage)
        }

        return usages.max()
    }

    static func utilization(from statistics: [String: Any]) -> Double? {
        let keys = [
            "Device Utilization %",
            "GPU Activity(%)",
            "Renderer Utilization %"
        ]

        for key in keys {
            guard let number = statistics[key] as? NSNumber else { continue }
            return min(max(number.doubleValue / 100, 0), 1)
        }

        return nil
    }

    private func fetchIOReportUsage() -> Double? {
        guard let subscription, let channels else { return nil }

        guard let currentSample = IOReportCreateSamples(
            subscription,
            channels,
            nil
        ) else {
            return nil
        }

        defer { previousSample = currentSample }

        guard let previousSample else { return nil }
        guard let delta = IOReportCreateSamplesDelta(previousSample, currentSample, nil) else {
            return nil
        }

        var totalBusy: UInt64 = 0
        var totalResidency: UInt64 = 0
        var foundPerformanceStates = false

        IOReportIterate(delta) { channel in
            let group = IOReportChannelGetGroup(channel) as String? ?? ""
            let subgroup = IOReportChannelGetSubGroup(channel) as String? ?? ""
            let name = IOReportChannelGetChannelName(channel) as String? ?? ""

            guard group == "GPU Stats",
                  subgroup == "GPU Performance States" || name == "GPUPH"
            else { return 0 }

            let stateCount = IOReportStateGetCount(channel)
            guard stateCount > 0 else { return 0 }

            foundPerformanceStates = true

            for index in 0..<Int32(stateCount) {
                let residency = IOReportStateGetResidency(channel, index)
                let stateName = (IOReportStateGetNameForIndex(channel, index) as String? ?? "")
                    .lowercased()
                let isInactive = index == 0 || stateName == "off" || stateName == "idle"

                totalResidency += residency
                if !isInactive {
                    totalBusy += residency
                }
            }

            return 0
        }

        guard foundPerformanceStates, totalResidency > 0 else { return nil }
        return min(max(Double(totalBusy) / Double(totalResidency), 0), 1)
    }
}

extension GPUMonitor: MonitorService {
    func fetch() -> GPUData {
        let usage = fetchAcceleratorUsage() ?? fetchIOReportUsage() ?? 0
        return GPUData(activeUsage: usage, gpuName: gpuName)
    }
}
