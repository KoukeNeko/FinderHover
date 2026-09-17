//
//  SettingsComponents.swift
//  FinderHover
//
//  Shared components for settings views
//

import SwiftUI

/// Row layout constants matching the System Settings visual language.
enum SettingsRowLayout {
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 12
    static let tileSize: CGFloat = 24
    static let tileSymbolSize: CGFloat = 13
    static let tileSpacing: CGFloat = 12
    static let dividerLeading: CGFloat = horizontalPadding + tileSize + tileSpacing
    static let cardCornerRadius: CGFloat = 10
    static let contentMaxWidth: CGFloat = 640
}

// MARK: - Icon Tile
/// Colored rounded-square icon used in the sidebar and on card rows,
/// matching the icon tiles in macOS System Settings.
struct SettingsIconTile: View {
    let icon: String
    let tint: Color
    var size: CGFloat = SettingsRowLayout.tileSize
    var symbolSize: CGFloat = SettingsRowLayout.tileSymbolSize

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: symbolSize, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: size * 0.29))
    }
}

// MARK: - Section Label
/// Small semibold label shown above a card, like System Settings section titles.
struct SettingsSectionLabel: View {
    let titleKey: String

    var body: some View {
        Text(titleKey.localized)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, SettingsRowLayout.horizontalPadding)
    }
}

// MARK: - Setting Row
struct SettingRow<Content: View>: View {
    let title: String
    let description: String
    let icon: String?
    let tint: Color
    let content: Content

    init(title: String, description: String, icon: String? = nil, tint: Color = .accentColor, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                HStack(alignment: .center, spacing: SettingsRowLayout.tileSpacing) {
                    if let icon {
                        SettingsIconTile(icon: icon, tint: tint)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                content
                    .accessibilityLabel(title)
            }
        }
        .padding(.horizontal, SettingsRowLayout.horizontalPadding)
        .padding(.vertical, SettingsRowLayout.verticalPadding)
    }
}

// MARK: - Display Toggle Row
struct DisplayToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))

            Spacer()

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Feature Row (for About page)
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Avatar Image View (for GitHub contributors)
struct AvatarImageView: View {
    let url: URL
    @State private var image: NSImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        defer { isLoading = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                image = nsImage
            }
        } catch {
            Logger.warning("Failed to load avatar image: \(error.localizedDescription)", subsystem: .ui)
        }
    }
}

// MARK: - Drag and Drop Delegate for Display Order
struct DisplayItemDropDelegate: DropDelegate {
    let item: DisplayItem
    @Binding var items: [DisplayItem]
    @Binding var draggingItem: DisplayItem?

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem,
              draggingItem != item,
              let fromIndex = items.firstIndex(of: draggingItem),
              let toIndex = items.firstIndex(of: item) else { return }

        // Reordering the bound array writes through to AppSettings.displayOrder,
        // whose didSet persists it; no manual save needed.
        if items[toIndex] != draggingItem {
            withAnimation(.default) {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
