import SwiftUI
import DockspaceCore

/// Popover content shown when the user clicks the menu bar icon.
struct MenuBarContentView: View {
    @Environment(AppState.self) private var state
    @State private var showingEditor = false
    @State private var creatingProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Docks")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if state.profiles.isEmpty {
                Text("No profiles yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(state.profiles) { profile in
                    ProfileMenuRow(
                        profile: profile,
                        isActive: profile.id == state.activeProfileId,
                        onSelect: { state.switchTo(profile: profile) }
                    )
                }
            }

            Divider().padding(.vertical, 4)

            Button {
                creatingProfile = true
            } label: {
                Label("New profile", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)

            Button {
                showingEditor = true
            } label: {
                Label("Edit profiles", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            if let error = state.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
        }
        .frame(minWidth: 220)
        .sheet(isPresented: $creatingProfile) {
            NewProfileSheet()
                .environment(state)
        }
        .sheet(isPresented: $showingEditor) {
            ProfileEditorView()
                .environment(state)
        }
    }
}
