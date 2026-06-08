import Foundation
import MacPulseShared

struct DiskMonitor: MonitorService {
    nonisolated func fetch() -> [DiskData] {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsInternalKey,
            .volumeIsLocalKey,
            .volumeTypeNameKey,
        ]

        guard let volumeURLs = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(keys),
            options: [.skipHiddenVolumes]
        ) else { return [] }

        var disks: [DiskData] = []
        for url in volumeURLs {
            guard let values = try? url.resourceValues(forKeys: keys) else { continue }

            let isLocal = values.volumeIsLocal ?? false
            guard isLocal else { continue }

            let name = values.volumeName ?? url.lastPathComponent
            let total = values.volumeTotalCapacity.map { UInt64($0) } ?? 0
            let free = values.volumeAvailableCapacityForImportantUsage.map { UInt64($0) } ?? 0
            let fsType = values.volumeTypeName ?? ""

            guard total > 0 else { continue }

            disks.append(DiskData(
                volumeName: name,
                mountPoint: url.path,
                totalBytes: total,
                usedBytes: total - free,
                freeBytes: free,
                fileSystemType: fsType
            ))
        }

        return disks
    }
}
