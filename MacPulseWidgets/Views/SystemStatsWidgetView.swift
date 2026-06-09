import SwiftUI
import WidgetKit
import MacPulseShared

/// Medium widget: CPU and RAM load rings, a compact CPU/RAM breakdown, and a
/// disk usage bar.
struct SystemStatsWidgetView: View {
    let entry: SystemStatsEntry

    private var memoryRatio: Double {
        entry.memory.totalBytes > 0
            ? Double(entry.memory.usedBytes) / Double(entry.memory.totalBytes)
            : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            title

            HStack(spacing: 16) {
                HStack(spacing: 10) {
                    ring("CPU", entry.cpu.overallUsage, .blue, icon: "cpu")
                    ring("RAM", memoryRatio, .green, icon: "memorychip")
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        infoCell("person.fill", "User", percent(entry.cpu.userUsage), .blue)
                        infoCell("memorychip.fill", "Used", bytes(entry.memory.usedBytes), .green)
                        infoCell("lock.fill", "Wired", bytes(entry.memory.wiredBytes), .green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        infoCell("gearshape.fill", "System", percent(entry.cpu.systemUsage), .blue)
                        infoCell("bolt.fill", "Active", bytes(entry.memory.activeBytes), .green)
                        infoCell("rectangle.compress.vertical", "Comp", bytes(entry.memory.compressedBytes), .green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let disk = entry.systemDisk {
                diskBar(disk)
            }
        }
    }

    private var title: some View {
        HStack(spacing: 5) {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(.blue)
            Text("CPU · RAM · Disk")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
        }
    }

    private func ring(
        _ label: LocalizedStringKey,
        _ value: Double,
        _ color: Color,
        icon: String
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundStyle(color)
                    Text(String(format: "%.0f%%", value * 100))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 62, height: 62)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    /// Icon + label stacked tight to the value, so the number sits right next
    /// to its description rather than pushed to the far edge.
    private func infoCell(
        _ icon: String,
        _ label: LocalizedStringKey,
        _ value: String,
        _ tint: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(tint)
                .frame(width: 13)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
    }

    private func diskBar(_ disk: DiskData) -> some View {
        let ratio = disk.totalBytes > 0
            ? min(max(Double(disk.usedBytes) / Double(disk.totalBytes), 0), 1)
            : 0

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
                    .frame(width: 13)
                Text("Disk")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(disk.volumeName.isEmpty ? disk.mountPoint : disk.volumeName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
                Text("\(bytesFile(disk.usedBytes)) / \(bytesFile(disk.totalBytes))")
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
            }

            ProgressView(value: ratio)
                .progressViewStyle(.linear)
                .tint(.orange)
                .controlSize(.small)
        }
    }

    private func percent(_ v: Double) -> String { String(format: "%.0f%%", v * 100) }

    private func bytes(_ b: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(b), countStyle: .memory)
    }

    private func bytesFile(_ b: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(b), countStyle: .file)
    }
}
