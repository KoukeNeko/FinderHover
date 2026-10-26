//
//  BehaviorSettingsView.swift
//  FinderHover
//
//  Behavior settings page
//

import SwiftUI

struct BehaviorSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 0) {
            SettingsCanvas { BehaviorPreview(settings: settings) }
            SettingsInspector {
                InspectorGroup {
                    InspectorSliderRow(
                        title: "settings.behavior.hoverDelay".localized,
                        valueText: "settings.behavior.hoverDelay.seconds".localized(settings.hoverDelay),
                        value: $settings.hoverDelay, range: 0.1...2.0, step: 0.1)
                    Divider()
                    InspectorToggleRow(title: "settings.behavior.autoHide".localized, isOn: $settings.autoHideEnabled)
                    Divider()
                    InspectorToggleRow(title: "settings.behavior.largeFileProtection".localized, isOn: $settings.enableLargeFileProtection)
                    Divider()
                    InspectorToggleRow(title: "settings.behavior.launchAtLogin".localized, isOn: $settings.launchAtLogin)
                }

                InspectorLabel(titleKey: "settings.behavior.windowPosition")
                InspectorGroup {
                    InspectorSliderRow(
                        title: "settings.behavior.horizontalOffset".localized,
                        valueText: "settings.behavior.pixels".localized(Int(settings.windowOffsetX)),
                        value: $settings.windowOffsetX, range: 0...50, step: 5)
                    Divider()
                    InspectorSliderRow(
                        title: "settings.behavior.verticalOffset".localized,
                        valueText: "settings.behavior.pixels".localized(Int(settings.windowOffsetY)),
                        value: $settings.windowOffsetY, range: 0...50, step: 5)
                }

                InspectorLabel(titleKey: "settings.language")
                InspectorGroup {
                    HStack {
                        Picker("settings.language".localized, selection: $settings.preferredLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        Button("settings.language.restart".localized) { AppRelauncher.relaunch() }
                            .disabled(!settings.languageRestartRequired)
                    }
                    .controlSize(.small)
                    .padding(10)
                }
            }
        }
    }
}

/// A Finder list with the cursor resting on a file: the dwell ring shows the hover
/// delay, dashed guides show the offsets, and the popup sits where those settings put it.
private struct BehaviorPreview: View {
    @ObservedObject var settings: AppSettings
    @State private var dwell: CGFloat = 0

    private static let rows: [(String, Color, String)] = [
        ("2026 新潟", .blue, "—"), ("DSC03752.ARW", .brown, "21.4 MB"), ("DSC03754.ARW", .brown, "21.9 MB"),
        ("DSC03757.ARW", .brown, "21.6 MB"), ("DSC03760.ARW", .brown, "22.0 MB"), ("行程.md", .mint, "4 KB"),
        ("票券.pdf", .red, "312 KB"), ("新潟.mov", .indigo, "1.2 GB"), ("備份.zip", .brown, "8.2 GB"),
        ("地圖截圖.png", .yellow, "2.4 MB"), ("住宿確認.pdf", .red, "188 KB"), ("花火.heic", .yellow, "3.1 MB"),
        ("旅費.numbers", .green, "96 KB"), ("新潟 2.mov", .indigo, "860 MB")
    ]
    private static let origin = CGPoint(x: 32, y: 32)
    private static let rowHeight: CGFloat = 26
    private static let hoveredRow = 3
    /// Offsets are a few points; draw them three times larger so the guides are readable.
    private static let offsetScale: CGFloat = 3

    private var cursor: CGPoint {
        CGPoint(x: Self.origin.x + 330, y: Self.origin.y + 34 + Self.rowHeight * (CGFloat(Self.hoveredRow) + 0.5))
    }

    var body: some View {
        let offset = CGSize(width: settings.windowOffsetX * Self.offsetScale, height: settings.windowOffsetY * Self.offsetScale)
        ZStack(alignment: .topLeading) {
            finderWindow.offset(x: Self.origin.x, y: Self.origin.y)

            // Offset guides from the cursor to the popup's corner.
            Path { path in
                path.move(to: cursor)
                path.addLine(to: CGPoint(x: cursor.x + offset.width, y: cursor.y))
                path.addLine(to: CGPoint(x: cursor.x + offset.width, y: cursor.y + offset.height))
            }
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            guideLabel("settings.behavior.pixels".localized(Int(settings.windowOffsetX)))
                .offset(x: cursor.x + offset.width / 2 - 20, y: cursor.y - 26)
            guideLabel("settings.behavior.pixels".localized(Int(settings.windowOffsetY)))
                .offset(x: cursor.x + offset.width + 6, y: cursor.y + offset.height / 2 - 9)

            PopupPreview { HoverContentView(fileInfo: PreviewSamples.photo) }
                .scaleEffect(0.62, anchor: .topLeading)
                .offset(x: cursor.x + offset.width, y: cursor.y + offset.height)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: offset)

            Circle()
                .trim(from: 0, to: dwell)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 30)
                .offset(x: cursor.x - 15, y: cursor.y - 15)
                .id(settings.hoverDelay)
                .onAppear { startDwell() }
                .onChange(of: settings.hoverDelay) { _, _ in startDwell() }
            Image(systemName: "cursorarrow")
                .font(.system(size: 17))
                .foregroundStyle(.black)
                .shadow(color: .white, radius: 0.5)
                .offset(x: cursor.x - 3, y: cursor.y - 3)
            guideLabel("settings.behavior.preview.delay".localized(settings.hoverDelay))
                .offset(x: cursor.x - 150, y: cursor.y - 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var finderWindow: some View {
        VStack(spacing: 0) {
            Color(NSColor.windowBackgroundColor).frame(height: 34)
            Divider()
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3).fill(row.1.opacity(0.85)).frame(width: 14, height: 14)
                    Text(row.0)
                    Spacer()
                    Text(row.2).foregroundStyle(.secondary).font(.system(size: 12))
                }
                .font(.system(size: 13))
                .padding(.horizontal, 16)
                .frame(height: Self.rowHeight)
                .background(index == Self.hoveredRow ? Color.accentColor.opacity(0.14)
                            : index.isMultiple(of: 2) ? Color.clear : Color.primary.opacity(0.03))
            }
            Spacer(minLength: 0)
        }
        .frame(width: 540, height: 600)
        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
    }

    private func guideLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
            .fixedSize()
    }

    /// Fills the ring over the hover delay, then repeats after a short pause.
    private func startDwell() {
        dwell = 0
        withAnimation(.linear(duration: settings.hoverDelay + 0.4).repeatForever(autoreverses: false)) {
            dwell = 1
        }
    }
}
