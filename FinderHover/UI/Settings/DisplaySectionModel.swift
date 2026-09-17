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

/// Layout constants previously hard-coded throughout `DisplaySettingsView`.
///
/// There is intentionally no `sectionTopPadding`: inter-section spacing is owned by
/// the enclosing `LazyVStack(spacing:)`, matching the original outer `VStack(spacing: 16)`.
/// Adding per-title top padding here would double-space the sections.
enum SettingsLayout {
    static let horizontalPadding: CGFloat = 20
    static let dividerLeading: CGFloat = 60
    static let cardCornerRadius: CGFloat = SettingsRowLayout.cardCornerRadius
    static let hintTextSize: CGFloat = 11
    static let sectionSpacing: CGFloat = 16
    static let dimmedOpacity: Double = 0.5
}

/// Renders one section. AppSettings is still a broad ObservableObject dependency.
struct DisplaySectionView: View {
    @ObservedObject var settings: AppSettings
    let section: DisplaySection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionLabel(titleKey: section.titleKey)

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
