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

// MARK: - GitHub Service
@MainActor
class GitHubService: ObservableObject {
    @Published var contributors: [Contributor] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repoOwner = "KoukeNeko"
    private let repoName = "FinderHover"
    private let cacheKey = "cachedContributors"
    private let cacheTimestampKey = "contributorsCacheTimestamp"
    private let cacheExpirationInterval: TimeInterval = 86400 // 24 hours

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
            self.error = error.localizedDescription
            // If fetch fails and we have no contributors, try to load from cache
            if contributors.isEmpty {
                loadCachedContributors()
            }
        }

        isLoading = false
    }

    private func cacheContributors(_ contributors: [Contributor]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(contributors)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
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

    private func isCacheValid() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? TimeInterval else {
            return false
        }
        let cacheAge = Date().timeIntervalSince1970 - timestamp
        return cacheAge < cacheExpirationInterval
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
struct AvatarImageView: View {
    let url: URL
    @StateObject private var loader: AvatarImageLoader

    init(url: URL) {
        self.url = url
        _loader = StateObject(wrappedValue: AvatarImageLoader(url: url))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}
