import AppKit
import ApplicationServices
import DockspaceCore
import SwiftUI
import os

private let menuBarLog = Logger(subsystem: "app.dockspace", category: "menubar")

/// Hosts the menu bar status item and the popover that opens from it.
///
/// We use a native `NSStatusItem` + `NSPopover` rather than SwiftUI's
/// `MenuBarExtra(.window)` because the latter has a known issue on
/// macOS 14+ where real mouse clicks (CGEventPost / HID) do not reach
/// the popover reliably — only the Accessibility API path does.
/// `NSPopover` handles click-to-open, click-outside-to-close, and Esc
/// correctly via AppKit, and `NSHostingController` lets us keep the
/// SwiftUI body with all its `@Environment` and `openWindow` actions.
///
/// On macOS 14+, `NSStatusItem` clicks also require the owning process
/// to be a "trusted" Accessibility client. Without that, real mouse
/// clicks (including the user's hardware clicks) are dropped on the
/// floor. We detect the missing permission and prompt the user to
/// grant it via System Settings, then they re-launch the app.
@MainActor
final class MenuBarController: NSObject {
  private let statusItem: NSStatusItem
  private let popover: NSPopover
  private let hostingController: NSHostingController<AnyView>

  private let state: AppState

  init(state: AppState) {
    self.state = state
    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    self.popover = NSPopover()
    self.hostingController = NSHostingController(
      rootView: AnyView(MenuBarContentView().environment(state))
    )
    super.init()
    configureStatusItem()
    configurePopover()
    requestAccessibilityIfNeeded()
    menuBarLog.info("MenuBarController initialized")
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else { return }
    let image = NSImage(
      systemSymbolName: "dock.rectangle",
      accessibilityDescription: "Dockspace"
    )
    image?.isTemplate = true
    button.image = image
    button.target = self
    button.action = #selector(handleClick(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
  }

  private func configurePopover() {
    popover.behavior = .transient
    popover.contentSize = NSSize(width: 260, height: 280)
    popover.contentViewController = hostingController
  }

  /// On macOS 14+, a non-notarized `NSStatusItem` only receives mouse
  /// events when the owning process is a trusted Accessibility client.
  /// Without that, real clicks (and most synthetic ones) are dropped.
  /// Prompt the user once to grant the permission.
  private func requestAccessibilityIfNeeded() {
    let promptKey = "Dockspace.requestedAccessibility"
    let defaults = UserDefaults.standard
    let alreadyPrompted = defaults.bool(forKey: promptKey)

    let trusted = AXIsProcessTrusted()
    menuBarLog.info(
      "accessibility trusted=\(trusted, privacy: .public) alreadyPrompted=\(alreadyPrompted, privacy: .public)"
    )

    if trusted { return }
    if alreadyPrompted { return }

    defaults.set(true, forKey: promptKey)
    // Prompt asynchronously so the menu bar item has a chance to
    // register first; otherwise the prompt can race with the
    // status-item setup on a slow first launch.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      let key = Unmanaged<CFString>.fromOpaque(kAXTrustedCheckOptionPrompt.toOpaque())
        .takeUnretainedValue()
      let options = [key: true] as CFDictionary
      _ = AXIsProcessTrustedWithOptions(options)
    }
  }

  @objc private func handleClick(_ sender: NSStatusBarButton) {
    togglePopover()
  }

  func togglePopover() {
    if popover.isShown {
      popover.performClose(nil)
      return
    }
    guard let button = statusItem.button else { return }
    menuBarLog.info("MenuBarController opening popover")
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    popover.contentViewController?.view.window?.makeKey()
  }
}
