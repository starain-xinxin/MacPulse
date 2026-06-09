import Foundation
import Darwin
import MacPulseShared

final class ProcessMonitor: MonitorService, @unchecked Sendable {
    private struct RawSample {
        let processID: pid_t
        let name: String
        let totalCPUTime: UInt64
        let residentMemory: UInt64
    }

    private let resultLimit: Int
    nonisolated(unsafe) private var previousCPUTime: [pid_t: UInt64] = [:]
    nonisolated(unsafe) private var previousTimestamp: UInt64?

    init(resultLimit: Int = 5) {
        self.resultLimit = resultLimit
    }

    nonisolated func fetch() -> ProcessData {
        let timestamp = DispatchTime.now().uptimeNanoseconds
        let samples = collectSamples()
        let elapsed = previousTimestamp.map { Double(timestamp - $0) / 1_000_000_000 }
        let logicalCoreCount = Double(ProcessInfo.processInfo.activeProcessorCount)

        let metrics = samples.map { sample in
            let cpuUsage: Double
            if let elapsed, elapsed > 0,
               let previous = previousCPUTime[sample.processID],
               sample.totalCPUTime >= previous {
                let cpuDelta = Double(sample.totalCPUTime - previous) / 1_000_000_000
                cpuUsage = min(max(cpuDelta / elapsed, 0), logicalCoreCount)
            } else {
                cpuUsage = 0
            }

            return ProcessMetric(
                processID: sample.processID,
                name: sample.name,
                cpuUsage: cpuUsage,
                memoryBytes: sample.residentMemory
            )
        }

        previousCPUTime = Dictionary(
            uniqueKeysWithValues: samples.map { ($0.processID, $0.totalCPUTime) }
        )
        previousTimestamp = timestamp

        return Self.ranked(metrics, limit: resultLimit)
    }

    nonisolated static func ranked(_ metrics: [ProcessMetric], limit: Int) -> ProcessData {
        let topCPU = metrics
            .filter { $0.cpuUsage > 0.0001 }
            .sorted {
                if $0.cpuUsage == $1.cpuUsage {
                    return $0.memoryBytes > $1.memoryBytes
                }
                return $0.cpuUsage > $1.cpuUsage
            }
            .prefix(limit)

        let topMemory = metrics
            .filter { $0.memoryBytes > 0 }
            .sorted {
                if $0.memoryBytes == $1.memoryBytes {
                    return $0.cpuUsage > $1.cpuUsage
                }
                return $0.memoryBytes > $1.memoryBytes
            }
            .prefix(limit)

        return ProcessData(
            topCPU: Array(topCPU),
            topMemory: Array(topMemory)
        )
    }

    nonisolated private func collectSamples() -> [RawSample] {
        let estimatedCount = proc_listallpids(nil, 0)
        guard estimatedCount > 0 else { return [] }

        var processIDs = [pid_t](
            repeating: 0,
            count: Int(estimatedCount) + 32
        )
        let actualCount = processIDs.withUnsafeMutableBytes { buffer in
            proc_listallpids(buffer.baseAddress, Int32(buffer.count))
        }
        guard actualCount > 0 else { return [] }

        return processIDs.prefix(Int(actualCount)).compactMap { processID in
            guard processID > 0 else { return nil }

            var taskInfo = proc_taskinfo()
            let taskInfoSize = MemoryLayout<proc_taskinfo>.stride
            let bytesRead = withUnsafeMutablePointer(to: &taskInfo) { pointer in
                proc_pidinfo(
                    processID,
                    PROC_PIDTASKINFO,
                    0,
                    pointer,
                    Int32(taskInfoSize)
                )
            }
            guard bytesRead == taskInfoSize else { return nil }

            var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            let nameLength = nameBuffer.withUnsafeMutableBytes { buffer in
                proc_name(processID, buffer.baseAddress, UInt32(buffer.count))
            }
            guard nameLength > 0 else { return nil }

            return RawSample(
                processID: processID,
                name: String(cString: nameBuffer),
                totalCPUTime: taskInfo.pti_total_user + taskInfo.pti_total_system,
                residentMemory: taskInfo.pti_resident_size
            )
        }
    }
}
