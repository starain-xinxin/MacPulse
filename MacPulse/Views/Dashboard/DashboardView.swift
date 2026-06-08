import SwiftUI
import MacPulseShared

struct CardContainer<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)

            content()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    private let columns = [
        GridItem(.flexible(minimum: 280), spacing: 16),
        GridItem(.flexible(minimum: 280), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                systemInfoHeader

                LazyVGrid(columns: columns, spacing: 16) {
                    CPUCardView(
                        data: viewModel.snapshot.cpu,
                        thermal: viewModel.snapshot.thermal,
                        history: viewModel.cpuHistory,
                        useFahrenheit: viewModel.useFahrenheit
                    )

                    MemoryCardView(
                        data: viewModel.snapshot.memory,
                        history: viewModel.memoryHistory
                    )

                    GPUCardView(
                        data: viewModel.snapshot.gpu,
                        thermal: viewModel.snapshot.thermal,
                        useFahrenheit: viewModel.useFahrenheit
                    )

                    DiskCardView(disks: viewModel.snapshot.disks)

                    NetworkCardView(
                        data: viewModel.snapshot.network,
                        downloadHistory: viewModel.downloadHistory,
                        uploadHistory: viewModel.uploadHistory
                    )

                    if let battery = viewModel.snapshot.battery {
                        BatteryCardView(
                            data: battery,
                            useFahrenheit: viewModel.useFahrenheit
                        )
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(.background)
    }

    private var systemInfoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacPulse")
                    .font(.title2)
                    .fontWeight(.bold)
                HStack(spacing: 12) {
                    let info = viewModel.snapshot.systemInfo
                    if !info.modelIdentifier.isEmpty {
                        Label(info.modelIdentifier, systemImage: "laptopcomputer")
                    }
                    if !info.chipName.isEmpty {
                        Label(info.chipName, systemImage: "cpu")
                    }
                    if !info.osVersion.isEmpty {
                        Label(info.osVersion, systemImage: "apple.logo")
                    }
                    if info.uptime > 0 {
                        Label("Up \(Formatters.duration(info.uptime))", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
