import DockspaceCore
import SwiftUI

/// One row inside the menu bar popover. Renders a colored swatch, the
/// profile name, and a checkmark for the currently active profile.
struct ProfileMenuRow: View {
  let profile: Profile
  let isActive: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 8) {
        Image(systemName: isActive ? "checkmark" : "circle")
          .frame(width: 14)
          .foregroundStyle(isActive ? Color.accentColor : .secondary)
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: profile.color.hex))
          .frame(width: 14, height: 14)
        Text(profile.name)
          .lineLimit(1)
        Spacer()
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
    }
    .buttonStyle(.plain)
  }
}
