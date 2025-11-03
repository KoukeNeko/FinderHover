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

enum BlurMaterial: String, CaseIterable {
    case hudWindow = "HUD Window"
    case popover = "Popover"
    case menu = "Menu"
    case sidebar = "Sidebar"
    case none = "None"

    var material: NSVisualEffectView.Material? {
        switch self {
        case .hudWindow: return .hudWindow
        case .popover: return .popover
        case .menu: return .menu
        case .sidebar: return .sidebar
        case .none: return nil
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
    @Published var blurMaterial: BlurMaterial {
        didSet { UserDefaults.standard.set(blurMaterial.rawValue, forKey: "blurMaterial") }
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
        // Load values from UserDefaults
        self.hoverDelay = UserDefaults.standard.object(forKey: "hoverDelay") as? Double ?? 0.1
        self.autoHideEnabled = UserDefaults.standard.object(forKey: "autoHideEnabled") as? Bool ?? true
        self.windowOpacity = UserDefaults.standard.object(forKey: "windowOpacity") as? Double ?? 0.98
        self.windowMaxWidth = UserDefaults.standard.object(forKey: "windowMaxWidth") as? Double ?? 400
        self.fontSize = UserDefaults.standard.object(forKey: "fontSize") as? Double ?? 11

        let blurMaterialString = UserDefaults.standard.string(forKey: "blurMaterial") ?? "HUD Window"
        self.blurMaterial = BlurMaterial(rawValue: blurMaterialString) ?? .hudWindow

        self.showCreationDate = UserDefaults.standard.object(forKey: "showCreationDate") as? Bool ?? true
        self.showModificationDate = UserDefaults.standard.object(forKey: "showModificationDate") as? Bool ?? true
        self.showFileSize = UserDefaults.standard.object(forKey: "showFileSize") as? Bool ?? true
        self.showFileType = UserDefaults.standard.object(forKey: "showFileType") as? Bool ?? true
        self.showFilePath = UserDefaults.standard.object(forKey: "showFilePath") as? Bool ?? true
        self.showIcon = UserDefaults.standard.object(forKey: "showIcon") as? Bool ?? true
        self.followCursor = UserDefaults.standard.object(forKey: "followCursor") as? Bool ?? true
        self.windowOffsetX = UserDefaults.standard.object(forKey: "windowOffsetX") as? Double ?? 15
        self.windowOffsetY = UserDefaults.standard.object(forKey: "windowOffsetY") as? Double ?? 15
    }

    func resetToDefaults() {
        hoverDelay = 0.1
        autoHideEnabled = true
        windowOpacity = 0.98
        windowMaxWidth = 400
        fontSize = 11
        blurMaterial = .hudWindow
        showCreationDate = true
        showModificationDate = true
        showFileSize = true
        showFileType = true
        showFilePath = true
        showIcon = true
        followCursor = true
        windowOffsetX = 15
        windowOffsetY = 15
    }
}
