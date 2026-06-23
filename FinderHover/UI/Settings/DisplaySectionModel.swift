//
//  DisplaySectionModel.swift
//  FinderHover
//
//  Data-driven description of the Display settings toggle page.
//
//  Each toggle section used to be ~50 lines of copy-pasted `DisplayToggleRow`s.
//  Declaring them as data lets a single `DisplaySectionView` render every section,
//  removing the duplication, applying dividers uniformly, and scoping SwiftUI
//  invalidation to the section whose value actually changed.
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
}

/// Layout constants previously hard-coded throughout `DisplaySettingsView`.
///
/// There is intentionally no `sectionTopPadding`: inter-section spacing is owned by
/// the enclosing `LazyVStack(spacing:)`, matching the original outer `VStack(spacing: 16)`.
/// Adding per-title top padding here would double-space the sections.
enum SettingsLayout {
    static let horizontalPadding: CGFloat = 20
    static let dividerLeading: CGFloat = 60
    static let cardCornerRadius: CGFloat = 8
    static let sectionTitleSize: CGFloat = 13
    static let hintTextSize: CGFloat = 11
    static let sectionSpacing: CGFloat = 16
    static let dimmedOpacity: Double = 0.5
}

/// Renders one `DisplaySection`. Lives in its own struct so toggling a value inside
/// one section invalidates only that section's body, not the whole Display page.
struct DisplaySectionView: View {
    @ObservedObject var settings: AppSettings
    let section: DisplaySection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.titleKey.localized)
                .font(.system(size: SettingsLayout.sectionTitleSize, weight: .semibold))
                .padding(.horizontal, SettingsLayout.horizontalPadding)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, spec in
                    if index != 0 {
                        Divider().padding(.leading, SettingsLayout.dividerLeading)
                    }
                    row(for: spec)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(SettingsLayout.cardCornerRadius)
            .padding(.horizontal, SettingsLayout.horizontalPadding)

            if let hintKey = section.hintKey {
                SettingsHint(textKey: hintKey)
            }
        }
    }

    @ViewBuilder
    private func row(for spec: DisplayToggleSpec) -> some View {
        let isEnabled = spec.gate.map { settings[keyPath: $0] } ?? true
        DisplayToggleRow(
            title: spec.titleKey.localized,
            icon: spec.icon,
            isOn: Binding(
                get: { settings[keyPath: spec.keyPath] },
                set: { settings[keyPath: spec.keyPath] = $0 }
            )
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : SettingsLayout.dimmedOpacity)
    }
}

/// The trailing "info" hint shown under several display sections.
struct SettingsHint: View {
    let textKey: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: SettingsLayout.hintTextSize))
            Text(textKey.localized)
                .font(.system(size: SettingsLayout.hintTextSize))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, SettingsLayout.horizontalPadding)
        .padding(.top, 8)
    }
}
