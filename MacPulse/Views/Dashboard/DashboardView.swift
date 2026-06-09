import SwiftUI
import UniformTypeIdentifiers
import MacPulseShared

struct CardContainer<Content: View>: View {
    let title: LocalizedStringKey
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
    @State private var draggingCard: CardType?
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                systemInfoHeader

                MasonryLayout(columns: 2, spacing: 16) {
                    ForEach(viewModel.visibleCards) { card in
                        cardView(for: card)
                            .opacity(draggingCard == card ? 0.4 : 1.0)
                            .onDrag {
                                draggingCard = card
                                return NSItemProvider(object: card.rawValue as NSString)
                            }
                            .onDrop(of: [.text], delegate: CardDropDelegate(
                                card: card,
                                viewModel: viewModel,
                                draggingCard: $draggingCard
                            ))
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(.background)
    }

    @ViewBuilder
    private func cardView(for card: CardType) -> some View {
        switch card {
        case .cpu:
            CPUCardView(
                data: viewModel.snapshot.cpu,
                thermal: viewModel.snapshot.thermal,
                history: viewModel.cpuHistory,
                useFahrenheit: viewModel.useFahrenheit
            )
        case .memory:
            MemoryCardView(
                data: viewModel.snapshot.memory,
                history: viewModel.memoryHistory
            )
        case .gpu:
            GPUCardView(
                data: viewModel.snapshot.gpu,
                thermal: viewModel.snapshot.thermal,
                useFahrenheit: viewModel.useFahrenheit
            )
        case .disk:
            DiskCardView(disks: viewModel.snapshot.disks)
        case .network:
            NetworkCardView(
                data: viewModel.snapshot.network,
                downloadHistory: viewModel.downloadHistory,
                uploadHistory: viewModel.uploadHistory
            )
        case .battery:
            if let battery = viewModel.snapshot.battery {
                BatteryCardView(
                    data: battery,
                    useFahrenheit: viewModel.useFahrenheit
                )
            }
        }
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
                        Label(
                            "Up \(Formatters.duration(info.uptime, locale: locale))",
                            systemImage: "clock"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct CardDropDelegate: DropDelegate {
    let card: CardType
    let viewModel: DashboardViewModel
    @Binding var draggingCard: CardType?

    func performDrop(info: DropInfo) -> Bool {
        draggingCard = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let source = draggingCard, source != card else { return }
        viewModel.moveCard(from: source, to: card)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        draggingCard != nil
    }
}
