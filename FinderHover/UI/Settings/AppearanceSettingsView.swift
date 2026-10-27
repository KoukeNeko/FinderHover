//
//  AppearanceSettingsView.swift
//  FinderHover
//
//  Appearance settings page
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var wallpaper: CGImage?

    private var isMacOSStyle: Bool { settings.uiStyle == .macOS }

    /// Liquid Glass replaces blur on macOS 26 and later.
    private var usesGlass: Bool {
        if #available(macOS 26, *) { return settings.enableLiquidGlass }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            canvas
            SettingsInspector {
                InspectorLabel(titleKey: "settings.style")
                Picker("settings.style".localized, selection: $settings.uiStyle) {
                    ForEach(UIStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                InspectorGroup {
                    if #available(macOS 26, *) {
                        InspectorToggleRow(title: "settings.appearance.liquidGlass".localized, isOn: $settings.enableLiquidGlass)
                            .onChange(of: settings.enableLiquidGlass) { _, newValue in
                                if newValue { settings.enableBlur = false }
                            }
                        Divider()
                    }
                    InspectorToggleRow(title: "settings.appearance.blur".localized, isOn: $settings.enableBlur)
                        .disabled(usesGlass)
                        .onChange(of: settings.enableBlur) { _, newValue in
                            if newValue, #available(macOS 26, *) { settings.enableLiquidGlass = false }
                        }
                    Divider()
                    InspectorSliderRow(
                        title: "settings.appearance.opacity".localized,
                        valueText: "settings.appearance.opacity.percent".localized(Int(settings.windowOpacity * 100)),
                        value: $settings.windowOpacity, range: 0.7...1.0, step: 0.05)
                        .disabled(settings.enableBlur || usesGlass)
                    Divider()
                    InspectorToggleRow(title: "settings.appearance.compactMode".localized, isOn: $settings.compactMode)
                }
                .disabled(!isMacOSStyle)

                InspectorGroup {
                    InspectorSliderRow(
                        title: "settings.appearance.maxWidth".localized,
                        valueText: "settings.appearance.maxWidth.pixels".localized(Int(settings.windowMaxWidth)),
                        value: $settings.windowMaxWidth, range: 300...600, step: 20)
                        .disabled(!isMacOSStyle)
                    Divider()
                    InspectorSliderRow(
                        title: "settings.appearance.fontSize".localized,
                        valueText: "settings.appearance.fontSize.points".localized(settings.fontSize),
                        value: $settings.fontSize, range: 9...14, step: 1)
                }
            }
        }
    }

    /// The popup over the user's own wallpaper, so glass, blur and opacity read as they will.
    private var canvas: some View {
        ZStack {
            if let wallpaper {
                // In an overlay so the filled image cannot grow the canvas past the window.
                Color.clear.overlay {
                    Image(decorative: wallpaper, scale: 1).resizable().aspectRatio(contentMode: .fill)
                }
            } else {
                gradientDesktop
            }
            ScrollView {
                Group {
                    if isMacOSStyle {
                        PopupPreview(glass: usesGlass,
                                     opaqueBackground: settings.enableBlur || usesGlass
                                     ? nil
                                     : Color(NSColor.controlBackgroundColor).opacity(settings.windowOpacity)) {
                            HoverContentView(fileInfo: PreviewSamples.photo)
                        }
                    } else {
                        WindowsStyleHoverView(fileInfo: PreviewSamples.photo)
                            .background(Color(NSColor.controlBackgroundColor))
                            .overlay(Rectangle().strokeBorder(Color.gray.opacity(0.4)))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 2)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .clipped()
        .task {
            guard let screen = NSScreen.main, let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return }
            wallpaper = await Self.downsampledImage(at: url)
        }
    }

    /// Stand-in when the wallpaper is not a still image (a dynamic or video wallpaper).
    private var gradientDesktop: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.29, green: 0.37, blue: 0.56), Color(red: 0.79, green: 0.56, blue: 0.42)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Color(red: 0.91, green: 0.71, blue: 0.48), .clear],
                           center: UnitPoint(x: 0.25, y: 0.8), startRadius: 0, endRadius: 380)
            RadialGradient(colors: [Color(red: 0.43, green: 0.56, blue: 0.84), .clear],
                           center: UnitPoint(x: 0.8, y: 0.2), startRadius: 0, endRadius: 420)
        }
    }

    /// Wallpapers are often 6K HEICs; decode a canvas-sized copy off the main thread.
    @concurrent
    private static func downsampledImage(at url: URL) async -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2400
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
