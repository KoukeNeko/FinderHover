//
//  SettingsComponents.swift
//  FinderHover
//
//  Shared components for settings views
//

import SwiftUI
import UniformTypeIdentifiers

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

extension UTType {
    /// App-private type for reorder drags. Accepting `.text` also matched external
    /// text drags, which carry no `draggingItem` and could reorder with stale state.
    static let displayItemOrder = UTType(exportedAs: "dev.koukeneko.finderhover.display-item")
}

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

// MARK: - Live Preview Layout
/// Settings pages pair a canvas that shows the result with an inspector of controls.
enum SettingsCanvasLayout {
    static let inspectorWidth: CGFloat = 300
    static let sidebarWidth: CGFloat = 230
    static let groupCornerRadius: CGFloat = 8
}

/// Dotted canvas behind a live preview.
struct SettingsCanvas<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color(NSColor.underPageBackgroundColor)
            Canvas { context, size in
                let dot = Path(ellipseIn: CGRect(x: 0, y: 0, width: 1.2, height: 1.2))
                for x in stride(from: 8.0, to: size.width, by: 16) {
                    for y in stride(from: 8.0, to: size.height, by: 16) {
                        context.fill(dot.offsetBy(dx: x, dy: y), with: .color(.primary.opacity(0.08)))
                    }
                }
            }
            content
        }
        // Zero minimum: a tall preview must clip, not raise the window's minimum size
        // past the screen (which pushes the toolbar off the window).
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
    }
}

/// Right-hand column of controls for the page's canvas.
struct SettingsInspector<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 0) {
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(16)
            }
        }
        .frame(width: SettingsCanvasLayout.inspectorWidth)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// A bordered group of inspector rows; place `Divider()` between rows.
struct InspectorGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(NSColor.controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: SettingsCanvasLayout.groupCornerRadius))
            .overlay(RoundedRectangle(cornerRadius: SettingsCanvasLayout.groupCornerRadius)
                .strokeBorder(Color(NSColor.separatorColor)))
    }
}

/// Small semibold label above an inspector group.
struct InspectorLabel: View {
    let titleKey: String

    var body: some View {
        Text(titleKey.localized)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, -6)
    }
}

struct InspectorToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title).font(.system(size: 13))
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 36)
    }
}

struct InspectorSliderRow: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 13))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }
}

/// The popup preview: the real popup content on a popup-like surface, not interactive.
struct PopupPreview<Content: View>: View {
    /// Liquid Glass, as the popup's NSGlassEffectView draws it. Wins over `opaqueBackground`.
    var glass = false
    var opaqueBackground: Color?
    @ViewBuilder let content: Content

    var body: some View {
        surface
            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: Constants.WindowLayout.macOSCornerRadius)
        if glass, #available(macOS 26, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content
                .background {
                    if let opaqueBackground {
                        shape.fill(opaqueBackground)
                    } else {
                        shape.fill(.regularMaterial)
                    }
                }
                .clipShape(shape)
                .overlay(shape.strokeBorder(Color.gray.opacity(0.3)))
        }
    }
}
