//
//  DisplaySectionModel.swift
//  FinderHover
//
//  Data-driven description of the Display settings toggle page.
//
//  Each toggle section used to be ~50 lines of copy-pasted `DisplayToggleRow`s.
//  Declaring them as data lets a single `DisplaySectionView` render every section,
//  removing the duplication, applying dividers uniformly, and keeping the rendering rules in one place.
//

import SwiftUI

/// A single toggle row in a display section.
///
/// `keyPath` is a reference-writable key path into `AppSettings` (a class, so its
/// `@Published` Bool properties are addressable as `ReferenceWritableKeyPath`).
/// `gate`, when present, is the master toggle that enables/disables this detail row.
struct DisplayToggleSpec: Identifiable {
    let titleKey: String
    let icon: String
    let keyPath: ReferenceWritableKeyPath<AppSettings, Bool>
    let gate: ReferenceWritableKeyPath<AppSettings, Bool>?
    var id: String { titleKey }

    init(_ titleKey: String,
         icon: String,
         _ keyPath: ReferenceWritableKeyPath<AppSettings, Bool>,
         gatedBy gate: ReferenceWritableKeyPath<AppSettings, Bool>? = nil) {
        self.titleKey = titleKey
        self.icon = icon
        self.keyPath = keyPath
        self.gate = gate
    }
}

/// A titled card of toggle rows, optionally followed by an info hint.
struct DisplaySection: Identifiable {
    let titleKey: String
    let hintKey: String?
    let rows: [DisplayToggleSpec]
    var id: String { titleKey }

    /// Keep the master control alongside matching detail rows so search never strands
    /// a disabled result without the switch needed to enable it.
    func matching(_ query: String) -> DisplaySection? {
        if titleKey.localized.localizedStandardContains(query) { return self }
        let matches = rows.filter { $0.titleKey.localized.localizedStandardContains(query) }
        guard !matches.isEmpty else { return nil }
        let gates = matches.compactMap(\.gate)
        let included = rows.filter { row in
            matches.contains { $0.id == row.id } || gates.contains(row.keyPath)
        }
        return DisplaySection(titleKey: titleKey, hintKey: hintKey, rows: included)
    }
}
