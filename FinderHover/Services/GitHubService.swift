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

    init() {
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
            request.timeoutInterval = 10

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
                cacheContributors(fetchedContributors)
            } else {
                error = "HTTP \(httpResponse.statusCode)"
            }
        } catch {
            self.error = error.localizedDescription
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

        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            self.image = cachedImage
            return
        }

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
