import SwiftUI
import MacPulseShared

@Observable
@MainActor
final class DashboardViewModel {
    let monitor = SystemMonitor()

    var snapshot: SystemSnapshot { monitor.snapshot }
    var cpuHistory: [Double] { monitor.cpuHistory }
    var memoryHistory: [Double] { monitor.memoryHistory }
    var downloadHistory: [UInt64] { monitor.downloadHistory }
    var uploadHistory: [UInt64] { monitor.uploadHistory }

    var cardOrder: [CardType] {
        didSet { saveCardOrder() }
    }

    var useFahrenheit: Bool {
        UserDefaults.standard.string(forKey: "temperatureUnit") == TemperatureUnit.fahrenheit.rawValue
    }

    /// Cards that should actually be displayed (e.g. hide battery if not present)
    var visibleCards: [CardType] {
        cardOrder.filter { card in
            if card == .battery { return snapshot.battery != nil }
            return true
        }
    }

    init() {
        cardOrder = Self.loadCardOrder()
        monitor.start()
    }

    func moveCard(from source: CardType, to target: CardType) {
        guard let fromIndex = cardOrder.firstIndex(of: source),
              let toIndex = cardOrder.firstIndex(of: target),
              fromIndex != toIndex
        else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOrder.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    private func saveCardOrder() {
        if let data = try? JSONEncoder().encode(cardOrder) {
            UserDefaults.standard.set(data, forKey: "cardOrder")
        }
    }

    private static func loadCardOrder() -> [CardType] {
        guard let data = UserDefaults.standard.data(forKey: "cardOrder"),
              let order = try? JSONDecoder().decode([CardType].self, from: data),
              Set(order) == Set(CardType.defaultOrder)
        else { return CardType.defaultOrder }
        return order
    }
}
