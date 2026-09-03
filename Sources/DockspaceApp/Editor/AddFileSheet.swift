import AppKit
import DockspaceCore
import SwiftUI

/// Sheet for adding a file or folder tile (a stack for Downloads, a
/// specific document, etc.) to the current profile. Wraps
/// `NSOpenPanel` configured to allow both files and directories.
@MainActor
struct AddFileSheet: View {
  @Environment(\.dismiss) private var dismiss
  let onAdd: (FileEntry) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Add a file or folder")
        .font(.headline)
      Text("Pick any file or folder. Folders render as a stack on the Dock.")
        .font(.callout)
        .foregroundStyle(.secondary)

      HStack {
        Spacer()
        Button("Cancel") { dismiss() }
          .keyboardShortcut(.cancelAction)
        Button("Choose…") {
          if let entry = pickFile() {
            onAdd(entry)
            dismiss()
          }
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 420)
  }

  private func pickFile() -> FileEntry? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.treatsFilePackagesAsDirectories = true
    panel.message = "Choose a file or folder to pin to this profile"
    panel.prompt = "Add"
    guard panel.runModal() == .OK, let url = panel.url else { return nil }
    var isDir: ObjCBool = false
    let directory =
      FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
      && isDir.boolValue
    return FileEntry(
      path: url.path,
      displayName: url.lastPathComponent,
      isDirectory: directory
    )
  }
}
