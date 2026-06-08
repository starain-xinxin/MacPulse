import SwiftUI
import MacPulseShared

struct DiskCardView: View {
    let disks: [DiskData]

    var body: some View {
        CardContainer(title: "Disk", icon: "internaldrive") {
            ForEach(disks) { disk in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(disk.volumeName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text(disk.fileSystemType)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    SimpleBarView(value: usageRatio(disk), color: diskColor(disk))

                    HStack {
                        Text("\(Formatters.byteCount(disk.usedBytes)) used")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Formatters.byteCount(disk.freeBytes)) free")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                if disk.id != disks.last?.id {
                    Divider()
                }
            }
        }
    }

    private func usageRatio(_ disk: DiskData) -> Double {
        disk.totalBytes > 0 ? Double(disk.usedBytes) / Double(disk.totalBytes) : 0
    }

    private func diskColor(_ disk: DiskData) -> Color {
        let ratio = usageRatio(disk)
        if ratio > 0.9 { return .red }
        if ratio > 0.75 { return .orange }
        return .teal
    }
}
