import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english
    case simplifiedChinese

    public static let preferenceKey = "appLanguage"

    public var id: String { rawValue }

    public var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        }
    }

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: "group.starain.MacPulse") ?? .standard
    }
}
