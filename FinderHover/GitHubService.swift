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
            } else {
                error = "HTTP \(httpResponse.statusCode)"
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
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
