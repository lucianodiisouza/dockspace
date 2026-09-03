import AppKit
import DockspaceCore
import os

/// Listens for global keystrokes matching any of the registered
/// `Hotkey` entries and invokes a callback with the matching profile
/// id when one fires.
///
/// Uses `NSEvent.addGlobalMonitorForEvents` so the OS still sees the
/// keystroke — this means our hotkey does NOT consume the event. For
/// v0.2 that is acceptable; a follow-up can swap in a `CGEvent` tap
/// for proper consumption. Logging is via `os.Logger` under the
/// `app.dockspace` subsystem with the `.hotkey` category.
@MainActor
public final class GlobalHotkeyManager {
    public typealias Handler = (UUID) -> Void

    private let logger = Logger(subsystem: "app.dockspace", category: "hotkey")
    private var handler: Handler?
    private var bindings: [UUID: Hotkey] = [:]
    private var monitor: Any?

    public init() {}

    public func setBindings(_ newBindings: [UUID: Hotkey], handler: @escaping Handler) {
        self.bindings = newBindings
        self.handler = handler
        restartMonitor()
    }

    public func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        self.handler = nil
        self.bindings = [:]
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func restartMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        guard !bindings.isEmpty else { return }

        let snapshot = bindings
        let callback = handler
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let callback else { return }
            guard let hotkey = HotkeyFromNSEvent.hotkey(from: event) else { return }
            for (profileID, registered) in snapshot where registered == hotkey {
                self?.logger.debug("hotkey fired for profile \(profileID, privacy: .public)")
                callback(profileID)
                return
            }
        }
    }
}
