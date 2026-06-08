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

    var useFahrenheit: Bool {
        UserDefaults.standard.string(forKey: "temperatureUnit") == TemperatureUnit.fahrenheit.rawValue
    }

    init() {
        monitor.start()
    }
}
