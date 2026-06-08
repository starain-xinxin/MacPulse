import Foundation
import Darwin
import MacPulseShared

final class CPUMonitor: MonitorService, @unchecked Sendable {
    private var previousTicks: [CPUTicks] = []

    struct CPUTicks {
        var user: UInt64
        var system: UInt64
        var idle: UInt64
        var nice: UInt64

        var total: UInt64 { user + system + idle + nice }
    }

    nonisolated(unsafe) private var _previousTicks: [CPUTicks] = []

    func fetch() -> CPUData {
        let currentTicks = fetchCPUTicks()
        defer { _previousTicks = currentTicks }

        let coreCount = Int(ProcessInfo.processInfo.activeProcessorCount)
        let physicalCores = getPhysicalCoreCount()

        guard !_previousTicks.isEmpty, _previousTicks.count == currentTicks.count else {
            return CPUData(
                coreCount: physicalCores,
                logicalCoreCount: coreCount
            )
        }

        var totalUser: Double = 0
        var totalSystem: Double = 0
        var totalIdle: Double = 0
        var coreUsages: [CPUData.CoreUsage] = []

        for i in 0..<currentTicks.count {
            let prev = _previousTicks[i]
            let curr = currentTicks[i]

            let userDelta = Double(curr.user - prev.user)
            let systemDelta = Double(curr.system - prev.system)
            let idleDelta = Double(curr.idle - prev.idle)
            let niceDelta = Double(curr.nice - prev.nice)
            let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

            guard totalDelta > 0 else {
                coreUsages.append(CPUData.CoreUsage(coreIndex: i, usage: 0))
                continue
            }

            let coreUsage = (userDelta + systemDelta + niceDelta) / totalDelta
            coreUsages.append(CPUData.CoreUsage(coreIndex: i, usage: coreUsage))

            totalUser += userDelta
            totalSystem += systemDelta
            totalIdle += idleDelta
        }

        let grandTotal = totalUser + totalSystem + totalIdle
        let overallUsage = grandTotal > 0 ? (totalUser + totalSystem) / grandTotal : 0

        return CPUData(
            overallUsage: overallUsage,
            userUsage: grandTotal > 0 ? totalUser / grandTotal : 0,
            systemUsage: grandTotal > 0 ? totalSystem / grandTotal : 0,
            idleUsage: grandTotal > 0 ? totalIdle / grandTotal : 1,
            coreUsages: coreUsages,
            coreCount: physicalCores,
            logicalCoreCount: coreCount
        )
    }

    private func fetchCPUTicks() -> [CPUTicks] {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo else { return [] }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: info),
                vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.stride)
            )
        }

        var ticks: [CPUTicks] = []
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            ticks.append(CPUTicks(
                user: UInt64(info[offset + Int(CPU_STATE_USER)]),
                system: UInt64(info[offset + Int(CPU_STATE_SYSTEM)]),
                idle: UInt64(info[offset + Int(CPU_STATE_IDLE)]),
                nice: UInt64(info[offset + Int(CPU_STATE_NICE)])
            ))
        }
        return ticks
    }

    private func getPhysicalCoreCount() -> Int {
        var count: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.physicalcpu", &count, &size, nil, 0)
        return Int(count)
    }
}
