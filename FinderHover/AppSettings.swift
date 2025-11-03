//
//  AppSettings.swift
//  FinderHover
//
//  User preferences and settings
//

import Foundation
import SwiftUI
import Combine
import AppKit

// MARK: - Display Item Types
enum DisplayItem: String, Codable, CaseIterable, Identifiable {
    case fileType = "File Type"
    case fileSize = "File Size"
    case itemCount = "Item Count"
    case creationDate = "Creation Date"
    case modificationDate = "Modification Date"
    case lastAccessDate = "Last Access Date"
    case permissions = "Permissions"
    case owner = "Owner"
    case exif = "Photo Information (EXIF)"
    case filePath = "File Path"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .fileType: return "displayItem.fileType".localized
        case .fileSize: return "displayItem.fileSize".localized
        case .itemCount: return "displayItem.itemCount".localized
        case .creationDate: return "displayItem.creationDate".localized
        case .modificationDate: return "displayItem.modificationDate".localized
        case .lastAccessDate: return "displayItem.lastAccessDate".localized
        case .permissions: return "displayItem.permissions".localized
        case .owner: return "displayItem.owner".localized
        case .exif: return "displayItem.exif".localized
        case .filePath: return "displayItem.filePath".localized
        }
    }

    var icon: String {
        switch self {
        case .fileType: return "doc.text"
        case .fileSize: return "archivebox"
        case .itemCount: return "number"
        case .creationDate: return "calendar"
        case .modificationDate: return "clock"
        case .lastAccessDate: return "eye"
        case .permissions: return "lock.shield"
        case .owner: return "person"
        case .exif: return "camera.fill"
        case .filePath: return "folder"
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Hover behavior
    @Published var hoverDelay: Double {
        didSet { UserDefaults.standard.set(hoverDelay, forKey: "hoverDelay") }
    }
    @Published var autoHideEnabled: Bool {
        didSet { UserDefaults.standard.set(autoHideEnabled, forKey: "autoHideEnabled") }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            LaunchAtLogin.setEnabled(launchAtLogin)
        }
    }

    // Appearance
    @Published var windowOpacity: Double {
        didSet { UserDefaults.standard.set(windowOpacity, forKey: "windowOpacity") }
    }
    @Published var windowMaxWidth: Double {
        didSet { UserDefaults.standard.set(windowMaxWidth, forKey: "windowMaxWidth") }
    }
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var enableBlur: Bool {
        didSet { UserDefaults.standard.set(enableBlur, forKey: "enableBlur") }
    }
    @Published var compactMode: Bool {
        didSet { UserDefaults.standard.set(compactMode, forKey: "compactMode") }
    }

    // Information display
    @Published var showCreationDate: Bool {
        didSet { UserDefaults.standard.set(showCreationDate, forKey: "showCreationDate") }
    }
    @Published var showModificationDate: Bool {
        didSet { UserDefaults.standard.set(showModificationDate, forKey: "showModificationDate") }
    }
    @Published var showFileSize: Bool {
        didSet { UserDefaults.standard.set(showFileSize, forKey: "showFileSize") }
    }
    @Published var showFileType: Bool {
        didSet { UserDefaults.standard.set(showFileType, forKey: "showFileType") }
    }
    @Published var showFilePath: Bool {
        didSet { UserDefaults.standard.set(showFilePath, forKey: "showFilePath") }
    }
    @Published var showIcon: Bool {
        didSet { UserDefaults.standard.set(showIcon, forKey: "showIcon") }
    }

    // Additional information display
    @Published var showLastAccessDate: Bool {
        didSet { UserDefaults.standard.set(showLastAccessDate, forKey: "showLastAccessDate") }
    }
    @Published var showPermissions: Bool {
        didSet { UserDefaults.standard.set(showPermissions, forKey: "showPermissions") }
    }
    @Published var showOwner: Bool {
        didSet { UserDefaults.standard.set(showOwner, forKey: "showOwner") }
    }
    @Published var showItemCount: Bool {
        didSet { UserDefaults.standard.set(showItemCount, forKey: "showItemCount") }
    }

    // EXIF information display
    @Published var showEXIF: Bool {
        didSet { UserDefaults.standard.set(showEXIF, forKey: "showEXIF") }
    }
    @Published var showEXIFCamera: Bool {
        didSet { UserDefaults.standard.set(showEXIFCamera, forKey: "showEXIFCamera") }
    }
    @Published var showEXIFLens: Bool {
        didSet { UserDefaults.standard.set(showEXIFLens, forKey: "showEXIFLens") }
    }
    @Published var showEXIFSettings: Bool {
        didSet { UserDefaults.standard.set(showEXIFSettings, forKey: "showEXIFSettings") }
    }
    @Published var showEXIFDateTaken: Bool {
        didSet { UserDefaults.standard.set(showEXIFDateTaken, forKey: "showEXIFDateTaken") }
    }
    @Published var showEXIFDimensions: Bool {
        didSet { UserDefaults.standard.set(showEXIFDimensions, forKey: "showEXIFDimensions") }
    }
    @Published var showEXIFGPS: Bool {
        didSet { UserDefaults.standard.set(showEXIFGPS, forKey: "showEXIFGPS") }
    }

    // Display order
    @Published var displayOrder: [DisplayItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(displayOrder) {
                UserDefaults.standard.set(encoded, forKey: "displayOrder")
            }
        }
    }

    // Window behavior
    @Published var followCursor: Bool {
        didSet { UserDefaults.standard.set(followCursor, forKey: "followCursor") }
    }
    @Published var windowOffsetX: Double {
        didSet { UserDefaults.standard.set(windowOffsetX, forKey: "windowOffsetX") }
    }
    @Published var windowOffsetY: Double {
        didSet { UserDefaults.standard.set(windowOffsetY, forKey: "windowOffsetY") }
    }

    private init() {
        // Load display order or use default
        if let data = UserDefaults.standard.data(forKey: "displayOrder"),
           let decoded = try? JSONDecoder().decode([DisplayItem].self, from: data) {
            self.displayOrder = decoded
        } else {
            // Default order
            self.displayOrder = [
                .fileType,
                .fileSize,
                .itemCount,
                .creationDate,
                .modificationDate,
                .lastAccessDate,
                .permissions,
                .owner,
                .exif,
                .filePath
            ]
        }

        // Load values from UserDefaults
        self.hoverDelay = UserDefaults.standard.object(forKey: "hoverDelay") as? Double ?? 0.1
        self.autoHideEnabled = UserDefaults.standard.object(forKey: "autoHideEnabled") as? Bool ?? true
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
        self.windowOpacity = UserDefaults.standard.object(forKey: "windowOpacity") as? Double ?? 0.98
        self.windowMaxWidth = UserDefaults.standard.object(forKey: "windowMaxWidth") as? Double ?? 400
        self.fontSize = UserDefaults.standard.object(forKey: "fontSize") as? Double ?? 11
        self.enableBlur = UserDefaults.standard.object(forKey: "enableBlur") as? Bool ?? true
        self.compactMode = UserDefaults.standard.object(forKey: "compactMode") as? Bool ?? false
        self.showCreationDate = UserDefaults.standard.object(forKey: "showCreationDate") as? Bool ?? true
        self.showModificationDate = UserDefaults.standard.object(forKey: "showModificationDate") as? Bool ?? true
        self.showFileSize = UserDefaults.standard.object(forKey: "showFileSize") as? Bool ?? true
        self.showFileType = UserDefaults.standard.object(forKey: "showFileType") as? Bool ?? true
        self.showFilePath = UserDefaults.standard.object(forKey: "showFilePath") as? Bool ?? true
        self.showIcon = UserDefaults.standard.object(forKey: "showIcon") as? Bool ?? true
        self.showLastAccessDate = UserDefaults.standard.object(forKey: "showLastAccessDate") as? Bool ?? false
        self.showPermissions = UserDefaults.standard.object(forKey: "showPermissions") as? Bool ?? false
        self.showOwner = UserDefaults.standard.object(forKey: "showOwner") as? Bool ?? false
        self.showItemCount = UserDefaults.standard.object(forKey: "showItemCount") as? Bool ?? true
        self.showEXIF = UserDefaults.standard.object(forKey: "showEXIF") as? Bool ?? true
        self.showEXIFCamera = UserDefaults.standard.object(forKey: "showEXIFCamera") as? Bool ?? true
        self.showEXIFLens = UserDefaults.standard.object(forKey: "showEXIFLens") as? Bool ?? true
        self.showEXIFSettings = UserDefaults.standard.object(forKey: "showEXIFSettings") as? Bool ?? true
        self.showEXIFDateTaken = UserDefaults.standard.object(forKey: "showEXIFDateTaken") as? Bool ?? true
        self.showEXIFDimensions = UserDefaults.standard.object(forKey: "showEXIFDimensions") as? Bool ?? true
        self.showEXIFGPS = UserDefaults.standard.object(forKey: "showEXIFGPS") as? Bool ?? false
        self.followCursor = UserDefaults.standard.object(forKey: "followCursor") as? Bool ?? true
        self.windowOffsetX = UserDefaults.standard.object(forKey: "windowOffsetX") as? Double ?? 15
        self.windowOffsetY = UserDefaults.standard.object(forKey: "windowOffsetY") as? Double ?? 15
    }

    func resetToDefaults() {
        hoverDelay = 0.1
        autoHideEnabled = true
        launchAtLogin = false
        windowOpacity = 0.98
        windowMaxWidth = 400
        fontSize = 11
        enableBlur = true
        compactMode = false
        showCreationDate = true
        showModificationDate = true
        showFileSize = true
        showFileType = true
        showFilePath = true
        showIcon = true
        showLastAccessDate = false
        showPermissions = false
        showOwner = false
        showItemCount = true
        showEXIF = true
        showEXIFCamera = true
        showEXIFLens = true
        showEXIFSettings = true
        showEXIFDateTaken = true
        showEXIFDimensions = true
        showEXIFGPS = false
        displayOrder = [
            .fileType,
            .fileSize,
            .itemCount,
            .creationDate,
            .modificationDate,
            .lastAccessDate,
            .permissions,
            .owner,
            .exif,
            .filePath
        ]
        followCursor = true
        windowOffsetX = 15
        windowOffsetY = 15
    }
}
