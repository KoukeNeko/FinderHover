//
//  SettingsPageView.swift
//  FinderHover
//
//  Template protocol for settings pages
//

import SwiftUI

/// Template Method Pattern for settings pages
/// All settings pages share the same structure: title + divider + content + reset button
protocol SettingsPageView: View {
    associatedtype Content: View

    var settings: AppSettings { get }
    var pageTitle: String { get }

    /// Subclasses implement this to provide page-specific content
    @ViewBuilder
    func pageContent() -> Content

    /// Subclasses can override this to customize reset behavior
    func resetAction()
}

// Default implementation of template method
extension SettingsPageView {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header (fixed template)
                Text(pageTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Divider()
                    .padding(.bottom, 20)

                // Page-specific content (hook for subclasses)
                pageContent()

                Spacer(minLength: 40)

                // Reset Button (fixed template)
                HStack {
                    Spacer()
                    Button("common.reset".localized) {
                        withAnimation {
                            resetAction()
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

    // Default reset action
    func resetAction() {
        settings.resetToDefaults()
    }
}
