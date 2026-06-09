import Foundation
import AppKit

/// Response from GitHub Releases API
struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let assets: [Asset]
    let publishedAt: String
    let body: String?

    struct Asset: Codable {
        let name: String
        let browserDownloadUrl: String
        let size: Int

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
            case size
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case assets
        case publishedAt = "published_at"
        case body
    }
}

/// Version comparison result
enum VersionComparison {
    case upToDate
    case updateAvailable(GitHubRelease)
    case unknown
}

/// Update checker service
@MainActor
@Observable
final class UpdateChecker {
    static let shared = UpdateChecker()

    var isChecking = false
    var lastCheckDate: Date?
    var availableUpdate: GitHubRelease?
    var errorMessage: String?

    private let repoOwner = "starain-xinxin"
    private let repoName = "MacPulse"
    private let lastCheckKey = "lastUpdateCheckDate"

    private init() {
        loadLastCheckDate()
    }

    /// Check for updates from GitHub Releases API
    func checkForUpdates() async {
        isChecking = true
        errorMessage = nil
        defer { isChecking = false }

        do {
            let release = try await fetchLatestRelease()
            let comparison = compareVersions(current: currentVersion, latest: release.tagName)

            switch comparison {
            case .upToDate:
                availableUpdate = nil
            case .updateAvailable:
                availableUpdate = release
            case .unknown:
                availableUpdate = nil
            }

            lastCheckDate = Date()
            saveLastCheckDate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetch latest release from GitHub API
    private func fetchLatestRelease() async throws -> GitHubRelease {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw UpdateError.noReleaseFound
            }
            throw UpdateError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    /// Compare semantic versions
    private func compareVersions(current: String, latest: String) -> VersionComparison {
        // Strip "v" prefix if present
        let cleanCurrent = current.hasPrefix("v") ? String(current.dropFirst()) : current
        let cleanLatest = latest.hasPrefix("v") ? String(latest.dropFirst()) : latest

        let currentComponents = cleanCurrent.split(separator: ".").compactMap { Int($0) }
        let latestComponents = cleanLatest.split(separator: ".").compactMap { Int($0) }

        guard currentComponents.count >= 2, latestComponents.count >= 2 else {
            return .unknown
        }

        for i in 0..<max(currentComponents.count, latestComponents.count) {
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            let latestValue = i < latestComponents.count ? latestComponents[i] : 0

            if latestValue > currentValue {
                return .updateAvailable(GitHubRelease(
                    tagName: latest,
                    name: latest,
                    htmlUrl: "https://github.com/\(repoOwner)/\(repoName)/releases/tag/\(latest)",
                    assets: [],
                    publishedAt: "",
                    body: nil
                ))
            } else if latestValue < currentValue {
                return .upToDate
            }
        }

        return .upToDate
    }

    /// Get current app version
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Open release page in browser
    func openReleasePage() {
        guard let release = availableUpdate,
              let url = URL(string: release.htmlUrl) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Dismiss the available update notification
    func dismissUpdate() {
        availableUpdate = nil
    }

    // MARK: - Persistence

    private func loadLastCheckDate() {
        if let timestamp = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            lastCheckDate = timestamp
        }
    }

    private func saveLastCheckDate() {
        UserDefaults.standard.set(lastCheckDate, forKey: lastCheckKey)
    }
}

// MARK: - Errors

enum UpdateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noReleaseFound
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GitHub API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noReleaseFound:
            return "No releases found for this repository"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
