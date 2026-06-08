import Foundation

public final class SharedDataManager: Sendable {
    private let containerURL: URL?
    private let suiteName = "group.starain.MacPulse"

    public init() {
        containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        )
    }

    public func writeSnapshot(_ snapshot: SystemSnapshot) throws {
        guard let url = containerURL?.appendingPathComponent("snapshot.json") else { return }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)

        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(Date().timeIntervalSince1970, forKey: "lastUpdate")
    }

    public func readSnapshot() -> SystemSnapshot? {
        guard let url = containerURL?.appendingPathComponent("snapshot.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SystemSnapshot.self, from: data)
    }

    public var lastUpdateTimestamp: Date? {
        let defaults = UserDefaults(suiteName: suiteName)
        guard let ts = defaults?.double(forKey: "lastUpdate"), ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    // MARK: Shared polling interval

    /// The polling interval (seconds) shared between the app and widgets. The
    /// widget's configuration writes here; the running app reads it each poll
    /// and reconciles its timer, so changing the rate from either side keeps
    /// both in sync. Returns nil if never set.
    public var sharedPollingInterval: TimeInterval? {
        let defaults = UserDefaults(suiteName: suiteName)
        guard let v = defaults?.double(forKey: "pollingInterval"), v > 0 else { return nil }
        return v
    }

    public func setSharedPollingInterval(_ interval: TimeInterval) {
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(interval, forKey: "pollingInterval")
    }
}
