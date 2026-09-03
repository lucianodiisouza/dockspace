import SwiftUI

/// Lightweight settings sheet. Lives inside the menu bar popover flow
/// rather than as a `Settings` scene to keep the popover self-contained.
struct SettingsView: View {
    @State private var launchAtLogin: Bool
    private let preferences: AppPreferences

    init(preferences: AppPreferences = AppPreferences()) {
        self.preferences = preferences
        _launchAtLogin = State(initialValue: preferences.launchAtLogin)
    }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch Dockspace at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        preferences.launchAtLogin = newValue
                    }
            }
            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Storage", value: storagePath)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 280)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    private var storagePath: String {
        (try? StoragePath.appSupportDirectory(create: false).path) ?? "unavailable"
    }
}
