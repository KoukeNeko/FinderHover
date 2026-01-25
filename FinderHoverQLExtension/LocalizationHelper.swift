//
//  LocalizationHelper.swift
//  FinderHoverQLExtension
//
//  Localization helper for Quick Look extension
//

import Foundation

/// Extension for easier localization access in Quick Look extension
extension String {
    /// Get localized version of this string
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.main, comment: "")
    }

    /// Get localized version with format arguments
    func localized(_ args: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, bundle: Bundle.main, comment: ""), arguments: args)
    }
}
