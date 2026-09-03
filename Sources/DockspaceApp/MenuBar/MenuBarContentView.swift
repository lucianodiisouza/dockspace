import DockspaceCore
import SwiftUI
import os

private let popoverLog = Logger(subsystem: "app.dockspace", category: "popover")

/// Popover content shown when the user clicks the menu bar icon.
///
/// Renders a real SwiftUI popover (`.menuBarExtraStyle(.window)` on
/// the parent `MenuBarExtra`). Buttons use the `.borderless` style
/// so they pick up the standard macOS hover/press feedback. Sheets
/// would be a more idiomatic presentation, but they do not survive
/// the popover closing — so secondary screens open as `Window`
/// scenes via `openWindow` instead.
@MainActor
struct MenuBarContentView: View {
  @Environment(AppState.self) private var state
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header

      if state.profiles.isEmpty {
        emptyState
      } else {
        profileList
      }

      Divider().padding(.vertical, 4)

      actionRow(
        title: "New profile",
        systemImage: "plus"
      ) { openWindow(id: AppWindow.newProfile.rawValue) }

      actionRow(
        title: "Edit profiles…",
        systemImage: "slider.horizontal.3"
      ) { openWindow(id: AppWindow.editor.rawValue) }

      actionRow(
        title: "Settings…",
        systemImage: "gearshape"
      ) { openWindow(id: AppWindow.settings.rawValue) }

      Divider()

      actionRow(
        title: "Quit Dockspace",
        systemImage: "power",
        role: .destructive
      ) { NSApplication.shared.terminate(nil) }
      .keyboardShortcut("q")

      if let error = state.lastError {
        errorBanner(error)
      }
    }
    .padding(.vertical, 6)
    .frame(minWidth: 240)
    .onAppear {
      popoverLog.info(
        "MenuBarContentView appeared: profiles=\(self.state.profiles.count, privacy: .public) active=\(self.state.activeProfileId?.uuidString ?? "nil", privacy: .public)"
      )
    }
  }

  // MARK: - Sections

  private var header: some View {
    Text("Docks")
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 12)
      .padding(.top, 6)
      .padding(.bottom, 4)
  }

  private var emptyState: some View {
    Text("No profiles yet")
      .font(.callout)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
  }

  private var profileList: some View {
    ForEach(state.profiles) { profile in
      ProfileMenuRow(
        profile: profile,
        isActive: profile.id == state.activeProfileId,
        onSelect: { state.switchTo(profile: profile) }
      )
    }
  }

  private func errorBanner(_ message: String) -> some View {
    Text(message)
      .font(.caption)
      .foregroundStyle(.red)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
  }

  /// Reusable button row with a leading icon, label, and optional
  /// hover state. We avoid `.plain` because it disables the native
  /// macOS row highlight, making the button feel dead.
  private func actionRow(
    title: String,
    systemImage: String,
    role: ButtonRole? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(role: role, action: action) {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
          .frame(width: 16)
        Text(title)
        Spacer()
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
    }
    .buttonStyle(MenuRowButtonStyle())
  }
}

/// Borderless style with a rounded highlight on hover/press. Mimics
/// what NSMenuItem looks like on macOS without losing the SwiftUI
/// bindings the rest of the app relies on.
struct MenuRowButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(highlightColor(configuration: configuration))
      )
  }

  private func highlightColor(configuration: Configuration) -> Color {
    if configuration.isPressed {
      return Color.accentColor.opacity(0.35)
    }
    return Color.clear
  }
}
