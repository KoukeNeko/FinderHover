//
//  UpdateChecker.swift
//  FinderHover
//
//  Service for checking app updates from GitHub releases
//

import Foundation
import SwiftUI
import Combine

// MARK: - GitHub Release Model
struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let publishedAt: String
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case body
    }
}

// MARK: - Update Status
enum UpdateStatus: Equatable {
    case unknown
    case checking
    case upToDate
    case updateAvailable(version: String, url: String)
    case error(String)

    var isUpdateAvailable: Bool {
        if case .updateAvailable = self {
            return true
        }
        return false
    }
}

// MARK: - Update Checker Service
@MainActor
class UpdateChecker: ObservableObject {
    @Published var updateStatus: UpdateStatus = .unknown
    @Published var isChecking = false

    private let repoOwner = "KoukeNeko"
    private let repoName = "FinderHover"
    private let cacheKey = "lastUpdateCheck"
    private let cacheIntervalSeconds: TimeInterval = 3600 // Check at most once per hour

    // Get current app version
    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    init() {
        // Load cached status on initialization
        loadCachedStatus()
    }

    // Check for updates
    func checkForUpdates(force: Bool = false) async {
        // Prevent duplicate checks
        guard !isChecking else { return }

        // Check cache if not forced
        if !force && !shouldCheckForUpdates() {
            return
        }

        isChecking = true
        updateStatus = .checking

        // Use /releases endpoint to get all releases (including prereleases)
        // then take the first one (most recent)
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            updateStatus = .error("Invalid URL")
            isChecking = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                updateStatus = .error("Invalid response")
                isChecking = false
                return
            }

            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let releases = try decoder.decode([GitHubRelease].self, from: data)

                // Get the first release (most recent)
                guard let latestRelease = releases.first else {
                    updateStatus = .error("No releases found")
                    isChecking = false
                    return
                }

                // Compare versions
                let latestVersion = latestRelease.tagName.replacingOccurrences(of: "v", with: "")
                if compareVersions(latestVersion, currentVersion) == .orderedDescending {
                    updateStatus = .updateAvailable(version: latestVersion, url: latestRelease.htmlUrl)
                } else {
                    updateStatus = .upToDate
                }

                // Cache the result
                cacheUpdateCheck()
            } else {
                updateStatus = .error("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            updateStatus = .error(error.localizedDescription)
        }

        isChecking = false
    }

    // Compare two version strings (e.g., "1.1.4" vs "1.1.3")
    private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(v1Components.count, v2Components.count)

        for i in 0..<maxLength {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0

            if v1Value > v2Value {
                return .orderedDescending
            } else if v1Value < v2Value {
                return .orderedAscending
            }
        }

        return .orderedSame
    }

    // Check if we should perform an update check (based on cache interval)
    private func shouldCheckForUpdates() -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: cacheKey) as? Date else {
            return true
        }

        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
        return timeSinceLastCheck >= cacheIntervalSeconds
    }

    // Cache the update check timestamp
    private func cacheUpdateCheck() {
        UserDefaults.standard.set(Date(), forKey: cacheKey)
    }

    // Load cached status (if available)
    private func loadCachedStatus() {
        // On init, we just set unknown status
        // The UI will trigger a check when About tab is opened
        updateStatus = .unknown
    }

    // Open download URL in browser
    func openDownloadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
