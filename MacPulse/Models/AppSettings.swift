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

    var label: LocalizedStringKey {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
}
