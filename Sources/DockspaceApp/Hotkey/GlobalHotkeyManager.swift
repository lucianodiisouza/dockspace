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
///
/// All mutations of `bindings` / `monitor` happen on the main actor.
/// The NSEvent callback runs on the main thread already
/// (AppKit's contract) so we don't need to dispatch there.
public final class GlobalHotkeyManager: @unchecked Sendable {
    public typealias Handler = @MainActor (UUID) -> Void

    private let logger = Logger(subsystem: "app.dockspace", category: "hotkey")
    private let lock = NSLock()
    private var handler: Handler?
    private var bindings: [UUID: Hotkey] = [:]
    private var monitor: Any?

    public init() {}

    public func setBindings(_ newBindings: [UUID: Hotkey], handler: @escaping Handler) {
        lock.lock()
        self.bindings = newBindings
        self.handler = handler
        lock.unlock()
        restartMonitor()
    }

    public func stop() {
        lock.lock()
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        self.handler = nil
        self.bindings = [:]
        lock.unlock()
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func restartMonitor() {
        lock.lock()
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        let isEmpty = bindings.isEmpty
        lock.unlock()
        guard !isEmpty else { return }

        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            guard let hotkey = HotkeyFromNSEvent.hotkey(from: event) else { return }
            self.lock.lock()
            let snapshot = self.bindings
            let callback = self.handler
            self.lock.unlock()

            for (profileID, registered) in snapshot where registered == hotkey {
                self.logger.debug("hotkey fired for profile \(profileID, privacy: .public)")
                if let callback {
                    // The AppKit contract says this closure runs on
                    // the main thread, so we can hop into the main
                    // actor directly without an extra Task hop.
                    MainActor.assumeIsolated {
                        callback(profileID)
                    }
                }
                return
            }
        }
    }
}
