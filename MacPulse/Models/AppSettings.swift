import SwiftUI
import AppKit

enum AppWindow {
    static let dashboardID = "dashboard"
}

@MainActor
enum DockVisibilityController {
    static let preferenceKey = "showDockIcon"

    static func applySavedPreference() {
        apply(showDockIcon: UserDefaults.standard.bool(forKey: preferenceKey))
    }

    static func apply(showDockIcon: Bool) {
        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        NSApplication.shared.setActivationPolicy(policy)
    }
}

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
}

enum PollingInterval: Double, CaseIterable {
    case one = 1.0
    case two = 2.0
    case five = 5.0
    case ten = 10.0

    var label: String {
        switch self {
        case .one: return "1s"
        case .two: return "2s"
        case .five: return "5s"
        case .ten: return "10s"
        }
    }
}
