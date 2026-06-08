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
}
