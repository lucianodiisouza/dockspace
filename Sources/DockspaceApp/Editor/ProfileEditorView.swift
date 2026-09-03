import DockspaceCore
import SwiftUI

/// Top-level window/sheet for managing all profiles. Lists profiles
/// with the ability to add, rename, recolor, delete, and drill into a
/// single profile for item-level editing.
@MainActor
struct ProfileEditorView: View {
  @Environment(AppState.self) private var state
  @Environment(\.dismiss) private var dismiss
  @State private var newName: String = ""
  @State private var selectedProfileId: UUID?

  var body: some View {
    NavigationSplitView {
      sidebar
        .frame(minWidth: 200)
    } detail: {
      if let id = selectedProfileId,
        let profile = state.profiles.first(where: { $0.id == id })
      {
        ProfileDetailView(profileID: profile.id)
      } else {
        ContentUnavailableView(
          "Pick a profile",
          systemImage: "rectangle.stack",
          description: Text("Select a profile on the left, or create a new one.")
        )
      }
    }
    .navigationTitle("Dockspace")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") { dismiss() }
      }
    }
    .frame(minWidth: 640, minHeight: 420)
  }

  @ViewBuilder
  private var sidebar: some View {
    List(selection: $selectedProfileId) {
      Section("Profiles") {
        ForEach(state.profiles) { profile in
          HStack {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color(hex: profile.color.hex))
              .frame(width: 12, height: 12)
            Text(profile.name)
            Spacer()
            if profile.id == state.activeProfileId {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
            }
          }
          .tag(profile.id)
        }
        .onDelete(perform: deleteProfiles)
      }
    }
    .safeAreaInset(edge: .bottom) {
      HStack {
        TextField("New profile name", text: $newName)
          .textFieldStyle(.roundedBorder)
        Button("Add") { addProfile() }
          .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
      }
      .padding(8)
    }
  }

  private func addProfile() {
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    do {
      let created = try state.createProfile(name: trimmed)
      newName = ""
      selectedProfileId = created.id
    } catch {
      // Surfaced via AppState.lastError.
    }
  }

  private func deleteProfiles(at offsets: IndexSet) {
    for index in offsets {
      let profile = state.profiles[index]
      try? state.deleteProfile(id: profile.id)
    }
  }
}
