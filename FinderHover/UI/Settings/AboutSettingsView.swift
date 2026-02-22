//
//  AboutSettingsView.swift
//  FinderHover
//
//  About settings page
//

import SwiftUI

// MARK: - About Settings
struct AboutSettingsView: View {
    @StateObject private var githubService = GitHubService()

    private var copyrightYear: String {
        // Get the app's build date from the bundle
        if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let infoDict = NSDictionary(contentsOfFile: infoPath) as? [String: Any],
           let buildDate = infoDict["CFBundleVersion"] as? String {
            // Try to get year from build timestamp or use current year
            if let executableURL = Bundle.main.executableURL,
               let attributes = try? FileManager.default.attributesOfItem(atPath: executableURL.path),
               let creationDate = attributes[.creationDate] as? Date {
                let year = Calendar.current.component(.year, from: creationDate)
                return String(year)
            }
        }
        return String(Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPageHeader(
                    icon: "info.circle",
                    title: "settings.tab.about".localized,
                    description: "settings.page.description.about".localized
                )

                VStack(alignment: .center, spacing: 24) {
                    // App Icon
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .padding(.top, 20)
                    }

                    // App Name and Version
                    VStack(spacing: 8) {
                        Text("FinderHover")
                            .font(.system(size: 24, weight: .bold))
                        Text(String(format: "settings.about.version".localized, Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Description
                    Text("settings.about.description".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Divider()
                        .padding(.vertical, 8)

                    // Usage Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("settings.about.usage".localized)
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("1.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("settings.about.usage.step1".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Text("2.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("settings.about.usage.step2".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Text("3.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("settings.about.usage.step3".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: 360)

                    Divider()
                        .padding(.vertical, 8)

                    // GitHub Links
                    VStack(spacing: 12) {
                        Text("settings.about.github".localized)
                            .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 12) {
                            Button(action: {
                                if let url = URL(string: "https://github.com/KoukeNeko/FinderHover") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "link")
                                        .font(.system(size: 11))
                                    Text("settings.about.github.repository".localized)
                                        .font(.system(size: 12))
                                }
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                if let url = URL(string: "https://github.com/KoukeNeko/FinderHover/issues") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.bubble")
                                        .font(.system(size: 11))
                                    Text("settings.about.github.issues".localized)
                                        .font(.system(size: 12))
                                }
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                if let url = URL(string: "https://github.com/KoukeNeko/FinderHover/releases") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 11))
                                    Text("settings.about.github.releases".localized)
                                        .font(.system(size: 12))
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Contributors Section
                    VStack(spacing: 12) {
                        if githubService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(height: 60)
                        } else if let error = githubService.error {
                            Text("Failed to load contributors: \(error)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(height: 60)
                        } else if !githubService.contributors.isEmpty {
                            VStack(spacing: 8) {
                                Text("settings.about.contributors".localized)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)

                                // Contributors Grid
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 10)], spacing: 10) {
                                    ForEach(githubService.contributors) { contributor in
                                        Button(action: {
                                            if let url = URL(string: contributor.htmlUrl) {
                                                NSWorkspace.shared.open(url)
                                            }
                                        }) {
                                            VStack(spacing: 3) {
                                                if let avatarURL = URL(string: contributor.avatarUrl) {
                                                    AvatarImageView(url: avatarURL)
                                                        .frame(width: 32, height: 32)
                                                        .clipShape(Circle())
                                                        .overlay(
                                                            Circle()
                                                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                                        )
                                                }

                                                Text(contributor.login)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .frame(maxWidth: 60)

                                                Text("\(contributor.contributions)")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 60)
                                        }
                                        .buttonStyle(.plain)
                                        .help(contributor.login)
                                    }
                                }
                                .frame(maxWidth: 380)
                            }
                        }
                    }
                    .task {
                        if githubService.contributors.isEmpty && !githubService.isLoading {
                            await githubService.fetchContributors()
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Credits
                    VStack(spacing: 8) {
                        Text("© \(copyrightYear) FinderHover")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("settings.about.opensource".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
