import SwiftUI
import MacPulseShared

struct MenuBarView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable private var updateChecker = UpdateChecker.shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MacPulse")
                    .font(.headline)
                if updateChecker.availableUpdate != nil {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                        .imageScale(.small)
                }
            }
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
                        value: String(
                            format: String(localized: "%@ free", locale: locale),
                            Formatters.byteCount(disk.freeBytes)
                        )
                    )
                }
            }

            Divider()

            if updateChecker.availableUpdate != nil {
                Button {
                    updateChecker.openReleasePage()
                } label: {
                    Label("Download Update", systemImage: "arrow.down.circle.fill")
                }
            }

            Button("Open MacPulse") {
                openWindow(id: AppWindow.dashboardID)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            SettingsLink {
                Text("Settings...")
            }

            Button("Quit MacPulse") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 260)
    }

    private func menuRow(
        icon: String,
        label: LocalizedStringKey,
        value: String
    ) -> some View {
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
