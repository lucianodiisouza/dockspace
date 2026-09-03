import AppKit
import DockspaceCore
import SwiftUI

/// Renders the real macOS icon for a `DockItem` when one is available.
///
/// App and file/folder tiles use `NSWorkspace.icon(forFile:)` so the
/// editor shows the same icons the user sees in Finder. URL tiles and
/// spacers fall back to SF Symbols — fetching a favicon per URL would
/// require network access and is out of scope for the local app.
struct ItemIconView: View {
  let item: DockItem
  let size: CGFloat

  init(item: DockItem, size: CGFloat = 28) {
    self.item = item
    self.size = size
  }

  var body: some View {
    Group {
      switch item {
      case .app(let entry):
        Image(nsImage: NSWorkspace.shared.icon(forFile: entry.path))
          .resizable()
      case .file(let entry):
        Image(nsImage: NSWorkspace.shared.icon(forFile: entry.path))
          .resizable()
      case .url:
        Image(systemName: "link")
          .imageScale(.large)
          .foregroundStyle(.secondary)
      case .spacer(let variant):
        Image(systemName: spacerSymbol(variant))
          .imageScale(.large)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: size, height: size)
  }

  private func spacerSymbol(_ variant: SpacerVariant) -> String {
    switch variant {
    case .small: return "rectangle"
    case .flex: return "rectangle.expand.vertical"
    case .default: return "rectangle.split.3x1"
    }
  }
}
