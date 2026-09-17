import SwiftUI

/// Shared layout for the behavior and appearance pages, each hosted in a
/// `TabView` tab inside `SettingsView`.
protocol SettingsPageView: View {
    associatedtype Content: View
    var settings: AppSettings { get }
    @ViewBuilder func pageContent() -> Content
}

extension SettingsPageView {
    var body: some View {
        ScrollView {
            pageContent()
                .padding(.bottom, 24)
                .frame(maxWidth: SettingsRowLayout.contentMaxWidth)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}