import SwiftUI

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
