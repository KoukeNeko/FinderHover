//
//  GitHubService.swift
//  FinderHover
//
//  GitHub API service for fetching contributors
//

import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Contributor Model
struct Contributor: Identifiable, Codable {
    let id: Int
    let login: String
    let avatarUrl: String
    let htmlUrl: String
    let contributions: Int

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case contributions
    }
}

// MARK: - Release Model
struct Release: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let prerelease: Bool
    let draft: Bool
    let publishedAt: String
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case prerelease
        case draft
        case publishedAt = "published_at"
        case body
    }

    var version: String {
        // Remove 'v' prefix if present (e.g., "v1.1.4" -> "1.1.4")
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }
}

// MARK: - Semantic Version
/// SemVer 2.0.0 value type for correct release-precedence comparison.
/// Encodes the rule that a release (1.8.1) outranks any of its prereleases
/// (1.8.1-beta.1), which String.compare(.numeric) gets backwards.
/// Declared internal (not fileprivate) so it can be unit-tested directly.
struct SemanticVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    /// Dot-separated prerelease identifiers; empty for a normal release.
    let prereleaseIdentifiers: [String]

    /// Parses "1.8.1", "1.8.1-beta.1", "v1.8" (missing components default to 0).
    /// Build metadata (after "+") is ignored per SemVer 11.4.
    /// Returns nil if the core version contains no parseable leading number.
    init?(_ raw: String) {
        let trimmed = raw.hasPrefix("v") ? String(raw.dropFirst()) : raw
        let buildSplit = trimmed.split(separator: "+", maxSplits: 1)
        guard let withoutBuild = buildSplit.first else { return nil }

        let prereleaseSplit = withoutBuild.split(separator: "-", maxSplits: 1)
        let core = prereleaseSplit[0]
        let coreComponents = core.split(separator: ".").map { Int($0) }
        guard let firstComponent = coreComponents.first, firstComponent != nil else { return nil }

        self.major = coreComponents.count > 0 ? (coreComponents[0] ?? 0) : 0
        self.minor = coreComponents.count > 1 ? (coreComponents[1] ?? 0) : 0
        self.patch = coreComponents.count > 2 ? (coreComponents[2] ?? 0) : 0

        if prereleaseSplit.count > 1 {
            self.prereleaseIdentifiers = prereleaseSplit[1].split(separator: ".").map(String.init)
        } else {
            self.prereleaseIdentifiers = []
        }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        return Self.comparePrerelease(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers) == .orderedAscending
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        lhs.major == rhs.major && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch && lhs.prereleaseIdentifiers == rhs.prereleaseIdentifiers
    }

    /// SemVer 11.3: a release (no identifiers) has higher precedence than a prerelease.
    /// Numeric identifiers compare numerically, alphanumerics lexically, numeric < alphanumeric.
    private static func comparePrerelease(_ lhs: [String], _ rhs: [String]) -> ComparisonResult {
        if lhs.isEmpty && rhs.isEmpty { return .orderedSame }
        if lhs.isEmpty { return .orderedDescending } // release > prerelease
        if rhs.isEmpty { return .orderedAscending }

        for (lhsItem, rhsItem) in zip(lhs, rhs) {
            let lhsNumber = Int(lhsItem)
            let rhsNumber = Int(rhsItem)
            switch (lhsNumber, rhsNumber) {
            case let (.some(left), .some(right)) where left != right:
                return left < right ? .orderedAscending : .orderedDescending
            case (.some, .none):
                return .orderedAscending // numeric < alphanumeric
            case (.none, .some):
                return .orderedDescending
            case (.none, .none) where lhsItem != rhsItem:
                return lhsItem < rhsItem ? .orderedAscending : .orderedDescending
            default:
                continue
            }
        }
        if lhs.count != rhs.count {
            return lhs.count < rhs.count ? .orderedAscending : .orderedDescending
        }
        return .orderedSame
    }
}

// MARK: - GitHub Service
@MainActor
class GitHubService: ObservableObject {
    @Published var contributors: [Contributor] = []
    @Published var isLoading = false
    @Published var error: String?

    @Published var latestRelease: Release?
    @Published var isCheckingForUpdates = false
    @Published var updateCheckError: String?
    @Published var showUpdateAlert = false

    private let repoOwner = "KoukeNeko"
    private let repoName = "FinderHover"
    private let cacheKey = "cachedContributors"
    private var lastUpdateCheckTime: Date?
    private let updateCheckCooldown: TimeInterval = 5.0 // 5 seconds between checks

    var releasePageUrl: String {
        guard let release = latestRelease else {
            return "https://github.com/\(repoOwner)/\(repoName)/releases"
        }
        return release.htmlUrl
    }

    init() {
        // Load cached contributors on initialization
        loadCachedContributors()
    }

