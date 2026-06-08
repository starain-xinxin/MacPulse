import Foundation
import Darwin
import MacPulseShared

struct MemoryMonitor: MonitorService {
    nonisolated func fetch() -> MemoryData {
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryData(totalBytes: totalBytes)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize

        let used = active + wired + compressed
        let available = free + inactive

        let swap = fetchSwapUsage()
        let pressure = determinePressure(used: used, total: totalBytes)

        return MemoryData(
            totalBytes: totalBytes,
            usedBytes: used,
            freeBytes: available,
            activeBytes: active,
            inactiveBytes: inactive,
            wiredBytes: wired,
            compressedBytes: compressed,
            pressure: pressure,
            swapUsedBytes: swap.used,
            swapTotalBytes: swap.total
        )
    }

    private func fetchSwapUsage() -> (used: UInt64, total: UInt64) {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let result = sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0)
        guard result == 0 else { return (0, 0) }
        return (UInt64(swapUsage.xsu_used), UInt64(swapUsage.xsu_total))
    }

    private func determinePressure(used: UInt64, total: UInt64) -> MemoryData.MemoryPressure {
        guard total > 0 else { return .nominal }
        let ratio = Double(used) / Double(total)
        if ratio > 0.9 { return .critical }
        if ratio > 0.75 { return .warning }
        return .nominal
    }
}
