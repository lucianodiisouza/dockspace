import SwiftUI
import AppKit
import DockspaceCore

/// Sheet that lets the user pick an installed app. Uses `NSOpenPanel`
/// configured to select only `.app` bundles, then returns a typed
/// `AppEntry` to the caller.
struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (AppEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add an app")
                .font(.headline)
            Text("Pick any installed `.app` bundle. It will be added to the active profile.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Choose app…") {
                    let entry = pickApp()
                    if let entry {
                        onPick(entry)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func pickApp() -> AppEntry? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = true
        panel.allowedContentTypes = []
        panel.message = "Choose an application to add to this profile"
        panel.prompt = "Add"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        return AppEntry(
            path: url.path,
            bundleIdentifier: Bundle(url: url)?.bundleIdentifier,
            displayName: Bundle(url: url)?["CFBundleDisplayName"] as? String ?? url.deletingPathExtension().lastPathComponent
        )
    }
}
