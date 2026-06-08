import SwiftUI
import MacPulseShared

struct MenuBarView: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MacPulse")
                .font(.headline)
                .padding(.bottom, 4)

            Group {
                menuRow(
                    icon: "cpu",
                    label: "CPU",
                    value: Formatters.percentage(viewModel.snapshot.cpu.overallUsage)
                )

                menuRow(
                    icon: "memorychip",
                    label: "Memory",
                    value: "\(Formatters.byteCount(viewModel.snapshot.memory.usedBytes)) / \(Formatters.byteCount(viewModel.snapshot.memory.totalBytes))"
                )

                if let battery = viewModel.snapshot.battery {
                    menuRow(
                        icon: "battery.100percent",
                        label: "Battery",
                        value: Formatters.percentageInt(battery.chargeLevel)
                    )
                }

                menuRow(
                    icon: "arrow.down.circle",
                    label: "Download",
                    value: Formatters.bytesPerSecond(viewModel.snapshot.network.downloadBytesPerSecond)
                )

                menuRow(
                    icon: "arrow.up.circle",
                    label: "Upload",
                    value: Formatters.bytesPerSecond(viewModel.snapshot.network.uploadBytesPerSecond)
                )

                if !viewModel.snapshot.disks.isEmpty {
                    let disk = viewModel.snapshot.disks[0]
                    menuRow(
                        icon: "internaldrive",
                        label: "Disk",
                        value: "\(Formatters.byteCount(disk.freeBytes)) free"
                    )
                }
            }

            Divider()

            Button("Quit MacPulse") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 260)
    }

    private func menuRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}
