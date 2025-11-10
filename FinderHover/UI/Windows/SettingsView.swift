//
//  SettingsView.swift
//  FinderHover
//
//  Settings window UI with sidebar navigation
//

import SwiftUI
import UniformTypeIdentifiers

enum SettingsPage: String, CaseIterable, Identifiable {
    case behavior
    case appearance
    case display
    case permissions
    case about

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .behavior: return "settings.tab.behavior".localized
        case .appearance: return "settings.tab.appearance".localized
        case .display: return "settings.tab.display".localized
        case .permissions: return "settings.tab.permissions".localized
        case .about: return "settings.tab.about".localized
        }
    }

    var icon: String {
        switch self {
        case .behavior: return "hand.point.up.left.fill"
        case .appearance: return "paintbrush.fill"
        case .display: return "list.bullet"
        case .permissions: return "lock.shield.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var selectedPage: SettingsPage = .behavior

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsPage.allCases, selection: $selectedPage) { page in
                NavigationLink(value: page) {
                    Label {
                        Text(page.localizedName)
                            .font(.system(size: 13))
                    } icon: {
                        Image(systemName: page.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                    }
                }
            }
            .navigationSplitViewColumnWidth(180)
            .listStyle(.sidebar)
        } detail: {
            // Detail view
            Group {
                switch selectedPage {
                case .behavior:
                    BehaviorSettingsView(settings: settings)
                case .appearance:
                    AppearanceSettingsView(settings: settings)
                case .display:
                    DisplaySettingsView(settings: settings)
                case .permissions:
                    PermissionsSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
            .frame(minWidth: 450, minHeight: 400)
        }
    }
}

// MARK: - Behavior Settings
struct BehaviorSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var initialLanguage: AppLanguage? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.behavior.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Hover Delay
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.behavior.hoverDelay".localized)
                            .font(.system(size: 13, weight: .semibold))

                        Text("settings.behavior.hoverDelay.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Slider(value: $settings.hoverDelay, in: 0.1...2.0, step: 0.1)
                                .frame(maxWidth: .infinity)
                            Text("settings.behavior.hoverDelay.seconds".localized(settings.hoverDelay))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 80, alignment: .trailing)
                                .fixedSize()
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Auto-hide
                    SettingRow(
                        title: "settings.behavior.autoHide".localized,
                        description: "settings.behavior.autoHide.description".localized
                    ) {
                        Toggle("", isOn: $settings.autoHideEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Launch at Login
                    SettingRow(
                        title: "settings.behavior.launchAtLogin".localized,
                        description: "settings.behavior.launchAtLogin.description".localized
                    ) {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Language Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("settings.language".localized)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("settings.language.description".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Picker("", selection: $settings.preferredLanguage) {
                                    ForEach(AppLanguage.allCases) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()

                                Button("settings.language.restart".localized) {
                                    NSApplication.shared.terminate(nil)
                                }
                                .disabled(settings.preferredLanguage == initialLanguage)
                                .buttonStyle(.bordered)
                                .fixedSize()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .onAppear {
                        if initialLanguage == nil {
                            initialLanguage = settings.preferredLanguage
                        }
                    }

                    Divider()

                    // Window Position
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.behavior.windowPosition".localized)
                            .font(.system(size: 13, weight: .semibold))

                        Text("settings.behavior.windowPosition.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Text("settings.behavior.horizontalOffset".localized)
                                    .frame(width: 90, alignment: .leading)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.windowOffsetX, in: 0...50, step: 5)
                                    .frame(maxWidth: .infinity)
                                Text("settings.behavior.pixels".localized(Int(settings.windowOffsetX)))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 80, alignment: .trailing)
                                    .fixedSize()
                            }

                            HStack(spacing: 12) {
                                Text("settings.behavior.verticalOffset".localized)
                                    .frame(width: 90, alignment: .leading)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.windowOffsetY, in: 0...50, step: 5)
                                    .frame(maxWidth: .infinity)
                                Text("settings.behavior.pixels".localized(Int(settings.windowOffsetY)))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 80, alignment: .trailing)
                                    .fixedSize()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("common.reset".localized) {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.appearance.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // UI Style Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("settings.style".localized)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("settings.style.description".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Picker("", selection: $settings.uiStyle) {
                                ForEach(UIStyle.allCases) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Window Opacity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.appearance.opacity".localized)
                            .font(.system(size: 13, weight: .semibold))

                        Text("settings.appearance.opacity.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Slider(value: $settings.windowOpacity, in: 0.7...1.0, step: 0.05)
                                .frame(maxWidth: .infinity)
                                .disabled(settings.enableBlur)
                            Text("settings.appearance.opacity.percent".localized(Int(settings.windowOpacity * 100)))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 80, alignment: .trailing)
                                .fixedSize()
                        }

                        if settings.enableBlur {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                Text("settings.appearance.opacity.hint".localized)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Maximum Width
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.appearance.maxWidth".localized)
                            .font(.system(size: 13, weight: .semibold))

                        Text("settings.appearance.maxWidth.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Slider(value: $settings.windowMaxWidth, in: 300...600, step: 20)
                                .frame(maxWidth: .infinity)
                            Text("settings.appearance.maxWidth.pixels".localized(Int(settings.windowMaxWidth)))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 80, alignment: .trailing)
                                .fixedSize()
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Font Size
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.appearance.fontSize".localized)
                            .font(.system(size: 13, weight: .semibold))

                        Text("settings.appearance.fontSize.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Slider(value: $settings.fontSize, in: 9...14, step: 1)
                                .frame(maxWidth: .infinity)
                            Text("settings.appearance.fontSize.points".localized(settings.fontSize))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 80, alignment: .trailing)
                                .fixedSize()
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Blur Effect
                    SettingRow(
                        title: "settings.appearance.blur".localized,
                        description: "settings.appearance.blur.hint".localized
                    ) {
                        Toggle("", isOn: $settings.enableBlur)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Compact Mode
                    SettingRow(
                        title: "settings.appearance.compactMode".localized,
                        description: "settings.appearance.compactMode.hint".localized
                    ) {
                        Toggle("", isOn: $settings.compactMode)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("common.reset".localized) {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Display Settings
struct DisplaySettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var draggingItem: DisplayItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.display.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 16) {
                    Text("settings.display.basicInfo".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.showIcon".localized, icon: "photo", isOn: $settings.showIcon)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showFileType".localized, icon: "doc.text", isOn: $settings.showFileType)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showFileSize".localized, icon: "archivebox", isOn: $settings.showFileSize)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showItemCount".localized, icon: "number", isOn: $settings.showItemCount)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showCreationDate".localized, icon: "calendar", isOn: $settings.showCreationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showModificationDate".localized, icon: "clock", isOn: $settings.showModificationDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showLastAccessDate".localized, icon: "eye", isOn: $settings.showLastAccessDate)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showPermissions".localized, icon: "lock.shield", isOn: $settings.showPermissions)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showOwner".localized, icon: "person", isOn: $settings.showOwner)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.showFilePath".localized, icon: "folder", isOn: $settings.showFilePath)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    // EXIF Section
                    Text("settings.display.exif".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.exif.show".localized, icon: IconManager.Photo.camera, isOn: $settings.showEXIF)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.camera".localized, icon: IconManager.Photo.camera, isOn: $settings.showEXIFCamera)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.lens".localized, icon: IconManager.Photo.lens, isOn: $settings.showEXIFLens)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.settings".localized, icon: IconManager.Photo.settings, isOn: $settings.showEXIFSettings)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.dateTaken".localized, icon: IconManager.Photo.calendarClock, isOn: $settings.showEXIFDateTaken)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.dimensions".localized, icon: IconManager.Photo.dimensions, isOn: $settings.showEXIFDimensions)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.exif.gps".localized, icon: IconManager.Photo.location, isOn: $settings.showEXIFGPS)
                            .disabled(!settings.showEXIF)
                            .opacity(settings.showEXIF ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.exif.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Video Section
                    Text("settings.display.video".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.video.show".localized, icon: IconManager.Video.video, isOn: $settings.showVideo)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.video.duration".localized, icon: IconManager.Video.duration, isOn: $settings.showVideoDuration)
                            .disabled(!settings.showVideo)
                            .opacity(settings.showVideo ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.video.resolution".localized, icon: IconManager.Video.resolution, isOn: $settings.showVideoResolution)
                            .disabled(!settings.showVideo)
                            .opacity(settings.showVideo ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.video.codec".localized, icon: IconManager.Video.codec, isOn: $settings.showVideoCodec)
                            .disabled(!settings.showVideo)
                            .opacity(settings.showVideo ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.video.framerate".localized, icon: IconManager.Video.frameRate, isOn: $settings.showVideoFrameRate)
                            .disabled(!settings.showVideo)
                            .opacity(settings.showVideo ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.video.bitrate".localized, icon: IconManager.Video.bitrate, isOn: $settings.showVideoBitrate)
                            .disabled(!settings.showVideo)
                            .opacity(settings.showVideo ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.video.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Audio Section
                    Text("settings.display.audio".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.audio.show".localized, icon: IconManager.Audio.music, isOn: $settings.showAudio)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.title".localized, icon: IconManager.Audio.songTitle, isOn: $settings.showAudioTitle)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.artist".localized, icon: IconManager.Audio.artist, isOn: $settings.showAudioArtist)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.album".localized, icon: IconManager.Audio.album, isOn: $settings.showAudioAlbum)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.genre".localized, icon: IconManager.Audio.genre, isOn: $settings.showAudioGenre)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.year".localized, icon: IconManager.Audio.year, isOn: $settings.showAudioYear)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.duration".localized, icon: IconManager.Audio.duration, isOn: $settings.showAudioDuration)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.bitrate".localized, icon: IconManager.Audio.bitrate, isOn: $settings.showAudioBitrate)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.audio.samplerate".localized, icon: IconManager.Audio.sampleRate, isOn: $settings.showAudioSampleRate)
                            .disabled(!settings.showAudio)
                            .opacity(settings.showAudio ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.audio.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // PDF Section
                    Text("settings.display.pdf".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.pdf.show".localized, icon: "doc.richtext", isOn: $settings.showPDF)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.pageCount".localized, icon: "doc.text", isOn: $settings.showPDFPageCount)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.pageSize".localized, icon: "ruler", isOn: $settings.showPDFPageSize)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.version".localized, icon: "info.circle", isOn: $settings.showPDFVersion)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.title".localized, icon: "textformat", isOn: $settings.showPDFTitle)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.author".localized, icon: "person", isOn: $settings.showPDFAuthor)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.subject".localized, icon: "text.alignleft", isOn: $settings.showPDFSubject)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.creator".localized, icon: "app", isOn: $settings.showPDFCreator)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.producer".localized, icon: "gearshape", isOn: $settings.showPDFProducer)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.creationDate".localized, icon: "calendar", isOn: $settings.showPDFCreationDate)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.modificationDate".localized, icon: "clock", isOn: $settings.showPDFModificationDate)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.keywords".localized, icon: "tag", isOn: $settings.showPDFKeywords)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.pdf.encrypted".localized, icon: "lock.fill", isOn: $settings.showPDFEncrypted)
                            .disabled(!settings.showPDF)
                            .opacity(settings.showPDF ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.pdf.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Office Section
                    Text("settings.display.office".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.office.show".localized, icon: "doc.richtext", isOn: $settings.showOffice)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.title".localized, icon: "textformat", isOn: $settings.showOfficeTitle)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.author".localized, icon: "person", isOn: $settings.showOfficeAuthor)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.subject".localized, icon: "text.alignleft", isOn: $settings.showOfficeSubject)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.keywords".localized, icon: "tag", isOn: $settings.showOfficeKeywords)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.comment".localized, icon: "text.bubble", isOn: $settings.showOfficeComment)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.lastModifiedBy".localized, icon: "person.crop.circle", isOn: $settings.showOfficeLastModifiedBy)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.creationDate".localized, icon: "calendar", isOn: $settings.showOfficeCreationDate)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.modificationDate".localized, icon: "clock", isOn: $settings.showOfficeModificationDate)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.pageCount".localized, icon: "doc.text", isOn: $settings.showOfficePageCount)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.wordCount".localized, icon: "textformat.size", isOn: $settings.showOfficeWordCount)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.sheetCount".localized, icon: "tablecells", isOn: $settings.showOfficeSheetCount)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.slideCount".localized, icon: "rectangle.stack", isOn: $settings.showOfficeSlideCount)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.company".localized, icon: "building.2", isOn: $settings.showOfficeCompany)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.office.category".localized, icon: "folder", isOn: $settings.showOfficeCategory)
                            .disabled(!settings.showOffice)
                            .opacity(settings.showOffice ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.office.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Archive Section
                    Text("settings.display.archive".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.archive.show".localized, icon: "doc.zipper", isOn: $settings.showArchive)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.archive.format".localized, icon: "doc.zipper", isOn: $settings.showArchiveFormat)
                            .disabled(!settings.showArchive)
                            .opacity(settings.showArchive ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.archive.fileCount".localized, icon: "doc.on.doc", isOn: $settings.showArchiveFileCount)
                            .disabled(!settings.showArchive)
                            .opacity(settings.showArchive ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.archive.uncompressedSize".localized, icon: "arrow.up.doc", isOn: $settings.showArchiveUncompressedSize)
                            .disabled(!settings.showArchive)
                            .opacity(settings.showArchive ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.archive.compressionRatio".localized, icon: "chart.bar", isOn: $settings.showArchiveCompressionRatio)
                            .disabled(!settings.showArchive)
                            .opacity(settings.showArchive ? 1.0 : 0.5)
                        Divider().padding(.leading, 60)
                        DisplayToggleRow(title: "settings.display.archive.encrypted".localized, icon: "lock.fill", isOn: $settings.showArchiveEncrypted)
                            .disabled(!settings.showArchive)
                            .opacity(settings.showArchive ? 1.0 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.archive.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // E-book Section
                    Text("settings.display.ebook".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.ebook.show".localized, icon: "book.closed", isOn: $settings.showEbook)

                        DisplayToggleRow(title: "settings.display.ebook.title".localized, icon: "book.closed", isOn: $settings.showEbookTitle)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.author".localized, icon: "person", isOn: $settings.showEbookAuthor)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.publisher".localized, icon: "building.2", isOn: $settings.showEbookPublisher)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.publicationDate".localized, icon: "calendar", isOn: $settings.showEbookPublicationDate)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.isbn".localized, icon: "barcode", isOn: $settings.showEbookISBN)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.language".localized, icon: "globe", isOn: $settings.showEbookLanguage)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.description".localized, icon: "text.alignleft", isOn: $settings.showEbookDescription)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.ebook.pageCount".localized, icon: "doc.text", isOn: $settings.showEbookPageCount)
                            .disabled(!settings.showEbook)
                            .opacity(settings.showEbook ? 1 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.ebook.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Code File Section
                    Text("settings.display.code".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.code.show".localized, icon: "chevron.left.forwardslash.chevron.right", isOn: $settings.showCode)

                        DisplayToggleRow(title: "settings.display.code.language".localized, icon: "chevron.left.forwardslash.chevron.right", isOn: $settings.showCodeLanguage)
                            .disabled(!settings.showCode)
                            .opacity(settings.showCode ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.code.lineCount".localized, icon: "number", isOn: $settings.showCodeLineCount)
                            .disabled(!settings.showCode)
                            .opacity(settings.showCode ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.code.codeLines".localized, icon: "curlybraces", isOn: $settings.showCodeLines)
                            .disabled(!settings.showCode)
                            .opacity(settings.showCode ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.code.commentLines".localized, icon: "text.bubble", isOn: $settings.showCodeCommentLines)
                            .disabled(!settings.showCode)
                            .opacity(settings.showCode ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.code.blankLines".localized, icon: "minus", isOn: $settings.showCodeBlankLines)
                            .disabled(!settings.showCode)
                            .opacity(settings.showCode ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.code.encoding".localized, icon: "textformat.abc", isOn: $settings.showCodeEncoding)
                            .disabled(!settings.showCode)
                            .opacity(settings.showCode ? 1 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.code.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Font Information
                    Text("settings.display.font.title".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(NSColor.labelColor))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.font.show".localized, icon: "textformat", isOn: $settings.showFont)

                        DisplayToggleRow(title: "settings.display.font.name".localized, icon: "textformat", isOn: $settings.showFontName)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.font.family".localized, icon: "textformat.alt", isOn: $settings.showFontFamily)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.font.style".localized, icon: "italic", isOn: $settings.showFontStyle)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.font.version".localized, icon: "number", isOn: $settings.showFontVersion)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.font.designer".localized, icon: "person", isOn: $settings.showFontDesigner)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.font.copyright".localized, icon: "c.circle", isOn: $settings.showFontCopyright)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.font.glyphCount".localized, icon: "character.textbox", isOn: $settings.showFontGlyphCount)
                            .disabled(!settings.showFont)
                            .opacity(settings.showFont ? 1 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.font.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Disk Image Information
                    Text("settings.display.diskImage.title".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(NSColor.labelColor))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        DisplayToggleRow(title: "settings.display.diskImage.show".localized, icon: "opticaldiscdrive", isOn: $settings.showDiskImage)

                        DisplayToggleRow(title: "settings.display.diskImage.format".localized, icon: "opticaldiscdrive", isOn: $settings.showDiskImageFormat)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.diskImage.totalSize".localized, icon: "externaldrive", isOn: $settings.showDiskImageTotalSize)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.diskImage.compressedSize".localized, icon: "arrow.down.circle", isOn: $settings.showDiskImageCompressedSize)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.diskImage.compressionRatio".localized, icon: "chart.bar", isOn: $settings.showDiskImageCompressionRatio)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.diskImage.encrypted".localized, icon: "lock.shield", isOn: $settings.showDiskImageEncrypted)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.diskImage.partitionScheme".localized, icon: "square.split.2x2", isOn: $settings.showDiskImagePartitionScheme)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)

                        DisplayToggleRow(title: "settings.display.diskImage.fileSystem".localized, icon: "doc.text", isOn: $settings.showDiskImageFileSystem)
                            .disabled(!settings.showDiskImage)
                            .opacity(settings.showDiskImage ? 1 : 0.5)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.diskImage.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Vector Graphics Section
                    Text("settings.display.vectorGraphics.title".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(spacing: 10) {
                        // Main toggle
                        DisplayToggleRow(title: "settings.display.vectorGraphics.show".localized, icon: "paintbrush.pointed", isOn: $settings.showVectorGraphics)

                        // Detail toggles
                        DisplayToggleRow(title: "settings.display.vectorGraphics.format".localized, icon: "paintbrush.pointed", isOn: $settings.showVectorGraphicsFormat)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                        DisplayToggleRow(title: "settings.display.vectorGraphics.dimensions".localized, icon: "arrow.up.left.and.arrow.down.right", isOn: $settings.showVectorGraphicsDimensions)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                        DisplayToggleRow(title: "settings.display.vectorGraphics.viewBox".localized, icon: "rectangle.dashed", isOn: $settings.showVectorGraphicsViewBox)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                        DisplayToggleRow(title: "settings.display.vectorGraphics.elementCount".localized, icon: "square.stack.3d.up", isOn: $settings.showVectorGraphicsElementCount)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                        DisplayToggleRow(title: "settings.display.vectorGraphics.colorMode".localized, icon: "paintpalette", isOn: $settings.showVectorGraphicsColorMode)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                        DisplayToggleRow(title: "settings.display.vectorGraphics.creator".localized, icon: "hammer", isOn: $settings.showVectorGraphicsCreator)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                        DisplayToggleRow(title: "settings.display.vectorGraphics.version".localized, icon: "number", isOn: $settings.showVectorGraphicsVersion)
                            .disabled(!settings.showVectorGraphics)
                            .opacity(settings.showVectorGraphics ? 1 : 0.5)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.vectorGraphics.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Display Order Section
                    Text("settings.display.order".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(spacing: 0) {
                        ForEach(settings.displayOrder) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)

                                Text(item.localizedName)
                                    .font(.system(size: 13))

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .background(Color(NSColor.controlBackgroundColor))
                            .opacity(draggingItem == item ? 0.5 : 1.0)
                            .onDrag {
                                self.draggingItem = item
                                return NSItemProvider(object: item.rawValue as NSString)
                            }
                            .onDrop(of: [.text], delegate: DisplayItemDropDelegate(
                                item: item,
                                items: $settings.displayOrder,
                                draggingItem: $draggingItem
                            ))

                            if item != settings.displayOrder.last {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text("settings.display.order.hint".localized)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer(minLength: 40)

                // Reset Button
                HStack {
                    Spacer()
                    Button("common.reset".localized) {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Permissions Settings
struct PermissionsSettingsView: View {
    @State private var accessibilityEnabled = AXIsProcessTrusted()
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("settings.permissions.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // Accessibility Permission
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.point.up.left.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(accessibilityEnabled ? .green : .orange)

                                    Text("settings.permissions.accessibility".localized)
                                        .font(.system(size: 14, weight: .semibold))
                                }

                                Text("settings.permissions.accessibility.description".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: accessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(accessibilityEnabled ? .green : .red)

                                    Text(accessibilityEnabled ? "settings.permissions.granted".localized : "settings.permissions.notGranted".localized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(accessibilityEnabled ? .green : .red)
                                }

                                if !accessibilityEnabled {
                                    Button("settings.permissions.openSystemSettings".localized) {
                                        openAccessibilitySettings()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                        }

                        // Additional info box
                        if !accessibilityEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("settings.permissions.accessibility.required".localized)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)
                                }

                                Text("settings.permissions.accessibility.steps".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.leading, 18)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    // Why These Permissions Are Needed
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.accentColor)

                            Text("settings.permissions.whyNeeded".localized)
                                .font(.system(size: 14, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            PermissionReasonRow(
                                icon: "cursorarrow.rays",
                                title: "settings.permissions.reason.mouseTracking".localized,
                                description: "settings.permissions.reason.mouseTracking.description".localized
                            )

                            PermissionReasonRow(
                                icon: "doc.text.magnifyingglass",
                                title: "settings.permissions.reason.fileDetection".localized,
                                description: "settings.permissions.reason.fileDetection.description".localized
                            )

                            PermissionReasonRow(
                                icon: "hand.raised.fill",
                                title: "settings.permissions.reason.noInvasion".localized,
                                description: "settings.permissions.reason.noInvasion.description".localized
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    // Privacy Notice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)

                            Text("settings.permissions.privacy".localized)
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Text("settings.permissions.privacy.description".localized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            accessibilityEnabled = AXIsProcessTrusted()
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Permission Reason Row
struct PermissionReasonRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

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
                // Header
                Text("settings.tab.about".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

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

                    // Check for Updates Section
                    VStack(spacing: 8) {
                        if githubService.isCheckingForUpdates {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 12, height: 12)
                                Text("settings.about.checkingForUpdates".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        } else if let error = githubService.updateCheckError {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Button(action: {
                                    Task {
                                        await githubService.fetchLatestRelease(includePrereleases: AppSettings.shared.includePrereleases)
                                    }
                                }) {
                                    Text("settings.about.retry".localized)
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.link)
                            }
                        } else if let latestRelease = githubService.latestRelease {
                            if githubService.isUpdateAvailable {
                                VStack(spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.green)
                                        Text(String(format: "settings.about.updateAvailable".localized, latestRelease.version))
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Button(action: {
                                        if let url = URL(string: latestRelease.htmlUrl) {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.forward.square")
                                                .font(.system(size: 11))
                                            Text("settings.about.viewRelease".localized)
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.green)
                                    if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                        Text(String(format: "settings.about.upToDateWithVersion".localized, currentVersion))
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("settings.about.upToDate".localized)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } else {
                            Button(action: {
                                Task {
                                    await githubService.fetchLatestRelease(includePrereleases: AppSettings.shared.includePrereleases)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.circle")
                                        .font(.system(size: 11))
                                    Text("settings.about.checkForUpdates".localized)
                                        .font(.system(size: 12))
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)

                    // Prerelease Toggle
                    HStack(spacing: 8) {
                        Text("settings.about.includePrereleases".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Toggle("", isOn: Binding(
                            get: { AppSettings.shared.includePrereleases },
                            set: { newValue in
                                AppSettings.shared.includePrereleases = newValue
                                // Reset update check state when toggle changes
                                githubService.latestRelease = nil
                                githubService.updateCheckError = nil
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    .padding(.top, -8)

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
        .alert("settings.about.updateAvailable.title".localized, isPresented: $githubService.showUpdateAlert) {
            Button("settings.about.viewRelease".localized) {
                githubService.openReleasePage()
                githubService.showUpdateAlert = false
            }
            Button("common.cancel".localized, role: .cancel) {
                githubService.showUpdateAlert = false
            }
        } message: {
            if let latestRelease = githubService.latestRelease,
               let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text(String(format: "settings.about.updateAvailable.message".localized, currentVersion, latestRelease.version))
            }
        }
    }
}

// MARK: - About Feature Row
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

// MARK: - Helper Views
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
    }
}

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

// MARK: - Drag and Drop Delegate
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

#Preview {
    SettingsView()
}
