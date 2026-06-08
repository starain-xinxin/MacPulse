import SwiftUI
import WidgetKit
import MacPulseShared

/// Medium widget: CPU and RAM load rings + a breakdown of CPU (User/System)
/// and memory (Used/Active/Wired/Compressed) plus system disk free space.
struct SystemStatsWidgetView: View {
    let entry: SystemStatsEntry

    private var memoryRatio: Double {
        entry.memory.totalBytes > 0
            ? Double(entry.memory.usedBytes) / Double(entry.memory.totalBytes)
            : 0
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 10) {
                ring("CPU", entry.cpu.overallUsage, .blue, icon: "cpu")
                ring("RAM", memoryRatio, .green, icon: "memorychip")
            }
            .frame(width: 78)

            VStack(alignment: .leading, spacing: 4) {
                infoRow("person.fill", "User", percent(entry.cpu.userUsage), .blue)
                infoRow("gearshape.fill", "System", percent(entry.cpu.systemUsage), .blue)
                Divider().padding(.vertical, 1)
                infoRow("memorychip.fill", "Used", bytes(entry.memory.usedBytes), .green)
                infoRow("bolt.fill", "Active", bytes(entry.memory.activeBytes), .green)
                infoRow("lock.fill", "Wired", bytes(entry.memory.wiredBytes), .green)
                infoRow("rectangle.compress.vertical", "Comp", bytes(entry.memory.compressedBytes), .green)
                if let disk = entry.systemDisk {
                    Divider().padding(.vertical, 1)
                    infoRow("internaldrive.fill", "Disk free", diskFree(disk.freeBytes), .orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func ring(_ label: String, _ value: Double, _ color: Color, icon: String) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(color)
                    Text(String(format: "%.0f%%", value * 100))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 60, height: 60)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func infoRow(_ icon: String, _ label: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(tint)
                .frame(width: 13)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private func percent(_ v: Double) -> String { String(format: "%.0f%%", v * 100) }

    private func bytes(_ b: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(b), countStyle: .memory)
    }

    private func diskFree(_ b: UInt64) -> String {
        String(format: "%.0f GB", Double(b) / 1_000_000_000)
    }
}