    func fetchContributors() async {
        isLoading = true
        error = nil

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/contributors"
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10 // 10 second timeout

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                error = "Invalid response"
                isLoading = false
                return
            }

            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let fetchedContributors = try decoder.decode([Contributor].self, from: data)
                self.contributors = fetchedContributors

                // Cache the contributors data
                cacheContributors(fetchedContributors)
            } else {
                error = "HTTP \(httpResponse.statusCode)"
            }
        } catch {
            Logger.error("Failed to fetch contributors", error: error, subsystem: .settings)
            self.error = "settings.about.error.network".localized
            // If fetch fails and we have no contributors, try to load from cache
            if contributors.isEmpty {
                loadCachedContributors()
            }
        }

        isLoading = false
    }

    func fetchLatestRelease(includePrereleases: Bool = false) async {
        // Check cooldown period to prevent rate limiting
        if let lastCheck = lastUpdateCheckTime {
            let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
            if timeSinceLastCheck < updateCheckCooldown {
                let remainingTime = Int(ceil(updateCheckCooldown - timeSinceLastCheck))
                updateCheckError = String(format: "settings.about.error.wait".localized, remainingTime)
                return
            }
        }

        isCheckingForUpdates = true
        updateCheckError = nil
        latestRelease = nil
        lastUpdateCheckTime = Date()

        // Use different endpoint based on prerelease preference
        let urlString: String
        if includePrereleases {
            // Get all releases and pick the first one (most recent)
            urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        } else {
            // Get only the latest stable release
            urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        }

        guard let url = URL(string: urlString) else {
            updateCheckError = "settings.about.error.invalidResponse".localized
            isCheckingForUpdates = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                updateCheckError = "settings.about.error.invalidResponse".localized
                isCheckingForUpdates = false
                return
            }

            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()

                if includePrereleases {
                    // Parse array and get first non-draft release
                    let releases = try decoder.decode([Release].self, from: data)
                    let latestByVersion = releases
                        .filter { !$0.draft }
                        .max { lhs, rhs in
                            guard let lhsVersion = SemanticVersion(lhs.version),
                                  let rhsVersion = SemanticVersion(rhs.version) else { return false }
                            return lhsVersion < rhsVersion
                        }
                    if let latestByVersion {
                        self.latestRelease = latestByVersion
                        // Show alert if update is available
                        if self.isUpdateAvailable {
                            self.showUpdateAlert = true
                        }
                    } else {
                        updateCheckError = "settings.about.error.noReleases".localized
                    }
                } else {
                    // Parse single release
                    let release = try decoder.decode(Release.self, from: data)
                    if release.draft {
                        updateCheckError = "settings.about.error.noStableRelease".localized
                    } else {
                        self.latestRelease = release
                        // Show alert if update is available
                        if self.isUpdateAvailable {
                            self.showUpdateAlert = true
                        }
                    }
                }
            } else if httpResponse.statusCode == 404 {
                updateCheckError = "settings.about.error.noReleases".localized
            } else if httpResponse.statusCode == 403 {
                updateCheckError = "settings.about.error.rateLimit".localized
            } else {
                updateCheckError = String(format: "settings.about.error.http".localized, "\(httpResponse.statusCode)")
            }
        } catch {
            Logger.error("Failed to fetch latest release", error: error, subsystem: .settings)
            self.updateCheckError = "settings.about.error.network".localized
        }

        isCheckingForUpdates = false
    }

    var isUpdateAvailable: Bool {
        guard let latestRelease = latestRelease,
              let currentRaw = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let currentVersion = SemanticVersion(currentRaw),
              let latestVersion = SemanticVersion(latestRelease.version) else {
            return false
        }
        return currentVersion < latestVersion
    }

    func openReleasePage() {
        guard let url = URL(string: releasePageUrl) else { return }
        NSWorkspace.shared.open(url)
    }

    private func cacheContributors(_ contributors: [Contributor]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(contributors)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("Failed to cache contributors: \(error)")
        }
    }

    private func loadCachedContributors() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            let cachedContributors = try decoder.decode([Contributor].self, from: data)
            self.contributors = cachedContributors
        } catch {
            print("Failed to load cached contributors: \(error)")
        }
    }
}

// MARK: - Avatar Image Loader
class AvatarImageLoader: ObservableObject {
    @Published var image: NSImage?
    private var url: URL?
    private static let imageCache = NSCache<NSString, NSImage>()

    init(url: URL) {
        self.url = url
        loadImage()
    }

    func loadImage() {
        guard let url = url else { return }

        let cacheKey = url.absoluteString as NSString

        // Check cache first
        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            self.image = cachedImage
            return
        }

        // Download image
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let downloadedImage = NSImage(data: data) else {
                return
            }

            Self.imageCache.setObject(downloadedImage, forKey: cacheKey)

            DispatchQueue.main.async {
                self.image = downloadedImage
            }
        }.resume()
    }
}

// MARK: - Avatar Image View
// Note: AvatarImageView has been moved to SettingsComponents.swift to avoid duplication
