import Foundation
import IOKit
import MacPulseShared

final class GPUMonitor: @unchecked Sendable {
    private var subscription: CFDictionary?
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

        subscription = IOReportCreateSubscription(
            nil,
            channels as! CFMutableDictionary,
            nil,
            0,
            nil
        )
    }

    private func fetchGPUName() {
        if let chip = sysctlString("machdep.cpu.brand_string") {
            let components = chip.components(separatedBy: " ")
            if let mIndex = components.firstIndex(where: { $0.hasPrefix("M") }) {
                gpuName = "Apple \(components[mIndex]) GPU"
                return
            }
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
}

extension GPUMonitor: MonitorService {
    func fetch() -> GPUData {
        guard let subscription else {
            return GPUData(activeUsage: 0, gpuName: gpuName)
        }

        guard let currentSample = IOReportCreateSamples(
            subscription,
            subscription as! CFMutableDictionary,
            nil
        ) else {
            return GPUData(activeUsage: 0, gpuName: gpuName)
        }

        defer { previousSample = currentSample }

        guard let prevSample = previousSample else {
            return GPUData(activeUsage: 0, gpuName: gpuName)
        }

        guard let delta = IOReportCreateSamplesDelta(prevSample, currentSample, nil) else {
            return GPUData(activeUsage: 0, gpuName: gpuName)
        }

        var totalBusy: UInt64 = 0
        var totalResidency: UInt64 = 0

        IOReportIterate(delta) { channel in
            let group = IOReportChannelGetGroup(channel) as String? ?? ""
            guard group == "GPU Stats" else { return 0 }

            let stateCount = IOReportStateGetCount(channel)
            for i in 0..<Int32(stateCount) {
                let residency = IOReportStateGetResidency(channel, i)
                let name = IOReportStateGetNameForIndex(channel, i) as String? ?? ""
                totalResidency += residency
                if name != "Off" && name != "Idle" {
                    totalBusy += residency
                }
            }
            return 0
        }

        let usage = totalResidency > 0 ? Double(totalBusy) / Double(totalResidency) : 0

        return GPUData(activeUsage: min(usage, 1.0), gpuName: gpuName)
    }
}
