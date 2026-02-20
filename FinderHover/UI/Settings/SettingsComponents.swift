//
//  SettingsComponents.swift
//  FinderHover
//
//  Shared components for settings views
//

import SwiftUI

// MARK: - Page Header

struct SettingsPageHeader: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.systemGray).opacity(0.35))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.primary)
            }

            Text(title)
                .font(.system(size: 18, weight: .semibold))

            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Setting Row
struct SettingRow<Content: View>: View {
    let title: String
    let description: String
    let content: Content

    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                content
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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

            Toggle("", isOn: $isOn)
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

    private func loadImage() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    self.image = nsImage
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
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

        if items[toIndex] != draggingItem {
            withAnimation(.default) {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }

            // Manually save to UserDefaults since move() doesn't trigger didSet
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "displayOrder")
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
