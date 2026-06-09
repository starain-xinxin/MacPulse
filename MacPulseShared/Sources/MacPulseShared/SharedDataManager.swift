import Foundation

public final class SharedDataManager: Sendable {
    private let containerURL: URL?
    private let suiteName = "group.starain.MacPulse"
    private let preferencesLock = NSLock()

    private struct SharedPreferences: Codable {
        var appLanguage: String
        var refreshSettings: ModuleRefreshSettings

        static let `default` = SharedPreferences(
            appLanguage: AppLanguage.system.rawValue,
            refreshSettings: .default
        )
    }

    public init() {
        containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        )
    }

    public func writeSnapshot(_ snapshot: SystemSnapshot) throws {
        guard let url = containerURL?.appendingPathComponent("snapshot.json") else { return }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    public func readSnapshot() -> SystemSnapshot? {
        guard let url = containerURL?.appendingPathComponent("snapshot.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SystemSnapshot.self, from: data)
    }

    public var lastUpdateTimestamp: Date? {
        readSnapshot()?.timestamp
    }

    public var sharedRefreshSettings: ModuleRefreshSettings {
        readPreferences().refreshSettings.normalized
    }

    public func setSharedRefreshSettings(_ settings: ModuleRefreshSettings) throws {
        try updatePreferences { preferences in
            preferences.refreshSettings = settings.normalized
        }
    }

    public var sharedAppLanguage: AppLanguage {
        AppLanguage(rawValue: readPreferences().appLanguage) ?? .system
    }

    public func setSharedAppLanguage(_ language: AppLanguage) throws {
        try updatePreferences { preferences in
            preferences.appLanguage = language.rawValue
        }
    }

    private var preferencesURL: URL? {
        containerURL?.appendingPathComponent("preferences.json")
    }

    private func readPreferences() -> SharedPreferences {
        preferencesLock.withLock {
            guard let url = preferencesURL,
                  let data = try? Data(contentsOf: url),
                  let preferences = try? JSONDecoder().decode(SharedPreferences.self, from: data)
            else {
                return .default
            }
            return preferences
        }
    }

    private func updatePreferences(
        _ update: (inout SharedPreferences) -> Void
    ) throws {
        try preferencesLock.withLock {
            guard let url = preferencesURL else { return }
            var preferences: SharedPreferences
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(SharedPreferences.self, from: data) {
                preferences = decoded
            } else {
                preferences = .default
            }
            update(&preferences)
            let data = try JSONEncoder().encode(preferences)
            try data.write(to: url, options: .atomic)
        }
    }
}
