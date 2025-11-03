//
//  LocalizationManager.swift
//  FinderHover
//
//  Localization helper for multi-language support
//

import Foundation

/// Helper class for localization
class L {
    /// Get localized string
    static func string(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }

    /// Get localized string with format arguments
    static func string(_ key: String, _ args: CVarArg..., comment: String = "") -> String {
        let format = NSLocalizedString(key, comment: comment)
        return String(format: format, arguments: args)
    }
}

/// Extension for easier localization access
extension String {
    /// Get localized version of this string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Get localized version with format arguments
    func localized(_ args: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}
