import DockspaceCore
import SwiftUI

/// Sheet for adding a URL tile (a webpage bookmark, or a `file://`
/// URL pointing at a folder shown as a stack) to the current profile.
@MainActor
struct AddURLSheet: View {
  @Environment(\.dismiss) private var dismiss
  let onAdd: (URLEntry) -> Void

  @State private var urlString: String = "https://"
  @State private var label: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Add a website")
        .font(.headline)
      Text("Pin a webpage or a `file://` link to this profile.")
        .font(.callout)
        .foregroundStyle(.secondary)

      Form {
        TextField("URL", text: $urlString)
          .textFieldStyle(.roundedBorder)
        TextField("Label (optional)", text: $label)
          .textFieldStyle(.roundedBorder)
      }
      .formStyle(.grouped)

      HStack {
        Spacer()
        Button("Cancel") { dismiss() }
          .keyboardShortcut(.cancelAction)
        Button("Add") { add() }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
          .disabled(trimmedURL.isEmpty)
      }
    }
    .padding(20)
    .frame(width: 420)
  }

  private var trimmedURL: String {
    urlString.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func add() {
    let entry = URLEntry(
      url: trimmedURL,
      displayName: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? nil : label
    )
    onAdd(entry)
    dismiss()
  }
}
